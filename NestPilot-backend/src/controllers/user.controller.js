const { Op } = require('sequelize');
const db = require('../models');
const ApiError = require('../utils/ApiError');
const ApiResponse = require('../utils/ApiResponse');
const auditService = require('../services/audit.service');

/**
 * Super-Admin user directory: every user across every society, with
 * server-side search, filters and paging so it stays usable as the number of
 * societies grows. Society Admins keep using /admin/members, which stays
 * scoped to their own society and buildings.
 */

const STATUSES = ['pending', 'active', 'rejected', 'blocked'];
const RELATIONS = ['OWNER', 'TENANT', 'FAMILY'];
const MOBILE_RE = /^\d{10}$/;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 50;

const STATUS_MESSAGES = {
    active: 'User activated',
    pending: 'User moved back to pending',
    rejected: 'User rejected',
    blocked: 'User blocked'
};

const toPositiveInt = (v) => {
    const n = Number(v);
    return Number.isInteger(n) && n > 0 ? n : null;
};

// The user's current flat with its building. Built per call because
// Sequelize mutates include options, so a shared object would leak state.
const activeFlatInclude = () => ({
    model: db.UserHouseMapping,
    separate: true,
    where: { is_active: true },
    attributes: ['id', 'user_id', 'house_id', 'relation_type', 'is_primary'],
    order: [['is_primary', 'DESC'], ['id', 'DESC']],
    include: [{
        model: db.House,
        attributes: ['id', 'house_no', 'wing', 'building_id'],
        include: [{ model: db.Building, attributes: ['id', 'name'] }]
    }]
});

const userIncludes = () => [
    { model: db.Role, attributes: ['id', 'code', 'name'] },
    { model: db.Society, attributes: ['id', 'name', 'city'] },
    activeFlatInclude()
];

const loadUser = (id) => db.User.findByPk(id, {
    include: [
        ...userIncludes(),
        { association: 'assignedBuildings', attributes: ['id', 'name'], through: { attributes: [] } }
    ]
});

const flatOf = (user) => {
    const mapping = (user.UserHouseMappings || [])[0];
    return mapping && mapping.House ? mapping.House.house_no : null;
};

// Activity-feed entry for the user's society. auditService swallows its own
// failures, so logging never breaks the request.
const logUserAction = (req, user, action) => auditService.logAction(
    req.user.id,
    user.society_id,
    action,
    'RESIDENT',
    String(user.id),
    { new_value: { title: user.full_name, house_no: flatOf(user) }, ip_address: req.ip }
);

const statusAction = (from, to) => {
    if (from === 'pending' && to === 'active') return 'APPROVED';
    if (to === 'rejected') return 'DENIED';
    if (to === 'blocked') return 'BLOCKED';
    if (to === 'active') return 'REACTIVATED';
    return 'UPDATED';
};

// Name / mobile / email match directly; flat numbers live two joins away, so
// they go through an id sub-select that keeps the paged query join-free.
const searchConditions = (search) => {
    const like = { [Op.iLike]: `%${search}%` };
    const flatMatch = db.sequelize.literal(
        '(SELECT m.user_id FROM tbl_user_house_mappings m ' +
        'JOIN tbl_houses h ON h.id = m.house_id ' +
        `WHERE m.is_active = true AND h.house_no ILIKE ${db.sequelize.escape(`%${search}%`)})`
    );
    return [
        { full_name: like },
        { mobile: like },
        { email: like },
        { id: { [Op.in]: flatMatch } }
    ];
};

/**
 * Validates a role / society / flat combination and returns the resolved
 * rows. Super Admins are platform accounts with no society; every other role
 * belongs to one, and a flat (when given) must sit inside that society.
 */
const resolveAssignment = async ({ roleId, societyId, houseId, relationType }, transaction) => {
    const role = roleId ? await db.Role.findByPk(roleId, { transaction }) : null;
    if (!role || !role.is_active) throw new ApiError(400, 'Select a valid role');

    if (role.code === 'SUPER_ADMIN') return { role, society: null, house: null };

    if (!societyId) throw new ApiError(400, 'Select a society for this user');
    const society = await db.Society.findByPk(societyId, { transaction });
    if (!society) throw new ApiError(404, 'Society not found');

    if (!houseId) return { role, society, house: null };

    const house = await db.House.findByPk(houseId, { transaction });
    if (!house || !house.is_active) throw new ApiError(404, 'Flat not found');
    if (house.society_id !== society.id) {
        throw new ApiError(400, 'The flat belongs to a different society');
    }
    if (!RELATIONS.includes(relationType)) {
        throw new ApiError(400, `relation_type must be one of: ${RELATIONS.join(', ')}`);
    }
    return { role, society, house };
};

// Puts the user in [house]. An existing active mapping to it is kept (its
// relation refreshed); any other active flat is closed, so moving a resident
// never leaves them scoped to their old building as well.
const assignFlat = async (userId, house, relationType, transaction) => {
    const current = await db.UserHouseMapping.findOne({
        where: { user_id: userId, house_id: house.id, is_active: true },
        transaction
    });
    if (current) {
        if (current.relation_type !== relationType) {
            await current.update({ relation_type: relationType }, { transaction });
        }
        return;
    }

    await db.UserHouseMapping.update(
        { is_active: false, is_primary: false, end_date: new Date() },
        { where: { user_id: userId, is_active: true }, transaction }
    );
    await db.UserHouseMapping.create({
        user_id: userId,
        house_id: house.id,
        relation_type: relationType,
        is_primary: true,
        is_active: true
    }, { transaction });
};

const listUsers = async (req, res, next) => {
    try {
        const page = toPositiveInt(req.query.page) || 1;
        const limit = Math.min(toPositiveInt(req.query.limit) || DEFAULT_LIMIT, MAX_LIMIT);
        const search = String(req.query.search || '').trim();

        const where = {};
        const societyId = toPositiveInt(req.query.society_id);
        if (societyId) where.society_id = societyId;
        const roleId = toPositiveInt(req.query.role_id);
        if (roleId) where.role_id = roleId;
        if (STATUSES.includes(req.query.status)) where.status = req.query.status;
        if (search) where[Op.or] = searchConditions(search);

        const order = req.query.sort === 'name'
            ? [['full_name', 'ASC'], ['id', 'ASC']]
            : [['created_at', 'DESC'], ['id', 'DESC']];

        // Counted separately: the filters never reference an include, so a
        // plain count is exact and avoids findAndCountAll's include handling.
        const [total, items] = await Promise.all([
            db.User.count({ where }),
            db.User.findAll({
                where,
                include: userIncludes(),
                order,
                limit,
                offset: (page - 1) * limit
            })
        ]);

        res.status(200).json(new ApiResponse(200, {
            items,
            total,
            page,
            limit,
            has_more: page * limit < total
        }));
    } catch (e) { next(e); }
};

const getUserStats = async (req, res, next) => {
    try {
        const where = {};
        const societyId = toPositiveInt(req.query.society_id);
        if (societyId) where.society_id = societyId;

        const rows = await db.User.findAll({
            where,
            attributes: ['status', [db.sequelize.fn('COUNT', db.sequelize.col('id')), 'count']],
            group: ['status'],
            raw: true
        });

        const stats = { total: 0, active: 0, pending: 0, blocked: 0, rejected: 0 };
        rows.forEach(r => {
            const n = Number(r.count) || 0;
            stats.total += n;
            if (STATUSES.includes(r.status)) stats[r.status] = n;
        });

        res.status(200).json(new ApiResponse(200, stats));
    } catch (e) { next(e); }
};

const getUser = async (req, res, next) => {
    try {
        const id = toPositiveInt(req.params.id);
        const user = id ? await loadUser(id) : null;
        if (!user) throw new ApiError(404, 'User not found');
        res.status(200).json(new ApiResponse(200, user));
    } catch (e) { next(e); }
};

/**
 * Create any user directly. Super-Admin-created accounts start active (no
 * approval step) and sign in with OTP on the given mobile right away.
 */
const createUser = async (req, res, next) => {
    try {
        const body = req.body || {};
        const fullName = String(body.full_name || '').trim();
        const mobile = String(body.mobile || '').trim();
        const email = String(body.email || '').trim();
        const status = body.status === undefined ? 'active' : String(body.status).toLowerCase();

        if (!fullName) throw new ApiError(400, 'full_name is required');
        if (!MOBILE_RE.test(mobile)) throw new ApiError(400, 'Enter a valid 10-digit mobile number');
        if (email && !EMAIL_RE.test(email)) throw new ApiError(400, 'Enter a valid email address');
        if (!STATUSES.includes(status)) {
            throw new ApiError(400, `status must be one of: ${STATUSES.join(', ')}`);
        }

        const existing = await db.User.findOne({ where: { mobile }, attributes: ['id'] });
        if (existing) throw new ApiError(409, 'A user with this mobile number already exists');

        const userId = await db.sequelize.transaction(async (transaction) => {
            const { role, society, house } = await resolveAssignment({
                roleId: toPositiveInt(body.role_id),
                societyId: toPositiveInt(body.society_id),
                houseId: toPositiveInt(body.house_id),
                relationType: body.relation_type
            }, transaction);

            const user = await db.User.create({
                full_name: fullName,
                mobile,
                email: email || null,
                role_id: role.id,
                society_id: society ? society.id : null,
                status
            }, { transaction });

            if (house) await assignFlat(user.id, house, body.relation_type, transaction);
            return user.id;
        });

        const user = await loadUser(userId);
        await logUserAction(req, user, 'CREATED');
        res.status(201).json(new ApiResponse(201, user, 'User created'));
    } catch (e) { next(e); }
};

/**
 * Partial update: only the fields present in the body change. Touching
 * role / society / flat re-validates the whole combination; moving a user to
 * another society closes their flats and building assignments in the old one.
 */
const updateUser = async (req, res, next) => {
    try {
        const id = toPositiveInt(req.params.id);
        if (!id) throw new ApiError(404, 'User not found');
        const body = req.body || {};

        await db.sequelize.transaction(async (transaction) => {
            const user = await db.User.findByPk(id, { transaction });
            if (!user) throw new ApiError(404, 'User not found');

            const changes = {};

            if (body.full_name !== undefined) {
                const fullName = String(body.full_name || '').trim();
                if (!fullName) throw new ApiError(400, 'full_name cannot be empty');
                changes.full_name = fullName;
            }

            if (body.email !== undefined) {
                const email = String(body.email || '').trim();
                if (email && !EMAIL_RE.test(email)) throw new ApiError(400, 'Enter a valid email address');
                changes.email = email || null;
            }

            if (body.mobile !== undefined) {
                const mobile = String(body.mobile || '').trim();
                if (!MOBILE_RE.test(mobile)) throw new ApiError(400, 'Enter a valid 10-digit mobile number');
                if (mobile !== user.mobile) {
                    const taken = await db.User.findOne({
                        where: { mobile, id: { [Op.ne]: user.id } },
                        attributes: ['id'],
                        transaction
                    });
                    if (taken) throw new ApiError(409, 'Another user already has this mobile number');
                    changes.mobile = mobile;
                }
            }

            const touchesAccess = ['role_id', 'society_id', 'house_id'].some(k => body[k] !== undefined);
            if (touchesAccess) {
                const roleId = body.role_id !== undefined ? toPositiveInt(body.role_id) : user.role_id;
                if (user.id === req.user.id && roleId !== user.role_id) {
                    throw new ApiError(400, 'You cannot change your own role');
                }

                const { role, society, house } = await resolveAssignment({
                    roleId,
                    societyId: body.society_id !== undefined
                        ? toPositiveInt(body.society_id)
                        : user.society_id,
                    houseId: toPositiveInt(body.house_id),
                    relationType: body.relation_type
                }, transaction);

                changes.role_id = role.id;
                changes.society_id = society ? society.id : null;

                if (changes.society_id !== user.society_id) {
                    await db.UserHouseMapping.update(
                        { is_active: false, is_primary: false, end_date: new Date() },
                        { where: { user_id: user.id, is_active: true }, transaction }
                    );
                    await db.UserBuilding.destroy({ where: { user_id: user.id }, transaction });
                }
                if (house) await assignFlat(user.id, house, body.relation_type, transaction);
            }

            await user.update(changes, { transaction });
        });

        res.status(200).json(new ApiResponse(200, await loadUser(id), 'User updated'));
    } catch (e) { next(e); }
};

/**
 * Approve / reject / block / unblock. A blocked or rejected user is refused
 * by the auth middleware on their very next request.
 */
const updateUserStatus = async (req, res, next) => {
    try {
        const id = toPositiveInt(req.params.id);
        const status = String((req.body && req.body.status) || '').toLowerCase();
        if (!STATUSES.includes(status)) {
            throw new ApiError(400, `status must be one of: ${STATUSES.join(', ')}`);
        }

        const user = id ? await db.User.findByPk(id) : null;
        if (!user) throw new ApiError(404, 'User not found');
        if (user.id === req.user.id) {
            throw new ApiError(400, 'You cannot change your own account status');
        }

        const previous = user.status;
        if (previous !== status) await user.update({ status });

        const loaded = await loadUser(user.id);
        if (previous !== status) await logUserAction(req, loaded, statusAction(previous, status));

        res.status(200).json(new ApiResponse(200, loaded, STATUS_MESSAGES[status]));
    } catch (e) { next(e); }
};

module.exports = {
    listUsers,
    getUserStats,
    getUser,
    createUser,
    updateUser,
    updateUserStatus
};
