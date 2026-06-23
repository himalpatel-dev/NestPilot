const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');
const auth = require('../middlewares/auth.middleware');
const { hasPermission } = require('../middlewares/permission.middleware');

router.use(auth);

// Dashboard view = needs to see the dashboard module
router.get('/dashboard-stats', hasPermission('DASHBOARD', 'view'), adminController.getDashboardStats);
router.get('/super-admin-stats', adminController.getSuperAdminStats);

// Pending users + members are USERS-module views
router.get('/pending-users', hasPermission('USERS', 'view'), adminController.getPendingUsers);
router.get('/members', hasPermission('USERS', 'view'), adminController.getSocietyMembers);

// Approve / reject pending residents = USERS approve
router.post('/users/:id/approve', hasPermission('USERS', 'approve'), adminController.approveUser);
router.post('/users/:id/reject', hasPermission('USERS', 'approve'), adminController.rejectUser);

module.exports = router;
