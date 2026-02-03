const express = require('express');
const router = express.Router();
const controller = require('../controllers/vehicle.controller');
const auth = require('../middlewares/auth.middleware');
const role = require('../middlewares/role.middleware');
router.use(auth);

router.post('/', controller.addVehicle);
router.get('/', controller.getMyVehicles);
router.get('/all', role(['SOCIETY_ADMIN']), controller.getAllVehicles); // Admin route
router.delete('/:id', controller.deleteVehicle);

module.exports = router;
