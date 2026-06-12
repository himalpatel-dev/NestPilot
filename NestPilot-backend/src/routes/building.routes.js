const express = require('express');
const router = express.Router();
const societyController = require('../controllers/society.controller');
const auth = require('../middlewares/auth.middleware');
const { hasPermission } = require('../middlewares/permission.middleware');

// Public discovery endpoint — used during registration.
router.get('/:id/flats', societyController.getFlatsByBuilding);
router.post('/:id/flats', auth, hasPermission('BUILDINGS', 'create'), societyController.createFlatForBuilding);
router.put('/:id', auth, hasPermission('BUILDINGS', 'update'), societyController.updateBuilding);

module.exports = router;
