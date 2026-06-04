const db = require('../models');
const ApiError = require('../utils/ApiError');
const ApiResponse = require('../utils/ApiResponse');
const auditService = require('../services/audit.service');

const resolveUserHouseNo = async (userId) => {
    try {
        const mapping = await db.UserHouseMapping.findOne({
            where: { user_id: userId, is_active: true },
            include: [{ model: db.House, attributes: ['house_no'] }]
        });
        return mapping && mapping.House ? mapping.House.house_no : null;
    } catch (_) {
        return null;
    }
};

const getPendingUsers = async (req, res, next) => {
    try {
        const users = await db.User.findAll({
            where: {
                society_id: req.user.society_id,
                status: 'pending'
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

const approveUser = async (req, res, next) => {
    try {
        const { id } = req.params;
        const user = await db.User.findOne({
            where: { id, society_id: req.user.society_id }
        });

        if (!user) throw new ApiError(404, 'User not found');

        user.status = 'active';
        await user.save();

        try {
            const house_no = await resolveUserHouseNo(user.id);
            await auditService.logAction(
                req.user.id,
                req.user.society_id,
                'APPROVED',
                'RESIDENT',
                String(user.id),
                { new_value: { title: user.full_name, house_no }, ip_address: req.ip }
            );
        } catch (_) {}

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

        try {
            const house_no = await resolveUserHouseNo(user.id);
            await auditService.logAction(
                req.user.id,
                req.user.society_id,
                'DENIED',
                'RESIDENT',
                String(user.id),
                { new_value: { title: user.full_name, house_no }, ip_address: req.ip }
            );
        } catch (_) {}

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

const getDashboardStats = async (req, res, next) => {
    try {
        const societyId = req.user.society_id;

        const [pendingMembers, totalResidents, totalNotices, totalComplaints] = await Promise.all([
            db.User.count({
                where: { society_id: societyId, status: 'pending' }
            }),
            db.User.count({
                where: { society_id: societyId, status: 'active' },
                include: [{
                    model: db.Role,
                    where: { code: 'MEMBER' },
                    required: true
                }]
            }),
            db.Notice.count({
                where: { society_id: societyId }
            }),
            db.Complaint.count({
                where: { society_id: societyId }
            }),
        ]);

        res.status(200).json(new ApiResponse(200, {
            pending_members: pendingMembers,
            total_residents: totalResidents,
            total_notices: totalNotices,
            total_complaints: totalComplaints,
        }));
    } catch (e) { next(e); }
};

module.exports = {
    getPendingUsers,
    approveUser,
    rejectUser,
    getSocietyMembers,
    getDashboardStats
};
