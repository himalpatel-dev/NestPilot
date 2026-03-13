const db = require('../models');
const ApiResponse = require('../utils/ApiResponse');

const getNotifications = async (req, res, next) => {
    try {
        const userId = req.user.id;
        const { limit = 20, offset = 0 } = req.query;

        const notifications = await db.Notification.findAndCountAll({
            where: { user_id: userId },
            order: [['created_at', 'DESC']],
            limit: parseInt(limit),
            offset: parseInt(offset)
        });

        const unreadCount = await db.Notification.count({
            where: { user_id: userId, is_read: false }
        });

        res.status(200).json(new ApiResponse(200, {
            notifications: notifications.rows,
            count: notifications.count,
            unreadCount
        }));
    } catch (e) {
        next(e);
    }
};

const markAsRead = async (req, res, next) => {
    try {
        const { id } = req.params;
        const userId = req.user.id;

        if (id === 'all') {
            await db.Notification.update(
                { is_read: true },
                { where: { user_id: userId, is_read: false } }
            );
        } else {
            const notification = await db.Notification.findOne({
                where: { id, user_id: userId }
            });
            if (notification) {
                notification.is_read = true;
                await notification.save();
            }
        }

        res.status(200).json(new ApiResponse(200, { success: true }));
    } catch (e) {
        next(e);
    }
};

module.exports = {
    getNotifications,
    markAsRead
};
