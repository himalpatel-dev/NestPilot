const express = require('express');
const router = express.Router();
const controller = require('../controllers/staff.controller');
const auth = require('../middlewares/auth.middleware');
const { hasPermission } = require('../middlewares/permission.middleware');

router.use(auth);

router.get('/', hasPermission('STAFF', 'view'), controller.getAllStaff);
router.post('/', hasPermission('STAFF', 'create'), controller.addStaff);

// Logging attendance is an update on the STAFF module.
router.post('/attendance', hasPermission('STAFF', 'update'), controller.logAttendance);
router.get('/:staff_id/attendance', hasPermission('STAFF', 'view'), controller.getStaffAttendance);

module.exports = router;
