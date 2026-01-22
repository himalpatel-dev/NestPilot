const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');
const auth = require('../middlewares/auth.middleware');
const role = require('../middlewares/role.middleware');

router.use(auth);
router.use(role(['SOCIETY_ADMIN']));

router.get('/pending-users', adminController.getPendingUsers);
router.get('/members', adminController.getSocietyMembers);
router.post('/users/:id/approve', adminController.approveUser);
router.post('/users/:id/reject', adminController.rejectUser);

module.exports = router;
