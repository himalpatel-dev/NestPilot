const { Op } = require('sequelize');
const db = require('../models');

const getSocietyDetails = async (societyId) => {
    return db.Society.findByPk(societyId, {
        include: [{
            model: db.Building,
            include: [{ model: db.House }]
        }]
    });
};

const createSociety = async (data) => {
    return db.Society.create(data);
};

const createBuilding = async (data) => {
    return db.Building.create(data);
};

const createHouse = async (data) => {
    return db.House.create(data);
};

const updateHouse = async (id, data) => {
    const house = await db.House.findByPk(id);
    if (!house) return null;
    return house.update(data);
};

const getHouses = async (societyId) => {
    return db.House.findAll({
        where: { society_id: societyId },
        include: [db.Building]
    });
};

const getAllSocieties = async () => {
    return db.Society.findAll();
};

const updateSociety = async (id, data) => {
    const society = await db.Society.findByPk(id);
    if (!society) return null;
    return society.update(data);
};

const updateBuilding = async (id, data) => {
    const building = await db.Building.findByPk(id);
    if (!building) return null;
    return building.update(data);
};

const getBuildingById = async (id) => {
    return db.Building.findByPk(id);
};

const getBuildingsBySocietyId = async (societyId) => {
    return db.Building.findAll({
        where: { society_id: societyId }
    });
};

const getFlatsByBuildingId = async (buildingId) => {
    return db.House.findAll({
        where: { building_id: buildingId }
    });
};

const getFlatsBySocietyId = async (societyId) => {
    return db.House.findAll({
        where: { society_id: societyId },
        include: [db.Building]
    });
};

// Soft delete via status — a society has no is_active flag, and hard-deleting
// one would cascade across its entire tenant (buildings, flats, users, notices,
// bills). Setting status keeps it reversible. Note: the list endpoints do not
// yet filter on status, so an inactive society still appears until that's added.
const deleteSociety = async (id) => {
    const society = await db.Society.findByPk(id);
    if (!society) return null;
    return society.update({ status: 'inactive' });
};

// Hard delete, guarded. Buildings have no is_active flag and no ON DELETE
// cascade, so removing one that still has flats would either orphan rows or be
// rejected by the FK. Require the flats to be gone first.
const deleteBuilding = async (id) => {
    const building = await db.Building.findByPk(id);
    if (!building) return null;

    const activeHouses = await db.House.count({
        where: { building_id: id, is_active: true }
    });
    if (activeHouses > 0) {
        const err = new Error('Remove the flats in this building before deleting it');
        err.statusCode = 400;
        throw err;
    }

    await building.destroy();
    return { message: 'Building deleted' };
};

// Soft delete — houses carry an is_active flag.
const deleteHouse = async (id) => {
    const house = await db.House.findByPk(id);
    if (!house) return null;
    return house.update({ is_active: false });
};

const getHouseOccupancyStats = async (societyId) => {
    const [totalHouses, occupiedHouses, ownerCount, tenantCount] = await Promise.all([
        db.House.count({
            where: { society_id: societyId, is_active: true }
        }),
        db.House.count({
            where: { society_id: societyId, is_active: true },
            include: [{
                model: db.UserHouseMapping,
                where: { is_active: true },
                required: true
            }],
            distinct: true
        }),
        db.UserHouseMapping.count({
            where: { is_active: true, relation_type: 'OWNER' },
            include: [{
                model: db.House,
                where: { society_id: societyId, is_active: true },
                required: true
            }]
        }),
        db.UserHouseMapping.count({
            where: { is_active: true, relation_type: 'TENANT' },
            include: [{
                model: db.House,
                where: { society_id: societyId, is_active: true },
                required: true
            }]
        }),
    ]);

    return {
        total_houses: totalHouses,
        occupied_houses: occupiedHouses,
        vacant_houses: totalHouses - occupiedHouses,
        owner_count: ownerCount,
        tenant_count: tenantCount,
    };
};

const SOCIETY_TYPES = ['APARTMENT', 'TENEMENT', 'ROW_HOUSE', 'COMMERCIAL', 'MIXED'];

// Per-society counts as correlated sub-selects, so a page of societies costs
// one query instead of several count calls per row.
const directoryCounts = () => {
    const count = (sql) => db.sequelize.literal(`(${sql})`);
    return [
        [count('SELECT COUNT(*) FROM tbl_buildings b WHERE b.society_id = "Society"."id"'), 'buildings_count'],
        [count('SELECT COUNT(*) FROM tbl_houses h WHERE h.society_id = "Society"."id" AND h.is_active = true'), 'flats_count'],
        [count('SELECT COUNT(*) FROM tbl_users u WHERE u.society_id = "Society"."id" AND u.status = \'active\''), 'active_users_count'],
        [count('SELECT COUNT(*) FROM tbl_users u WHERE u.society_id = "Society"."id" AND u.status = \'pending\''), 'pending_users_count'],
        [count(
            'SELECT COUNT(*) FROM tbl_users u JOIN tbl_roles r ON r.id = u.role_id ' +
            'WHERE u.society_id = "Society"."id" AND u.status = \'active\' AND r.code = \'SOCIETY_ADMIN\''
        ), 'admins_count']
    ];
};

/**
 * Paged society directory for the Super Admin: search, status and type
 * filters, per-society counts, and an overall active/inactive summary.
 * Status is a free string defaulting to 'active' and deleteSociety sets
 * 'inactive', so anything other than 'inactive' (null included) is active.
 */
const getSocietyDirectory = async ({ page, limit, search, status, type }) => {
    const where = {};
    if (search) {
        const like = { [Op.iLike]: `%${search}%` };
        where[Op.or] = [
            { name: like },
            { city: like },
            { district: like },
            { state: like },
            { pincode: like },
            { address: like },
            // society_type is an enum, so cast it; "row house" still finds
            // ROW_HOUSE because '_' is a one-character wildcard in ILIKE.
            db.sequelize.where(
                db.sequelize.cast(db.sequelize.col('society_type'), 'TEXT'),
                { [Op.iLike]: `%${search.replace(/\s+/g, '_')}%` }
            )
        ];
    }
    if (status === 'inactive') where.status = 'inactive';
    if (status === 'active') where.status = { [Op.or]: { [Op.ne]: 'inactive', [Op.is]: null } };
    if (SOCIETY_TYPES.includes(type)) where.society_type = type;

    const [total, items, byStatus] = await Promise.all([
        db.Society.count({ where }),
        db.Society.findAll({
            where,
            attributes: { include: directoryCounts() },
            order: [['name', 'ASC'], ['id', 'ASC']],
            limit,
            offset: (page - 1) * limit
        }),
        db.Society.findAll({
            attributes: ['status', [db.sequelize.fn('COUNT', db.sequelize.col('id')), 'count']],
            group: ['status'],
            raw: true
        })
    ]);

    const summary = { total: 0, active: 0, inactive: 0 };
    byStatus.forEach(r => {
        const n = Number(r.count) || 0;
        summary.total += n;
        if (r.status === 'inactive') summary.inactive += n;
        else summary.active += n;
    });

    return { items, total, page, limit, has_more: page * limit < total, summary };
};

module.exports = {
    getSocietyDetails,
    getSocietyDirectory,
    createSociety,
    createBuilding,
    createHouse,
    updateHouse,
    getHouses,
    getAllSocieties,
    updateSociety,
    updateBuilding,
    getBuildingById,
    getBuildingsBySocietyId,
    getFlatsByBuildingId,
    getFlatsBySocietyId,
    getHouseOccupancyStats,
    deleteSociety,
    deleteBuilding,
    deleteHouse
};

