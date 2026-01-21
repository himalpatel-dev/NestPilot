const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const validate = require('../middlewares/validate.middleware');
const { requestOtp, verifyOtp, register } = require('../validators/auth.validator');
const auth = require('../middlewares/auth.middleware');

router.post('/request-otp', validate(requestOtp), authController.requestOtp);
router.post('/verify-otp', validate(verifyOtp), authController.verifyOtp);
router.post('/register', validate(register), authController.register);
router.get('/me', auth, authController.getCurrentUser);

module.exports = router;
