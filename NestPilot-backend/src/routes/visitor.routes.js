const express = require('express');
const router = express.Router();
const controller = require('../controllers/visitor.controller');
const auth = require('../middlewares/auth.middleware');
const { hasPermission, hasAnyPermission } = require('../middlewares/permission.middleware');

router.use(auth);

// Resident / Member Actions
router.post('/invite', hasAnyPermission([{ module: 'VISITORS', action: 'manage' }, { module: 'GATE_CONTROL', action: 'manage' }]), controller.preApproveVisitor);
router.delete('/invite/:id', hasAnyPermission([{ module: 'VISITORS', action: 'manage' }, { module: 'GATE_CONTROL', action: 'manage' }]), controller.cancelInvite);
router.get('/my', hasAnyPermission([{ module: 'VISITORS', action: 'view' }, { module: 'GATE_CONTROL', action: 'view' }]), controller.getMyVisitors);
router.post('/respond', hasAnyPermission([{ module: 'VISITORS', action: 'manage' }, { module: 'GATE_CONTROL', action: 'manage' }]), controller.respondToVisitor);

// Security Gate / Admin Actions
router.get('/dashboard', hasAnyPermission([{ module: 'GATE_CONTROL', action: 'view' }, { module: 'VISITORS', action: 'view' }]), controller.getDashboard);
router.post('/entry', hasAnyPermission([{ module: 'GATE_CONTROL', action: 'manage' }, { module: 'VISITORS', action: 'manage' }]), controller.logEntry);
router.post('/exit', hasAnyPermission([{ module: 'GATE_CONTROL', action: 'manage' }, { module: 'VISITORS', action: 'manage' }]), controller.logExit);
router.get('/inside', hasAnyPermission([{ module: 'GATE_CONTROL', action: 'view' }, { module: 'VISITORS', action: 'view' }]), controller.getInsideVisitors);
router.get('/all', hasAnyPermission([{ module: 'VISITORS', action: 'view' }, { module: 'GATE_CONTROL', action: 'view' }]), controller.getAllSocietyVisitors);
router.get('/houses', hasAnyPermission([{ module: 'GATE_CONTROL', action: 'manage' }, { module: 'VISITORS', action: 'manage' }]), controller.getHouseOptions);
router.get('/verify/:code',hasAnyPermission([{ module: 'GATE_CONTROL', action: 'manage' }, { module: 'VISITORS', action: 'manage' }]), controller.verifyPassCode);

module.exports = router;
