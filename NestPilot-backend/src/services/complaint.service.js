const db = require('../models');

const createComplaint = async (data, file) => {
    if (file) {
        data.image_path = file.path;
    }
    return db.Complaint.create(data);
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

const updateStatus = async (id, status, societyId) => {
    const complaint = await db.Complaint.findOne({ where: { id, society_id: societyId } });
    if (!complaint) throw new Error('Complaint not found');

    complaint.status = status;
    return complaint.save();
};

const addComment = async (complaintId, userId, message) => {
    return db.ComplaintComment.create({
        complaint_id: complaintId,
        user_id: userId,
        message
    });
};

module.exports = {
    createComplaint,
    getComplaints,
    updateStatus,
    addComment
};
