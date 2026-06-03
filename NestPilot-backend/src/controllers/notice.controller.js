const api = require('../services/notice.service');
const ApiResponse = require('../utils/ApiResponse');
const auditService = require('../services/audit.service');

const create = async (req, res, next) => {
    try {
        const data = {
            ...req.body,
            society_id: req.user.society_id,
            created_by: req.user.id
        };
        const result = await api.createNotice(data, req.files);

        try {
            await auditService.logAction(
                req.user.id,
                req.user.society_id,
                'PUBLISHED',
                'NOTICE',
                String(result.id),
                { new_value: { title: result.title }, ip_address: req.ip }
            );
        } catch (_) {}

        res.status(201).json(new ApiResponse(201, result));
    } catch (e) { next(e); }
};

const getAll = async (req, res, next) => {
    try {
        const result = await api.getNotices(req.user.society_id);
        res.status(200).json(new ApiResponse(200, result));
    } catch (e) { next(e); }
};

module.exports = {
    create,
    getAll
};
