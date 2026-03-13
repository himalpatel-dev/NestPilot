const db = require('../models');

const createComplaint = async (data, file) => {
    if (file) {
        data.image_path = file.path;
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

const getComplaints = async (user, societyId) => {
    const where = { society_id: societyId };
    if (user.Role.code === 'MEMBER') {
        where.created_by = user.id;
    }

    return db.Complaint.findAll({
        where,
        include: [
            { model: db.User, as: 'createdBy', attributes: ['full_name'] },
            { model: db.ComplaintComment, include: [{ model: db.User, attributes: ['full_name'] }] },
            { model: db.House, attributes: ['house_no', 'wing'] } // Include optional house details
        ],
        order: [['created_at', 'DESC']]
    });
};

const updateStatus = async (id, status, societyId, currentUserId) => {
    const complaint = await db.Complaint.findOne({ where: { id, society_id: societyId } });
    if (!complaint) throw new Error('Complaint not found');

    complaint.status = status;
    await complaint.save();

    // Notify Creator if status updated by someone else
    // Notify Creator and Admins
    try {
        const io = require('../utils/socket').getIo();

        // 1. Notify Creator (if not self)
        if (String(complaint.created_by) !== String(currentUserId)) {
            await db.Notification.create({
                user_id: complaint.created_by,
                society_id: societyId,
                type: 'COMPLAINT',
                title: 'Complaint Status Updated',
                message: `Your complaint status has been updated to ${status}`,
                reference_id: complaint.id,
                is_read: false
            });

            // Notification
            io.to(`user_${complaint.created_by}`).emit('new_notification', {
                title: 'Complaint Status Updated',
                message: `Your complaint status has been updated to ${status}`,
                type: 'COMPLAINT'
            });

            // Real-time Status Update
            console.log(`Emitting complaint_status_updated for complaint ${id} to user_${complaint.created_by} with status ${status}`);
            io.to(`user_${complaint.created_by}`).emit('complaint_status_updated', {
                complaint_id: id,
                status: status
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
        let targetUserId = null;

        // If comment by Creator -> Notify Admins?
        // If comment by Admin -> Notify Creator?

        // Simpler: If commenter != creator, notify creator.
        if (String(userId) !== String(complaint.created_by)) {
            targetUserId = complaint.created_by;
        } else {
            // Commenter IS creator. Notify Admins.
            try {
                const adminUsers = await db.User.findAll({
                    where: { society_id: complaint.society_id, status: 'active' },
                    include: [{ model: db.Role, where: { code: 'SOCIETY_ADMIN' } }]
                });

                if (adminUsers.length > 0) {
                    // Filter admins who are NOT the commenter
                    const notifyAdmins = adminUsers.filter(a => String(a.id) !== String(userId));

                    if (notifyAdmins.length > 0) {
                        const notifications = notifyAdmins.map(admin => ({
                            user_id: admin.id,
                            society_id: complaint.society_id,
                            type: 'COMPLAINT',
                            title: title,
                            message: msg,
                            reference_id: complaint.id,
                            is_read: false
                        }));
                        await db.Notification.bulkCreate(notifications);

                        const io = require('../utils/socket').getIo();
                        notifyAdmins.forEach(admin => {
                            // Emit Notification
                            io.to(`user_${admin.id}`).emit('new_notification', {
                                title: title,
                                message: msg,
                                type: 'COMPLAINT'
                            });
                            // Emit New Comment Data for Real-time Chat
                            io.to(`user_${admin.id}`).emit('new_comment', {
                                complaint_id: complaintId,
                                comment: fullComment
                            });
                        });
                    }
                }
            } catch (e) { console.error("Comment Notification Error:", e); }
            return fullComment;
        }

        if (targetUserId) {
            try {
                await db.Notification.create({
                    user_id: targetUserId,
                    society_id: complaint.society_id,
                    type: 'COMPLAINT',
                    title: title,
                    message: msg,
                    reference_id: complaint.id,
                    is_read: false
                });

                const io = require('../utils/socket').getIo();
                // Emit Notification
                io.to(`user_${targetUserId}`).emit('new_notification', {
                    title: title,
                    message: msg,
                    type: 'COMPLAINT'
                });
                // Emit New Comment Data for Real-time Chat
                io.to(`user_${targetUserId}`).emit('new_comment', {
                    complaint_id: complaintId,
                    comment: fullComment
                });
            } catch (e) { console.error("Comment Notification Error:", e); }
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
