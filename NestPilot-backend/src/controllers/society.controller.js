const societyService = require('../services/society.service');
const ApiResponse = require('../utils/ApiResponse');

const getSociety = async (req, res, next) => {
    try {
        const data = await societyService.getSocietyDetails(req.user.society_id);
        res.status(200).json(new ApiResponse(200, data));
    } catch (e) { next(e); }
};

const createBuilding = async (req, res, next) => {
    try {
        const data = await societyService.createBuilding({ ...req.body, society_id: req.user.society_id });
        res.status(201).json(new ApiResponse(201, data));
    } catch (e) { next(e); }
};

const createHouse = async (req, res, next) => {
    try {
        const data = await societyService.createHouse({ ...req.body, society_id: req.user.society_id });
        res.status(201).json(new ApiResponse(201, data));
    } catch (e) { next(e); }
};

const getAllHouses = async (req, res, next) => {
    try {
        const data = await societyService.getHouses(req.user.society_id);
        res.status(200).json(new ApiResponse(200, data));
    } catch (e) { next(e); }
};

const createSociety = async (req, res, next) => {
    try {
        const data = await societyService.createSociety(req.body);
        res.status(201).json(new ApiResponse(201, data));
    } catch (e) { next(e); }
};

module.exports = {
    getSociety,
    createSociety,
    createBuilding,
    createHouse,
    getAllHouses
};
