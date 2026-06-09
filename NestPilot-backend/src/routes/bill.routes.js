const express = require('express');
const router = express.Router();
const controller = require('../controllers/bill.controller');
const auth = require('../middlewares/auth.middleware');
const { hasPermission } = require('../middlewares/permission.middleware');

router.use(auth);

// Admin Bill Mgmt
router.post('/', hasPermission('BILLS', 'create'), controller.create);
router.get('/', hasPermission('BILLS', 'view'), controller.getAll);
router.get('/dashboard', hasPermission('BILLS', 'view'), controller.getDashboard);
router.get('/user/:userId', hasPermission('BILLS', 'view'), controller.getUserBills);
router.post('/:id/publish', hasPermission('BILLS', 'approve'), controller.publish);

// Member Bills (always available to the authenticated user for their own bills)
router.get('/my', controller.getMyBills);

module.exports = router;
