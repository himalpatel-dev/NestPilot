const express = require('express');
const router = express.Router();
const societyController = require('../controllers/society.controller');
const auth = require('../middlewares/auth.middleware');
const { hasPermission } = require('../middlewares/permission.middleware');

router.post('/', auth, hasPermission('BUILDINGS', 'create'), societyController.createSociety);

// Public discovery endpoint — used during registration to list societies. Stays open.
router.get('/', auth.optional, societyController.getSociety);

router.post('/buildings', auth, hasPermission('BUILDINGS', 'create'), societyController.createBuilding);
router.post('/houses', auth, hasPermission('BUILDINGS', 'create'), societyController.createHouse);
router.get('/houses', auth, hasPermission('BUILDINGS', 'view'), societyController.getAllHouses);
router.get('/house-stats', auth, hasPermission('BUILDINGS', 'view'), societyController.getHouseOccupancyStats);

// Nested society routes — discovery endpoints used during registration. Stay open.
router.get('/:id/buildings', societyController.getBuildingsBySociety);
router.post('/:id/buildings', auth, hasPermission('BUILDINGS', 'create'), societyController.createBuildingForSociety);
router.get('/:id/flats', societyController.getFlatsBySociety);

module.exports = router;
