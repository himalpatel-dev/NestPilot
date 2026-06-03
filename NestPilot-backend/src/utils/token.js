const jwt = require('jsonwebtoken');

const ensureSecret = () => {
    if (!process.env.JWT_SECRET) {
        throw new Error('JWT_SECRET is not set. Please set JWT_SECRET in your environment.');
    }
};

const generateToken = (payload) => {
    ensureSecret();
    return jwt.sign(payload, process.env.JWT_SECRET, {
        expiresIn: process.env.JWT_EXPIRES_IN || '30d',
    });
};

const verifyToken = (token) => {
    ensureSecret();
    return jwt.verify(token, process.env.JWT_SECRET);
};

module.exports = {
    generateToken,
    verifyToken,
};
