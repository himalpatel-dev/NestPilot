const otpService = require('../services/otp.service');
const authService = require('../services/auth.service');
const ApiResponse = require('../utils/ApiResponse');
const catchAsync = require('../utils/catchAsync');

const requestOtp = catchAsync(async (req, res) => {
    const { mobile, purpose } = req.body;
    await otpService.sendOtp(mobile, purpose);
    res.status(200).json(new ApiResponse(200, null, 'OTP sent successfully'));
});

const verifyOtp = catchAsync(async (req, res) => {
    const { mobile, otp, purpose } = req.body;

    // For login flow:
    // If purpose is LOGIN (default), verify OTP then generate Token.
    await otpService.verifyOtp(mobile, otp, 'LOGIN');

    const result = await authService.login(mobile);
    res.status(200).json(new ApiResponse(200, result, 'Login successful'));
});

const register = catchAsync(async (req, res) => {
    const user = await authService.register(req.body);
    res.status(201).json(new ApiResponse(201, user, 'Registration successful. Please wait for admin approval.'));
});

const getCurrentUser = catchAsync(async (req, res) => {
    const user = await authService.getMe(req.user.id);
    res.status(200).json(new ApiResponse(200, user, 'User profile fetched'));
});

module.exports = {
    requestOtp,
    verifyOtp,
    register,
    getCurrentUser
};
