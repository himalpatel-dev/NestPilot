const db = require('../models');
const { Op } = require('sequelize');
const ApiError = require('../utils/ApiError');
const ApiResponse = require('../utils/ApiResponse');
const auditService = require('../services/audit.service');
const { isUnscoped, scopeBuildingIn } = require('../middlewares/scope.middleware');

/**
 * Returns the set of user_ids in the caller's society that live in at least
 * one in-scope building. Returns null when the caller is unscoped (no filter).
 */
const userIdsInScope = async (req) => {
    if (isUnscoped(req)) return null;
    const buildingIds = req.userScope.building_ids;
    if (!buildingIds.length) return [];

    const rows = await db.UserHouseMapping.findAll({
        attributes: ['user_id'],
        include: [{
            model: db.House,
            attributes: [],
            where: { building_id: { [Op.in]: buildingIds } },
            required: true
        }],
        raw: true
    });
    return Array.from(new Set(rows.map(r => r.user_id)));
};

const resolveUserHouseNo = async (userId) => {
    try {
        const mapping = await db.UserHouseMapping.findOne({
            where: { user_id: userId, is_active: true },
            include: [{ model: db.House, attributes: ['house_no'] }]
        });
        return mapping && mapping.House ? mapping.House.house_no : null;
    } catch (_) {
        return null;
    }
};

const getPendingUsers = async (req, res, next) => {
    try {
        const where = {
            society_id: req.user.society_id,
            status: 'pending'
        };

        const scopedIds = await userIdsInScope(req);
        if (scopedIds !== null) {
            if (!scopedIds.length) return res.status(200).json(new ApiResponse(200, []));
            where.id = { [Op.in]: scopedIds };
        }

        const users = await db.User.findAll({
            where,
            include: [
                { model: db.Role },
                {
                    model: db.UserHouseMapping,
                    include: [db.House]
                }
            ]
        });
        res.status(200).json(new ApiResponse(200, users));
    } catch (e) { next(e); }
};

const approveUser = async (req, res, next) => {
    try {
        const { id } = req.params;
        const user = await db.User.findOne({
            where: { id, society_id: req.user.society_id }
        });

        if (!user) throw new ApiError(404, 'User not found');

        const scopedIds = await userIdsInScope(req);
        if (scopedIds !== null && !scopedIds.includes(user.id)) {
            throw new ApiError(403, 'User is outside your assigned buildings');
        }

        user.status = 'active';
        await user.save();

        try {
            const house_no = await resolveUserHouseNo(user.id);
            await auditService.logAction(
                req.user.id,
                req.user.society_id,
                'APPROVED',
                'RESIDENT',
                String(user.id),
                { new_value: { title: user.full_name, house_no }, ip_address: req.ip }
            );
        } catch (_) {}

        res.status(200).json(new ApiResponse(200, user, 'User approved'));
    } catch (e) { next(e); }
};

const rejectUser = async (req, res, next) => {
    try {
        const { id } = req.params;
        const user = await db.User.findOne({
            where: { id, society_id: req.user.society_id }
        });

        if (!user) throw new ApiError(404, 'User not found');

        const scopedIds = await userIdsInScope(req);
        if (scopedIds !== null && !scopedIds.includes(user.id)) {
            throw new ApiError(403, 'User is outside your assigned buildings');
        }

        user.status = 'rejected';
        await user.save();

        try {
            const house_no = await resolveUserHouseNo(user.id);
            await auditService.logAction(
                req.user.id,
                req.user.society_id,
                'DENIED',
                'RESIDENT',
                String(user.id),
                { new_value: { title: user.full_name, house_no }, ip_address: req.ip }
            );
        } catch (_) {}

        res.status(200).json(new ApiResponse(200, user, 'User rejected'));
    } catch (e) { next(e); }
};

const getSocietyMembers = async (req, res, next) => {
    try {
        const where = {
            society_id: req.user.society_id,
            status: 'active'
        };

        const scopedIds = await userIdsInScope(req);
        if (scopedIds !== null) {
            if (!scopedIds.length) return res.status(200).json(new ApiResponse(200, []));
            where.id = { [Op.in]: scopedIds };
        }

        const users = await db.User.findAll({
            where,
            include: [
                { model: db.Role },
                {
                    model: db.UserHouseMapping,
                    include: [db.House]
                }
            ]
        });
        res.status(200).json(new ApiResponse(200, users));
    } catch (e) { next(e); }
};

const getDashboardStats = async (req, res, next) => {
    try {
        const societyId = req.user.society_id;
        const buildingIn = scopeBuildingIn(req); // undefined if unscoped
        const scopedIds = await userIdsInScope(req);
        const userIdFilter = scopedIds === null ? undefined : { [Op.in]: scopedIds };

        const userWhere = (status, extra = {}) => {
            const w = { society_id: societyId, status, ...extra };
            if (userIdFilter) w.id = userIdFilter;
            return w;
        };

        const buildingScopedComplaintCount = async () => {
            if (!buildingIn) {
                return db.Complaint.count({ where: { society_id: societyId } });
            }
            return db.Complaint.count({
                where: { society_id: societyId },
                include: [{
                    model: db.House,
                    attributes: [],
                    where: { building_id: buildingIn },
                    required: true
                }]
            });
        };

        const noticeCount = () => {
            const w = { society_id: societyId };
            if (buildingIn) {
                // Society-wide (building_id null) OR targeted to one of my buildings
                w[Op.and] = [{ [Op.or]: [{ building_id: null }, { building_id: buildingIn }] }];
            }
            return db.Notice.count({ where: w });
        };

        const [pendingMembers, totalResidents, totalNotices, totalComplaints] = await Promise.all([
            db.User.count({ where: userWhere('pending') }),
            db.User.count({
                where: userWhere('active'),
                include: [{
                    model: db.Role,
                    where: { code: 'MEMBER' },
                    required: true
                }]
            }),
            noticeCount(),
            buildingScopedComplaintCount(),
        ]);

        res.status(200).json(new ApiResponse(200, {
            pending_members: pendingMembers,
            total_residents: totalResidents,
            total_notices: totalNotices,
            total_complaints: totalComplaints,
        }));
    } catch (e) { next(e); }
};

module.exports = {
    getPendingUsers,
    approveUser,
    rejectUser,
    getSocietyMembers,
    getDashboardStats
};
