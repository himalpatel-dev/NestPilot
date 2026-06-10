const db = require('../models');
const { Op } = require('sequelize');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');

const addVehicle = async (req, res, next) => {
    try {
        const { vehicle_number, type, brand, model, sticker_number } = req.body;

        const existing = await db.Vehicle.findOne({
            where: { vehicle_number, society_id: req.user.society_id }
        });
        if (existing) throw new ApiError(400, 'Vehicle already registered in this society');

        const vehicle = await db.Vehicle.create({
            user_id: req.user.id,
            society_id: req.user.society_id,
            vehicle_number,
            type,
            brand,
            model,
            sticker_number
        });

        res.status(201).json(new ApiResponse(201, vehicle, 'Vehicle added successfully'));
    } catch (e) { next(e); }
};

const getMyVehicles = async (req, res, next) => {
    try {
        const userHouses = await db.UserHouseMapping.findAll({
            where: { user_id: req.user.id, is_active: true },
            attributes: ['house_id']
        });
        const houseIds = userHouses.map(uh => uh.house_id);

        if (houseIds.length === 0) {
            return res.status(200).json(new ApiResponse(200, []));
        }

        const houseMappings = await db.UserHouseMapping.findAll({
            where: { house_id: houseIds, is_active: true },
            attributes: ['user_id']
        });
        const userIds = [...new Set(houseMappings.map(hm => hm.user_id))];

        const vehicles = await db.Vehicle.findAll({
            where: { user_id: userIds, is_active: true }
        });
        res.status(200).json(new ApiResponse(200, vehicles));
    } catch (e) { next(e); }
};

const deleteVehicle = async (req, res, next) => {
    try {
        const userHouses = await db.UserHouseMapping.findAll({
            where: { user_id: req.user.id, is_active: true },
            attributes: ['house_id']
        });
        const houseIds = userHouses.map(uh => uh.house_id);

        const houseMappings = await db.UserHouseMapping.findAll({
            where: { house_id: houseIds, is_active: true },
            attributes: ['user_id']
        });
        const userIds = [...new Set(houseMappings.map(hm => hm.user_id))];

        const vehicle = await db.Vehicle.findOne({
            where: { id: req.params.id, user_id: userIds }
        });
        if (!vehicle) throw new ApiError(404, 'Vehicle not found');

        vehicle.is_active = false;
        await vehicle.save();

        res.status(200).json(new ApiResponse(200, null, 'Vehicle removed'));
    } catch (e) { next(e); }
};

const getAllVehicles = async (req, res, next) => {
    try {
        const where = { society_id: req.user.society_id, is_active: true };

        if (req.userScope && !req.userScope.unscoped) {
            if (!req.userScope.building_ids.length) {
                return res.status(200).json(new ApiResponse(200, []));
            }
            const rows = await db.UserHouseMapping.findAll({
                attributes: ['user_id'],
                include: [{
                    model: db.House,
                    attributes: [],
                    where: { building_id: { [Op.in]: req.userScope.building_ids } },
                    required: true
                }],
                raw: true
            });
            const userIds = Array.from(new Set(rows.map(r => r.user_id)));
            if (!userIds.length) return res.status(200).json(new ApiResponse(200, []));
            where.user_id = { [Op.in]: userIds };
        }

        const vehicles = await db.Vehicle.findAll({
            where,
            include: [{
                model: db.User,
                as: 'owner',
                attributes: ['full_name', 'mobile']
            }]
        });
        res.status(200).json(new ApiResponse(200, vehicles));
    } catch (e) { next(e); }
};

module.exports = {
    addVehicle,
    getMyVehicles,
    deleteVehicle,
    getAllVehicles
};
