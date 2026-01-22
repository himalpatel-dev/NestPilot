const express = require('express');
const router = express.Router();
const societyController = require('../controllers/society.controller');
const auth = require('../middlewares/auth.middleware');
const role = require('../middlewares/role.middleware');

// Only SOCIETY_ADMIN can manage buildings/houses
router.get('/', auth, societyController.getSociety);
router.post('/buildings', auth, role(['SOCIETY_ADMIN']), societyController.createBuilding);
router.post('/houses', auth, role(['SOCIETY_ADMIN']), societyController.createHouse);
router.get('/houses', auth, societyController.getAllHouses);

module.exports = router;
