const express = require('express');
const router = express.Router();
const auth = require('../middlewares/auth.middleware');
const { hasPermission } = require('../middlewares/permission.middleware');
const roleCtrl = require('../controllers/role.controller');

// Enum + modules — any authenticated user can fetch (frontend uses for guards)
router.get('/enum', auth, roleCtrl.getRolesEnum);
router.get('/modules', auth, roleCtrl.getModules);

// Current user's effective permissions — used by the mobile app to filter menus and gate action buttons.
router.get('/my-permissions', auth, roleCtrl.getMyPermissions);

// Role CRUD — gated by the ROLES module permissions
router.get('/', auth, hasPermission('ROLES', 'view'), roleCtrl.getAllRoles);
router.post('/', auth, hasPermission('ROLES', 'create'), roleCtrl.createRole);
router.put('/:id', auth, hasPermission('ROLES', 'update'), roleCtrl.updateRole);
router.delete('/:id', auth, hasPermission('ROLES', 'delete'), roleCtrl.deleteRole);

// Permission management per role
router.get('/:id/permissions', auth, hasPermission('ROLES', 'view'), roleCtrl.getRolePermissions);
router.put('/:id/permissions', auth, hasPermission('ROLES', 'update'), roleCtrl.updateRolePermissions);

module.exports = router;
