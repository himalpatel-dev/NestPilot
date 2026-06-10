const db = require('../models');
const { Op } = require('sequelize');

const createComplaint = async (data, file) => {
    if (file) {
        data.image_path = file.path;
    }

    if (!data.house_id) {
        const mapping = await db.UserHouseMapping.findOne({
            where: { user_id: data.created_by, is_active: true }
        });
        if (mapping) {
            data.house_id = mapping.house_id;
        }
    }

    const complaint = await db.Complaint.create(data);

    // Notify Society Admins
    try {


        // The where clause for User should be society_id: data.society_id. 
        // Previously used 'society_id' in other files.
        const adminUsers = await db.User.findAll({
            where: { society_id: data.society_id, status: 'active' },
            include: [{
                model: db.Role,
                where: { code: 'SOCIETY_ADMIN' }
            }]
        });

        if (adminUsers.length > 0) {
            const notifications = adminUsers.map(admin => ({
                user_id: admin.id,
                society_id: data.society_id,
                type: 'COMPLAINT',
                title: 'New Complaint Posted',
                message: `New complaint regarding ${data.type || 'issue'}`,
                reference_id: complaint.id,
                is_read: false
            }));
            await db.Notification.bulkCreate(notifications);

            const io = require('../utils/socket').getIo();
            adminUsers.forEach(admin => {
                io.to(`user_${admin.id}`).emit('new_notification', {
                    title: 'New Complaint Posted',
                    message: `New complaint regarding ${data.type || 'issue'}`,
                    type: 'COMPLAINT'
                });
            });
        }
    } catch (e) {
        console.error("Complaint Notification Error:", e);
    }

    return complaint;
};

const getComplaints = async (user, societyId, userScope) => {
    const where = { society_id: societyId };
    const houseInclude = { model: db.House, attributes: ['house_no', 'wing', 'building_id'] };

    if (user.Role.code === 'MEMBER') {
        const userHouses = await db.UserHouseMapping.findAll({
            where: { user_id: user.id, is_active: true },
            attributes: ['house_id']
        });
        const houseIds = userHouses.map(uh => uh.house_id);
        where[Op.or] = [
            { house_id: houseIds },
            { created_by: user.id }
        ];
    } else if (userScope && !userScope.unscoped) {
        // SOCIETY_ADMIN / staff: limit to complaints whose house lives in an assigned building
        if (!userScope.building_ids.length) return [];
        houseInclude.where = { building_id: { [Op.in]: userScope.building_ids } };
        houseInclude.required = true;
    }

    return db.Complaint.findAll({
        where,
        include: [
            { model: db.User, as: 'createdBy', attributes: ['full_name'] },
            { model: db.ComplaintComment, include: [{ model: db.User, attributes: ['full_name'] }] },
            houseInclude
        ],
        order: [['created_at', 'DESC']]
    });
};

const updateStatus = async (id, status, societyId, currentUserId, userScope) => {
    const complaint = await db.Complaint.findOne({
        where: { id, society_id: societyId },
        include: [{ model: db.House, attributes: ['building_id'] }]
    });
    if (!complaint) throw new Error('Complaint not found');

    if (userScope && !userScope.unscoped && complaint.House) {
        if (!userScope.building_ids.includes(complaint.House.building_id)) {
            const err = new Error('Complaint is outside your assigned buildings');
            err.statusCode = 403;
            throw err;
        }
    }

    complaint.status = status;
    await complaint.save();

    // Notify Creator and co-residents if status updated by someone else
    try {
        const io = require('../utils/socket').getIo();

        let houseUserIds = [];
        if (complaint.house_id) {
            const mappings = await db.UserHouseMapping.findAll({
                where: { house_id: complaint.house_id, is_active: true },
                attributes: ['user_id']
            });
            houseUserIds = mappings.map(m => m.user_id).filter(uid => String(uid) !== String(currentUserId));
        } else {
            if (String(complaint.created_by) !== String(currentUserId)) {
                houseUserIds = [complaint.created_by];
            }
        }

        if (houseUserIds.length > 0) {
            const notifications = houseUserIds.map(uid => ({
                user_id: uid,
                society_id: societyId,
                type: 'COMPLAINT',
                title: 'Complaint Status Updated',
                message: `Your complaint status has been updated to ${status}`,
                reference_id: complaint.id,
                is_read: false
            }));
            await db.Notification.bulkCreate(notifications);

            houseUserIds.forEach(uid => {
                io.to(`user_${uid}`).emit('new_notification', {
                    title: 'Complaint Status Updated',
                    message: `Your complaint status has been updated to ${status}`,
                    type: 'COMPLAINT'
                });
                io.to(`user_${uid}`).emit('complaint_status_updated', {
                    complaint_id: id,
                    status: status
                });
            });
        }

        // 2. Notify Admins (if not self)
        // Check if current user is admin? Even if so, other admins might need update.
        // Let's just broadcast status update to relevant admins.
        const adminUsers = await db.User.findAll({
            where: { society_id: societyId, status: 'active' },
            include: [{ model: db.Role, where: { code: 'SOCIETY_ADMIN' } }]
        });

        adminUsers.forEach(admin => {
            // If the current user is an admin updating it, they don't need a socket event (handled by API response),
            // but other admins do. 
            if (String(admin.id) !== String(currentUserId)) {
                // Optional: Notification for admins? Maybe overkill.
                // Just emit status update for real-time UI
                io.to(`user_${admin.id}`).emit('complaint_status_updated', {
                    complaint_id: id,
                    status: status
                });
            }
        });

    } catch (e) { console.error("Notification Error:", e); }
    return complaint;
};

const addComment = async (complaintId, userId, message) => {
    const comment = await db.ComplaintComment.create({
        complaint_id: complaintId,
        user_id: userId,
        message
    });

    // Fetch full comment with User for response and socket
    const fullComment = await db.ComplaintComment.findByPk(comment.id, {
        include: [{ model: db.User, attributes: ['full_name'] }]
    });

    const complaint = await db.Complaint.findByPk(complaintId);
    if (complaint) {
        let title = 'New Comment on Complaint';
        let msg = `New comment: ${message}`;

        // Get commenter details to check role
        const commenter = await db.User.findByPk(userId, { include: [db.Role] });
        const isCommenterAdmin = commenter && (commenter.Role.code === 'SOCIETY_ADMIN' || commenter.Role.code === 'SUPER_ADMIN');

        let usersToNotify = [];
        let adminsToNotify = [];

        // 1. Determine admins to notify
        if (!isCommenterAdmin) {
            const adminUsers = await db.User.findAll({
                where: { society_id: complaint.society_id, status: 'active' },
                include: [{ model: db.Role, where: { code: 'SOCIETY_ADMIN' } }]
            });
            adminsToNotify = adminUsers.filter(a => String(a.id) !== String(userId));
        }

        // 2. Determine house residents to notify
        if (complaint.house_id) {
            const mappings = await db.UserHouseMapping.findAll({
                where: { house_id: complaint.house_id, is_active: true },
                attributes: ['user_id']
            });
            usersToNotify = mappings.map(m => m.user_id).filter(uid => String(uid) !== String(userId));
        } else {
            // Fallback if no house is associated
            if (String(complaint.created_by) !== String(userId)) {
                usersToNotify = [complaint.created_by];
            }
        }

        // Combine into arrays for bulk insertion and socket emissions
        const allRecipientIds = [...new Set([...usersToNotify, ...adminsToNotify.map(a => a.id)])];

        if (allRecipientIds.length > 0) {
            try {
                const notifications = allRecipientIds.map(uid => ({
                    user_id: uid,
                    society_id: complaint.society_id,
                    type: 'COMPLAINT',
                    title: title,
                    message: msg,
                    reference_id: complaint.id,
                    is_read: false
                }));
                await db.Notification.bulkCreate(notifications);

                const io = require('../utils/socket').getIo();
                allRecipientIds.forEach(uid => {
                    io.to(`user_${uid}`).emit('new_notification', {
                        title: title,
                        message: msg,
                        type: 'COMPLAINT'
                    });
                    io.to(`user_${uid}`).emit('new_comment', {
                        complaint_id: complaintId,
                        comment: fullComment
                    });
                });
            } catch (e) {
                console.error("Comment Notification Error:", e);
            }
        }
    }
    return fullComment;
};

module.exports = {
    createComplaint,
    getComplaints,
    updateStatus,
    addComment
};
