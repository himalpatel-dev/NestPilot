const express = require('express');
const router = express.Router();
const controller = require('../controllers/staff.controller');
const auth = require('../middlewares/auth.middleware');
const role = require('../middlewares/role.middleware');

router.use(auth);

router.get('/', controller.getAllStaff);
router.post('/', role(['SOCIETY_ADMIN']), controller.addStaff);

router.post('/attendance', role(['SOCIETY_ADMIN', 'SECURITY_GUARD', 'MEMBER']), controller.logAttendance);
router.get('/:staff_id/attendance', controller.getStaffAttendance);

module.exports = router;
