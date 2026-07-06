const express = require('express');
const router = express.Router();
const societyController = require('../controllers/society.controller');
const auth = require('../middlewares/auth.middleware');
const { hasPermission } = require('../middlewares/permission.middleware');

// Public discovery endpoint — used during registration.
router.get('/:id/flats', societyController.getFlatsByBuilding);
router.post('/:id/flats', auth, hasPermission('BUILDINGS', 'manage'), societyController.createFlatForBuilding);
router.put('/:id/flats/:flatId', auth, hasPermission('BUILDINGS', 'manage'), societyController.updateFlatForBuilding);
router.put('/:id', auth, hasPermission('BUILDINGS', 'manage'), societyController.updateBuilding);

module.exports = router;
