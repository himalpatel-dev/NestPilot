const express = require('express');
const router = express.Router();
const controller = require('../controllers/visitor.controller');
const auth = require('../middlewares/auth.middleware');
const role = require('../middlewares/role.middleware');

router.use(auth);

// Resident Actions
router.post('/invite', controller.preApproveVisitor);
router.get('/my', controller.getMyVisitors);
router.post('/respond', controller.respondToVisitor);

// Security / Admin Actions (In a real app, we'd have a specific SECURITY_GUARD role)
router.post('/entry', role(['SOCIETY_ADMIN', 'SECURITY_GUARD', 'MEMBER']), controller.logEntry);
router.post('/exit', role(['SOCIETY_ADMIN', 'SECURITY_GUARD', 'MEMBER']), controller.logExit);
router.get('/inside', role(['SOCIETY_ADMIN', 'SECURITY_GUARD']), controller.getInsideVisitors);
router.get('/all', role(['SOCIETY_ADMIN', 'SECURITY_GUARD']), controller.getAllSocietyVisitors);
router.get('/verify/:code', role(['SOCIETY_ADMIN', 'SECURITY_GUARD']), controller.verifyPassCode);

module.exports = router;
