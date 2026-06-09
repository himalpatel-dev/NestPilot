const express = require('express');
const router = express.Router();
const auth = require('../middlewares/auth.middleware');
const authorize = require('../middlewares/role.middleware');
const roleCtrl = require('../controllers/role.controller');
const ROLES = require('../constants/roles');

// Enum + modules — any authenticated user can fetch (frontend uses for guards)
router.get('/enum', auth, roleCtrl.getRolesEnum);
router.get('/modules', auth, roleCtrl.getModules);

// Current user's effective permissions — used by the mobile app to filter menus and gate action buttons.
router.get('/my-permissions', auth, roleCtrl.getMyPermissions);

// Role CRUD — SUPER_ADMIN manages, SOCIETY_ADMIN can read
router.get('/', auth, authorize([ROLES.SUPER_ADMIN, ROLES.SOCIETY_ADMIN]), roleCtrl.getAllRoles);
router.post('/', auth, authorize([ROLES.SUPER_ADMIN]), roleCtrl.createRole);
router.put('/:id', auth, authorize([ROLES.SUPER_ADMIN]), roleCtrl.updateRole);
router.delete('/:id', auth, authorize([ROLES.SUPER_ADMIN]), roleCtrl.deleteRole);

// Permission management per role
router.get('/:id/permissions', auth, authorize([ROLES.SUPER_ADMIN, ROLES.SOCIETY_ADMIN]), roleCtrl.getRolePermissions);
router.put('/:id/permissions', auth, authorize([ROLES.SUPER_ADMIN]), roleCtrl.updateRolePermissions);

module.exports = router;
