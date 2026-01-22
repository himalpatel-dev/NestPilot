const Joi = require('joi');

const requestOtp = Joi.object({
    mobile: Joi.string().pattern(/^[0-9]{10}$/).required().messages({ 'string.pattern.base': 'Mobile number must be 10 digits' }),
    purpose: Joi.string().valid('LOGIN', 'REGISTER').required()
});

const verifyOtp = Joi.object({
    mobile: Joi.string().pattern(/^[0-9]{10}$/).required(),
    otp: Joi.string().length(6).required()
});

const register = Joi.object({
    fullName: Joi.string().required(),
    mobile: Joi.string().pattern(/^[0-9]{10}$/).required(),
    societyId: Joi.number().integer().required(),
    buildingId: Joi.number().integer().required(),
    houseId: Joi.number().integer().required(),
    relationType: Joi.string().valid('OWNER', 'TENANT', 'FAMILY').required(),
    email: Joi.string().email().optional().allow('')
});

module.exports = {
    requestOtp,
    verifyOtp,
    register
};
