const db = require('../models');
const api = require('../services/payment.service');
const ApiResponse = require('../utils/ApiResponse');
const path = require('path');

const syncOffline = async (req, res, next) => {
    try {
        const { payments } = req.body;
        if (!Array.isArray(payments)) throw new Error('Payments must be an array');

        const result = await api.syncOfflinePayments(payments, req.user.id, req.user.society_id);
        res.status(200).json(new ApiResponse(200, result));
    } catch (e) { next(e); }
};

const downloadReceipt = async (req, res, next) => {
    try {
        const receipt = await api.getReceipt(req.params.paymentId);
        if (!receipt || !receipt.receipt_pdf_path) return res.status(404).send('Receipt not found');

        const filePath = path.join(__dirname, '../../', receipt.receipt_pdf_path);
        res.download(filePath);
    } catch (e) { next(e); }
};

const getMyPayments = async (req, res, next) => {
    try {
        const mappings = await db.UserHouseMapping.findAll({
            where: { user_id: req.user.id, is_active: true },
            attributes: ['house_id']
        });
        const houseIds = mappings.map(m => m.house_id);

        if (houseIds.length === 0) {
            return res.status(200).json(new ApiResponse(200, []));
        }

        const payments = await db.Payment.findAll({
            where: { house_id: houseIds },
            order: [['payment_date', 'DESC']]
        });

        res.status(200).json(new ApiResponse(200, payments));
    } catch (e) { next(e); }
};

module.exports = {
    syncOffline,
    downloadReceipt,
    getMyPayments
};
