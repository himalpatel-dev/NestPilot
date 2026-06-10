const { Op } = require('sequelize');
const db = require('../models');

/**
 * Per-building data scoping for non-Super-Admin users.
 *
 * After auth, this attaches req.userScope:
 *   { unscoped: true }                                  -> SUPER_ADMIN (sees everything)
 *   { society_id, building_ids: [int], unscoped: false } -> SOCIETY_ADMIN, MEMBER, etc.
 *
 * SOCIETY_ADMIN building_ids come from tbl_user_buildings (assigned by Super Admin).
 * MEMBER building_ids are derived from their active house mappings.
 * Any other role with no explicit mapping gets an empty list (fail-closed).
 *
 * Controllers consume this via scopeWhereByBuilding(req) to filter list queries.
 */
const attachScope = async (req, res, next) => {
    try {
        if (!req.user) return next();

        const roleCode = req.user.Role && req.user.Role.code;

        if (roleCode === 'SUPER_ADMIN') {
            req.userScope = { unscoped: true };
            return next();
        }

        let buildingIds = [];

        if (roleCode === 'SOCIETY_ADMIN') {
            const rows = await db.UserBuilding.findAll({
                where: { user_id: req.user.id },
                attributes: ['building_id']
            });
            buildingIds = rows.map(r => r.building_id);
        } else if (roleCode === 'MEMBER') {
            const mappings = await db.UserHouseMapping.findAll({
                where: { user_id: req.user.id, is_active: true },
                include: [{ model: db.House, attributes: ['building_id'] }]
            });
            const ids = new Set();
            mappings.forEach(m => { if (m.House) ids.add(m.House.building_id); });
            buildingIds = Array.from(ids);
        } else {
            // SECURITY_GUARD / staff / future roles — also try the explicit mapping
            const rows = await db.UserBuilding.findAll({
                where: { user_id: req.user.id },
                attributes: ['building_id']
            });
            buildingIds = rows.map(r => r.building_id);
        }

        req.userScope = {
            unscoped: false,
            society_id: req.user.society_id,
            building_ids: buildingIds
        };
        next();
    } catch (e) {
        next(e);
    }
};

/**
 * Returns a Sequelize WHERE fragment that filters by building_id according
 * to the request's scope. Usage:
 *
 *   const where = { society_id, ...scopeWhereByBuilding(req) };
 *   await db.House.findAll({ where });
 *
 * For joined queries where the building_id lives on an included model, use
 * scopeBuildingIn(req) to get the raw [Op.in] fragment:
 *
 *   include: [{ model: db.House, where: { building_id: scopeBuildingIn(req) }, required: true }]
 */
const scopeWhereByBuilding = (req, column = 'building_id') => {
    if (!req.userScope || req.userScope.unscoped) return {};
    return { [column]: { [Op.in]: req.userScope.building_ids } };
};

const scopeBuildingIn = (req) => {
    if (!req.userScope || req.userScope.unscoped) return undefined;
    return { [Op.in]: req.userScope.building_ids };
};

/**
 * True when the request is unscoped (Super Admin) — controllers can skip
 * joins entirely in that case.
 */
const isUnscoped = (req) => !!(req.userScope && req.userScope.unscoped);

/**
 * Throws 403 unless the given building_id is inside the caller's scope.
 * Used by write endpoints to stop a Society Admin from creating data
 * for a building they don't own.
 */
const assertBuildingInScope = (req, buildingId) => {
    if (!req.userScope) {
        const e = new Error('Forbidden: no scope attached');
        e.statusCode = 403;
        throw e;
    }
    if (req.userScope.unscoped) return;
    if (!req.userScope.building_ids.includes(Number(buildingId))) {
        const e = new Error('Forbidden: building outside your scope');
        e.statusCode = 403;
        throw e;
    }
};

module.exports = {
    attachScope,
    scopeWhereByBuilding,
    scopeBuildingIn,
    isUnscoped,
    assertBuildingInScope
};
