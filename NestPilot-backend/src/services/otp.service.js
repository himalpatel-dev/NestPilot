const crypto = require('crypto');
const bcrypt = require('bcrypt');
const { Op } = require('sequelize');
const db = require('../models');
const ApiError = require('../utils/ApiError');

const generateOtp = () => {
    //return Math.floor(100000 + Math.random() * 900000).toString();
    return "123456";
};

const sendOtp = async (mobile, purpose) => {
    // Check rate limits if needed (count attempts in last X mins)

    const otp = generateOtp();
    const hash = await bcrypt.hash(otp, 10);
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 mins

    await db.OtpRequest.create({
        mobile,
        otp_hash: hash,
        purpose,
        expires_at: expiresAt
    });

    // TODO: Integrate SMS provider
    console.log(`[OTP SERVICE] Mobile: ${mobile}, OTP: ${otp}, Purpose: ${purpose}`);

    return otp; // Return for dev/testing, or just return success
};

const verifyOtp = async (mobile, otp, purpose) => {
    const otpRecord = await db.OtpRequest.findOne({
        where: {
            mobile,
            purpose,
            verified_at: null,
            expires_at: { [Op.gt]: new Date() }
        },
        order: [['created_at', 'DESC']]
    });

    if (!otpRecord) {
        throw new ApiError(400, 'Invalid or expired OTP');
    }

    const isValid = await bcrypt.compare(otp, otpRecord.otp_hash);
    if (!isValid) {
        otpRecord.attempts += 1;
        await otpRecord.save();
        throw new ApiError(400, 'Invalid OTP');
    }

    otpRecord.verified_at = new Date();
    await otpRecord.save();

    return true;
};

module.exports = {
    sendOtp,
    verifyOtp
};
