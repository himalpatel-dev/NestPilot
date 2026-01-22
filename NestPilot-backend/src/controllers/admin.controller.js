const db = require('../models');
const ApiError = require('../utils/ApiError');
const ApiResponse = require('../utils/ApiResponse');

const getPendingUsers = async (req, res, next) => {
    try {
        const users = await db.User.findAll({
            where: {
                society_id: req.user.society_id,
                status: 'pending'
            },
            include: [db.Role]
        });
        res.status(200).json(new ApiResponse(200, users));
    } catch (e) { next(e); }
};

const approveUser = async (req, res, next) => {
    try {
        const { id } = req.params;
        const user = await db.User.findOne({
            where: { id, society_id: req.user.society_id }
        });

        if (!user) throw new ApiError(404, 'User not found');

        user.status = 'active';
        await user.save();

        res.status(200).json(new ApiResponse(200, user, 'User approved'));
    } catch (e) { next(e); }
};

const rejectUser = async (req, res, next) => {
    try {
        const { id } = req.params;
        const user = await db.User.findOne({
            where: { id, society_id: req.user.society_id }
        });

        if (!user) throw new ApiError(404, 'User not found');

        user.status = 'rejected';
        await user.save();

        res.status(200).json(new ApiResponse(200, user, 'User rejected'));
    } catch (e) { next(e); }
};

const getSocietyMembers = async (req, res, next) => {
    try {
        const users = await db.User.findAll({
            where: {
                society_id: req.user.society_id,
                status: 'active'
            },
            include: [
                { model: db.Role },
                {
                    model: db.UserHouseMapping,
                    include: [db.House]
                }
            ]
        });
        res.status(200).json(new ApiResponse(200, users));
    } catch (e) { next(e); }
};

module.exports = {
    getPendingUsers,
    approveUser,
    rejectUser,
    getSocietyMembers
};
