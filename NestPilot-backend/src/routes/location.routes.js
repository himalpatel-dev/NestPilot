const express = require('express');
const router = express.Router();
const locationController = require('../controllers/location.controller');
const auth = require('../middlewares/auth.middleware');

// Location master reference data (State -> District).
// Feeds the cascading dropdowns on screens like Society Create.

// States
router.get('/states', auth, locationController.getStates);

// Districts — nested under a state, or filtered via ?state_id=
router.get('/states/:stateId/districts', auth, locationController.getDistricts);
router.get('/districts', auth, locationController.getDistricts);

module.exports = router;
