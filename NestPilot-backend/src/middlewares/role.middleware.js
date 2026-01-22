const ApiError = require('../utils/ApiError');

const authorize = (roles = []) => {
    return (req, res, next) => {
        if (!req.user || !req.user.Role) {
            return next(new ApiError(403, 'Forbidden: No role assigned'));
        }

        const userRole = req.user.Role.code;
        if (roles.length && !roles.includes(userRole)) {
            return next(new ApiError(403, 'Forbidden: Insufficient permissions'));
        }

        next();
    };
};

module.exports = authorize;
