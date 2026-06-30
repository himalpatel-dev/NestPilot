const express = require('express');
const router = express.Router();
const controller = require('../controllers/vehicle.controller');
const auth = require('../middlewares/auth.middleware');
const { hasPermission } = require('../middlewares/permission.middleware');
router.use(auth);

router.post('/', hasPermission('VEHICLES', 'create'), controller.addVehicle);
router.get('/', hasPermission('VEHICLES', 'view'), controller.getMyVehicles);
router.get('/all', hasPermission('VEHICLES', 'view'), controller.getAllVehicles);
router.delete('/:id', hasPermission('VEHICLES', 'delete'), controller.deleteVehicle);

module.exports = router;
