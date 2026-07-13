const locationService = require('../services/location.service');
const ApiResponse = require('../utils/ApiResponse');

const getStates = async (req, res, next) => {
    try {
        const data = await locationService.getStates();
        res.status(200).json(new ApiResponse(200, data));
    } catch (e) { next(e); }
};

const getDistricts = async (req, res, next) => {
    try {
        const stateId = req.params.stateId || req.query.state_id;
        const data = await locationService.getDistricts(stateId);
        res.status(200).json(new ApiResponse(200, data));
    } catch (e) { next(e); }
};

module.exports = {
    getStates,
    getDistricts,
};
