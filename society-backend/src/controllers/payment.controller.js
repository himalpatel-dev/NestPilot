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
    // Implementation similar to bills
    // db.Payment.findAll({ where: { user_id: req.user.id } })
    res.json(new ApiResponse(200, [])); // stub
};

module.exports = {
    syncOffline,
    downloadReceipt,
    getMyPayments
};
