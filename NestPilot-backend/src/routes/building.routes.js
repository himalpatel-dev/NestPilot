const express = require('express');
const router = express.Router();
const societyController = require('../controllers/society.controller');
const auth = require('../middlewares/auth.middleware');
const role = require('../middlewares/role.middleware');

router.get('/:id/flats', societyController.getFlatsByBuilding);
router.post('/:id/flats', auth, role(['SUPER_ADMIN']), societyController.createFlatForBuilding);

module.exports = router;
