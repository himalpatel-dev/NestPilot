const db = require('../models');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');

/**
 * Super-Admin-only endpoints to manage which buildings each SOCIETY_ADMIN
 * is responsible for. Society Admins themselves cannot touch these.
 */

const listSocietyAdmins = async (req, res, next) => {
    try {
        const where = { '$Role.code$': 'SOCIETY_ADMIN' };
        if (req.query.society_id) {
            where.society_id = Number(req.query.society_id);
        }

        const admins = await db.User.findAll({
            where,
            include: [
                { model: db.Role, attributes: ['code', 'name'] },
                { model: db.Society, attributes: ['id', 'name'] },
                { association: 'assignedBuildings', attributes: ['id', 'name'], through: { attributes: [] } }
            ],
            attributes: ['id', 'full_name', 'mobile', 'email', 'status', 'society_id'],
            order: [['id', 'ASC']]
        });

        res.status(200).json(new ApiResponse(200, admins));
    } catch (e) { next(e); }
};

const getAssignments = async (req, res, next) => {
    try {
        const user = await db.User.findByPk(req.params.userId, {
            include: [
                { model: db.Role, attributes: ['code'] },
                { association: 'assignedBuildings', attributes: ['id', 'name', 'society_id'], through: { attributes: [] } }
            ]
        });
        if (!user) throw new ApiError(404, 'User not found');
        if (!user.Role || user.Role.code !== 'SOCIETY_ADMIN') {
            throw new ApiError(400, 'Only Society Admins can have building assignments');
        }
        res.status(200).json(new ApiResponse(200, {
            user_id: user.id,
            society_id: user.society_id,
            buildings: user.assignedBuildings || []
        }));
    } catch (e) { next(e); }
};

const setAssignments = async (req, res, next) => {
    const t = await db.sequelize.transaction();
    try {
        const userId = Number(req.params.userId);
        const { building_ids } = req.body;
        if (!Array.isArray(building_ids)) {
            throw new ApiError(400, 'building_ids must be an array');
        }

        const user = await db.User.findByPk(userId, {
            include: [{ model: db.Role, attributes: ['code'] }],
            transaction: t
        });
        if (!user) throw new ApiError(404, 'User not found');
        if (!user.Role || user.Role.code !== 'SOCIETY_ADMIN') {
            throw new ApiError(400, 'Only Society Admins can have building assignments');
        }

        const ids = Array.from(new Set(building_ids.map(Number).filter(n => Number.isInteger(n) && n > 0)));

        if (ids.length) {
            const buildings = await db.Building.findAll({
                where: { id: ids },
                attributes: ['id', 'society_id'],
                transaction: t
            });
            if (buildings.length !== ids.length) {
                throw new ApiError(400, 'One or more building ids are invalid');
            }
            const mismatched = buildings.filter(b => b.society_id !== user.society_id);
            if (mismatched.length) {
                throw new ApiError(400, 'All buildings must belong to the user\'s society');
            }
        }

        await db.UserBuilding.destroy({ where: { user_id: userId }, transaction: t });

        if (ids.length) {
            await db.UserBuilding.bulkCreate(
                ids.map(building_id => ({
                    user_id: userId,
                    building_id,
                    assigned_by: req.user.id
                })),
                { transaction: t }
            );
        }

        await t.commit();
        res.status(200).json(new ApiResponse(200, { user_id: userId, building_ids: ids }, 'Assignments updated'));
    } catch (e) {
        await t.rollback();
        next(e);
    }
};

const addAssignment = async (req, res, next) => {
    try {
        const userId = Number(req.params.userId);
        const buildingId = Number(req.params.buildingId);

        const user = await db.User.findByPk(userId, { include: [{ model: db.Role, attributes: ['code'] }] });
        if (!user) throw new ApiError(404, 'User not found');
        if (!user.Role || user.Role.code !== 'SOCIETY_ADMIN') {
            throw new ApiError(400, 'Only Society Admins can have building assignments');
        }

        const building = await db.Building.findByPk(buildingId);
        if (!building) throw new ApiError(404, 'Building not found');
        if (building.society_id !== user.society_id) {
            throw new ApiError(400, 'Building belongs to a different society');
        }

        const [row, created] = await db.UserBuilding.findOrCreate({
            where: { user_id: userId, building_id: buildingId },
            defaults: { assigned_by: req.user.id }
        });

        res.status(created ? 201 : 200).json(new ApiResponse(created ? 201 : 200, row));
    } catch (e) { next(e); }
};

const removeAssignment = async (req, res, next) => {
    try {
        const userId = Number(req.params.userId);
        const buildingId = Number(req.params.buildingId);
        const deleted = await db.UserBuilding.destroy({ where: { user_id: userId, building_id: buildingId } });
        if (!deleted) throw new ApiError(404, 'Assignment not found');
        res.status(200).json(new ApiResponse(200, { user_id: userId, building_id: buildingId }, 'Assignment removed'));
    } catch (e) { next(e); }
};

module.exports = {
    listSocietyAdmins,
    getAssignments,
    setAssignments,
    addAssignment,
    removeAssignment
};
