const db = require('../models');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');

const uploadDocument = async (req, res, next) => {
    try {
        const { title, category, is_private } = req.body;

        if (!req.file) throw new ApiError(400, 'File is required');

        const doc = await db.Document.create({
            society_id: req.user.society_id,
            uploaded_by: req.user.id,
            title,
            category,
            is_private: is_private === 'true',
            file_url: `/uploads/documents/${req.file.filename}`
        });

        res.status(201).json(new ApiResponse(201, doc, 'Document uploaded'));
    } catch (e) { next(e); }
};

const getDocuments = async (req, res, next) => {
    try {
        const docs = await db.Document.findAll({
            where: { society_id: req.user.society_id },
            order: [['created_at', 'DESC']]
        });
        res.status(200).json(new ApiResponse(200, docs));
    } catch (e) { next(e); }
};

const deleteDocument = async (req, res, next) => {
    try {
        const doc = await db.Document.findByPk(req.params.id);
        if (!doc) throw new ApiError(404, 'Document not found');
        if (doc.society_id !== req.user.society_id) throw new ApiError(403, 'Unauthorized');

        await doc.destroy();
        res.status(200).json(new ApiResponse(200, null, 'Document deleted'));
    } catch (e) { next(e); }
};

module.exports = {
    uploadDocument,
    getDocuments,
    deleteDocument
};
