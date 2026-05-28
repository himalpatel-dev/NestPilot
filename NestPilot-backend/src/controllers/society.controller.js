const societyService = require('../services/society.service');
const ApiResponse = require('../utils/ApiResponse');

const getSociety = async (req, res, next) => {
    try {
        if (!req.user || (req.user.Role && req.user.Role.code === 'SUPER_ADMIN')) {
            const data = await societyService.getAllSocieties();
            return res.status(200).json(new ApiResponse(200, data));
        }
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

const getBuildingsBySociety = async (req, res, next) => {
    try {
        const data = await societyService.getBuildingsBySocietyId(req.params.id);
        res.status(200).json(new ApiResponse(200, data));
    } catch (e) { next(e); }
};

const createBuildingForSociety = async (req, res, next) => {
    try {
        const data = await societyService.createBuilding({
            ...req.body,
            society_id: req.params.id
        });
        res.status(201).json(new ApiResponse(201, data));
    } catch (e) { next(e); }
};

const getFlatsByBuilding = async (req, res, next) => {
    try {
        const data = await societyService.getFlatsByBuildingId(req.params.id);
        res.status(200).json(new ApiResponse(200, data));
    } catch (e) { next(e); }
};

const createFlatForBuilding = async (req, res, next) => {
    try {
        const building = await societyService.getBuildingById(req.params.id);
        if (!building) {
            return res.status(404).json(new ApiResponse(404, null, 'Building not found'));
        }
        const data = await societyService.createHouse({
            ...req.body,
            building_id: req.params.id,
            society_id: building.society_id
        });
        res.status(201).json(new ApiResponse(201, data));
    } catch (e) { next(e); }
};

const getFlatsBySociety = async (req, res, next) => {
    try {
        const data = await societyService.getFlatsBySocietyId(req.params.id);
        res.status(200).json(new ApiResponse(200, data));
    } catch (e) { next(e); }
};

module.exports = {
    getSociety,
    createSociety,
    createBuilding,
    createHouse,
    getAllHouses,
    getBuildingsBySociety,
    createBuildingForSociety,
    getFlatsByBuilding,
    createFlatForBuilding,
    getFlatsBySociety
};

