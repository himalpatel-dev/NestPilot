const express = require('express');
const router = express.Router();
const controller = require('../controllers/visitor.controller');
const auth = require('../middlewares/auth.middleware');
const { hasPermission } = require('../middlewares/permission.middleware');

router.use(auth);

// Resident Actions
router.post('/invite', hasPermission('VISITORS', 'manage'), controller.preApproveVisitor);
router.delete('/invite/:id', hasPermission('VISITORS', 'manage'), controller.cancelInvite);
router.get('/my', hasPermission('VISITORS', 'view'), controller.getMyVisitors);
router.post('/respond', hasPermission('VISITORS', 'manage'), controller.respondToVisitor);

// Security / Admin Actions
router.get('/dashboard', hasPermission('VISITORS', 'view'), controller.getDashboard);
router.post('/entry', hasPermission('VISITORS', 'manage'), controller.logEntry);
router.post('/exit', hasPermission('VISITORS', 'manage'), controller.logExit);
router.get('/inside', hasPermission('VISITORS', 'view'), controller.getInsideVisitors);
router.get('/all', hasPermission('VISITORS', 'view'), controller.getAllSocietyVisitors);
router.get('/verify/:code', hasPermission('VISITORS', 'manage'), controller.verifyPassCode);

module.exports = router;
