const db = require('../models');


const createNotice = async (data, files) => {
    const transaction = await db.sequelize.transaction();
    try {
        const notice = await db.Notice.create(data, { transaction });

        if (files && files.length > 0) {
            const attachments = files.map(f => ({
                notice_id: notice.id,
                file_type: f.mimetype,
                file_path: f.path,
                original_name: f.originalname
            }));
            await db.NoticeAttachment.bulkCreate(attachments, { transaction });
        }

        // --- Notification Logic Start ---
        let usersToNotify = [];
        if (data.building_id) {
            // Fetch users belonging to this building
            const users = await db.User.findAll({
                attributes: ['id'],
                include: [{
                    model: db.UserHouseMapping,
                    required: true,
                    include: [{
                        model: db.House,
                        attributes: [],
                        where: { building_id: data.building_id },
                        required: true
                    }]
                }],
                where: { society_id: data.society_id, status: 'active' },
                transaction
            });
            usersToNotify = users.map(u => u.id);
        } else {
            // Fetch all users in society
            const users = await db.User.findAll({
                attributes: ['id'],
                where: { society_id: data.society_id, status: 'active' },
                transaction
            });
            usersToNotify = users.map(u => u.id);
        }

        // Remove duplicates and exclude the creator
        usersToNotify = [...new Set(usersToNotify)].filter(id => id !== data.created_by);

        if (usersToNotify.length > 0) {
            const notifications = usersToNotify.map(userId => ({
                user_id: userId,
                society_id: data.society_id,
                type: 'NOTICE',
                title: 'New Notice Posted',
                message: data.title, // Use title as message or construct a message
                reference_id: notice.id,
                is_read: false
            }));
            await db.Notification.bulkCreate(notifications, { transaction });

            // Emit Socket Events
            try {
                const io = require('../utils/socket').getIo();
                usersToNotify.forEach(userId => {
                    io.to(`user_${userId}`).emit('new_notification', {
                        title: 'New Notice Posted',
                        message: data.title,
                        type: 'NOTICE'
                    });
                });
            } catch (socketError) {
                console.error("Socket emit failed (non-critical):", socketError);
            }
        }
        // --- Notification Logic End ---

        await transaction.commit();



        return notice;
    } catch (err) {
        await transaction.rollback();
        throw err;
    }
};

const getNotices = async (societyId) => {
    return db.Notice.findAll({
        where: { society_id: societyId, is_active: true },
        include: [db.NoticeAttachment],
        order: [['publish_date', 'DESC']]
    });
};

module.exports = {
    createNotice,
    getNotices
};
