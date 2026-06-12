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

const updateSociety = async (req, res, next) => {
    try {
        const { name, address, city, state, pincode, society_type, status } = req.body;
        const data = await societyService.updateSociety(req.params.id, {
            ...(name !== undefined && { name }),
            ...(address !== undefined && { address }),
            ...(city !== undefined && { city }),
            ...(state !== undefined && { state }),
            ...(pincode !== undefined && { pincode }),
            ...(society_type !== undefined && { society_type }),
            ...(status !== undefined && { status }),
        });
        if (!data) {
            return res.status(404).json(new ApiResponse(404, null, 'Society not found'));
        }
        res.status(200).json(new ApiResponse(200, data));
    } catch (e) { next(e); }
};

const updateBuilding = async (req, res, next) => {
    try {
        const { name, blocks, wings, floors_count } = req.body;
        const data = await societyService.updateBuilding(req.params.id, {
            ...(name !== undefined && { name }),
            ...(blocks !== undefined && { blocks }),
            ...(wings !== undefined && { wings }),
            ...(floors_count !== undefined && { floors_count }),
        });
        if (!data) {
            return res.status(404).json(new ApiResponse(404, null, 'Building not found'));
        }
        res.status(200).json(new ApiResponse(200, data));
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

const getHouseOccupancyStats = async (req, res, next) => {
    try {
        const societyId = req.user.society_id;
        const data = await societyService.getHouseOccupancyStats(societyId);
        res.status(200).json(new ApiResponse(200, data));
    } catch (e) { next(e); }
};

module.exports = {
    getSociety,
    createSociety,
    updateSociety,
    createBuilding,
    updateBuilding,
    createHouse,
    getAllHouses,
    getBuildingsBySociety,
    createBuildingForSociety,
    getFlatsByBuilding,
    createFlatForBuilding,
    getFlatsBySociety,
    getHouseOccupancyStats
};

