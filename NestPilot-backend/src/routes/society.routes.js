const express = require('express');
const router = express.Router();
const societyController = require('../controllers/society.controller');
const auth = require('../middlewares/auth.middleware');
const role = require('../middlewares/role.middleware');

// Only SOCIETY_ADMIN can manage buildings/houses
router.post('/', auth, role(['SUPER_ADMIN']), societyController.createSociety);
router.get('/', auth.optional, societyController.getSociety);
router.post('/buildings', auth, role(['SOCIETY_ADMIN']), societyController.createBuilding);
router.post('/houses', auth, role(['SOCIETY_ADMIN']), societyController.createHouse);
router.get('/houses', auth, societyController.getAllHouses);

// Super admin specific or nested routes
router.get('/:id/buildings', societyController.getBuildingsBySociety);
router.post('/:id/buildings', auth, role(['SUPER_ADMIN']), societyController.createBuildingForSociety);
router.get('/:id/flats', societyController.getFlatsBySociety);

module.exports = router;

