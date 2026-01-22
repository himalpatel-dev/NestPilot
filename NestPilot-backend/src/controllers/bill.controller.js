const api = require('../services/bill.service');
const ApiResponse = require('../utils/ApiResponse');

const create = async (req, res, next) => {
    try {
        const data = {
            ...req.body,
            society_id: req.user.society_id,
            created_by: req.user.id
        };
        const result = await api.createBill(data);
        res.status(201).json(new ApiResponse(201, result));
    } catch (e) { next(e); }
};

const publish = async (req, res, next) => {
    try {
        const result = await api.publishBill(req.params.id, req.user.society_id);
        res.status(200).json(new ApiResponse(200, result, 'Bill published and generated for members'));
    } catch (e) { next(e); }
};

const getMyBills = async (req, res, next) => {
    try {
        const result = await api.getMemberBills(req.user.id, req.user.society_id);
        res.status(200).json(new ApiResponse(200, result));
    } catch (e) { next(e); }
};

module.exports = {
    create,
    publish,
    getMyBills
};
