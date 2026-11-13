const express = require('express');
const router = express.Router();
const auth = require('../middlewares/auth.middleware');
const authorize = require('../middlewares/role.middleware');
const ctrl = require('../controllers/user.controller');

// Platform-wide user management — Super Admin only. Society Admins manage
// their own residents through /admin, which is scoped to their buildings.
router.use(auth);
router.use(authorize(['SUPER_ADMIN']));

router.get('/', ctrl.listUsers);
router.get('/stats', ctrl.getUserStats);
router.post('/', ctrl.createUser);
router.get('/:id', ctrl.getUser);
router.put('/:id', ctrl.updateUser);
router.patch('/:id/status', ctrl.updateUserStatus);

module.exports = router;
