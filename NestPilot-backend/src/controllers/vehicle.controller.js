const db = require('../models');
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
        const vehicles = await db.Vehicle.findAll({
            where: { user_id: req.user.id, is_active: true }
        });
        res.status(200).json(new ApiResponse(200, vehicles));
    } catch (e) { next(e); }
};

const deleteVehicle = async (req, res, next) => {
    try {
        const vehicle = await db.Vehicle.findOne({
            where: { id: req.params.id, user_id: req.user.id }
        });
        if (!vehicle) throw new ApiError(404, 'Vehicle not found');

        vehicle.is_active = false;
        await vehicle.save();

        res.status(200).json(new ApiResponse(200, null, 'Vehicle removed'));
    } catch (e) { next(e); }
};

const getAllVehicles = async (req, res, next) => {
    try {
        const vehicles = await db.Vehicle.findAll({
            where: { society_id: req.user.society_id, is_active: true },
            include: [{
                model: db.User,
                as: 'owner',
                attributes: ['full_name', 'mobile'] // Removed flat_number as strictly it's not on User model directly usually, but checked User model earlier it might be. Checked user.model.js earlier: flat_number is NOT on User model directly, it's relationType/flatId etc. Wait, let me check user.model.js again to be safe.
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
