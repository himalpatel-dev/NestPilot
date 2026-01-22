const jwt = require('jsonwebtoken');
const ApiError = require('../utils/ApiError');
const { verifyToken } = require('../utils/token');
const db = require('../models');

const auth = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            throw new ApiError(401, 'Unauthorized access');
        }

        const token = authHeader.split(' ')[1];
        if (!token) {
            throw new ApiError(401, 'Unauthorized access');
        }

        try {
            const decoded = verifyToken(token);

            const user = await db.User.findByPk(decoded.userId, {
                include: [{ model: db.Role }]
            });

            if (!user) {
                throw new ApiError(401, 'User not found or inactive');
            }

            if (user.status !== 'active') {
                // allow only if checking status? No, usually block. 
                // But for registration flow, we might need flexibility? 
                // For now, strict: only active users can use auth routes (except status check).
                // Actually, newly registered users are 'pending'. They can't do much until approved.
                if (user.status === 'blocked' || user.status === 'rejected') {
                    throw new ApiError(403, 'Account blocked or rejected');
                }
            }

            req.user = user;
            next();
        } catch (err) {
            throw new ApiError(401, 'Invalid or expired token');
        }
    } catch (error) {
        next(error);
    }
};

module.exports = auth;
