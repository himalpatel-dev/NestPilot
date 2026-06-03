const api = require('../services/complaint.service');
const ApiResponse = require('../utils/ApiResponse');
const auditService = require('../services/audit.service');

const create = async (req, res, next) => {
    try {
        const data = {
            ...req.body,
            society_id: req.user.society_id,
            created_by: req.user.id,
            house_id: req.body.houseId
        };

        const result = await api.createComplaint(data, req.file);
        res.status(201).json(new ApiResponse(201, result));
    } catch (e) { next(e); }
};

const getAll = async (req, res, next) => {
    try {
        const result = await api.getComplaints(req.user, req.user.society_id);
        res.status(200).json(new ApiResponse(200, result));
    } catch (e) { next(e); }
};

const updateStatus = async (req, res, next) => {
    try {
        const { status } = req.body;
        const result = await api.updateStatus(req.params.id, status, req.user.society_id, req.user.id);

        try {
            const normalized = String(status || '').toUpperCase();
            const trackedActions = ['RESOLVED', 'CLOSED', 'REOPENED', 'IN_PROGRESS'];
            if (trackedActions.includes(normalized)) {
                await auditService.logAction(
                    req.user.id,
                    req.user.society_id,
                    normalized,
                    'COMPLAINT',
                    String(result.id),
                    { new_value: { ref_code: `C-${result.id}` }, ip_address: req.ip }
                );
            }
        } catch (_) {}

        res.status(200).json(new ApiResponse(200, result));
    } catch (e) { next(e); }
};

const addComment = async (req, res, next) => {
    try {
        const { message } = req.body;
        const result = await api.addComment(req.params.id, req.user.id, message);
        res.status(201).json(new ApiResponse(201, result));
    } catch (e) { next(e); }
};

module.exports = {
    create,
    getAll,
    updateStatus,
    addComment
};
