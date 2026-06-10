const api = require('../services/bill.service');
const ApiResponse = require('../utils/ApiResponse');
const auditService = require('../services/audit.service');

const create = async (req, res, next) => {
    try {
        const data = {
            ...req.body,
            society_id: req.user.society_id,
            created_by: req.user.id
        };
        const result = await api.createBill(data, req.userScope);

        try {
            await auditService.logAction(
                req.user.id,
                req.user.society_id,
                'CREATED',
                'BILL',
                String(result.id),
                { new_value: { title: result.title, ref_code: result.id }, ip_address: req.ip }
            );
        } catch (_) {}

        res.status(201).json(new ApiResponse(201, result));
    } catch (e) { next(e); }
};

const publish = async (req, res, next) => {
    try {
        const result = await api.publishBill(req.params.id, req.user.society_id, req.user.id, req.userScope);

        try {
            await auditService.logAction(
                req.user.id,
                req.user.society_id,
                'GENERATED',
                'BILL',
                String(result.id),
                { new_value: { title: result.title, ref_code: result.id }, ip_address: req.ip }
            );
        } catch (_) {}

        res.status(200).json(new ApiResponse(200, result, 'Bill published and generated for members'));
    } catch (e) { next(e); }
};

const getMyBills = async (req, res, next) => {
    try {
        const result = await api.getMemberBills(req.user.id, req.user.society_id);
        res.status(200).json(new ApiResponse(200, result));
    } catch (e) { next(e); }
};

const getAll = async (req, res, next) => {
    try {
        const result = await api.getBillsBySociety(req.user.society_id, req.userScope);
        res.status(200).json(new ApiResponse(200, result));
    } catch (e) { next(e); }
};

const getUserBills = async (req, res, next) => {
    try {
        const result = await api.getMemberBills(req.params.userId, req.user.society_id);
        res.status(200).json(new ApiResponse(200, result));
    } catch (e) { next(e); }
};

const getDashboard = async (req, res, next) => {
    try {
        const month = req.query.month || null;
        const result = await api.getDashboardData(req.user.society_id, month, req.userScope);
        res.status(200).json(new ApiResponse(200, result));
    } catch (e) { next(e); }
};

module.exports = {
    create,
    publish,
    getMyBills,
    getAll,
    getUserBills,
    getDashboard
};
