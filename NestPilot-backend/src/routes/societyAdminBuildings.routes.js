const express = require('express');
const router = express.Router();
const auth = require('../middlewares/auth.middleware');
const authorize = require('../middlewares/role.middleware');
const ctrl = require('../controllers/societyAdminBuildings.controller');

router.use(auth);
router.use(authorize(['SUPER_ADMIN']));

router.get('/', ctrl.listSocietyAdmins);
router.get('/:userId/buildings', ctrl.getAssignments);
router.put('/:userId/buildings', ctrl.setAssignments);
router.post('/:userId/buildings/:buildingId', ctrl.addAssignment);
router.delete('/:userId/buildings/:buildingId', ctrl.removeAssignment);

module.exports = router;
