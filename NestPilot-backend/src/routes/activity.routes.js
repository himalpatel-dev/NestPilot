const express = require('express');
const router = express.Router();
const auth = require('../middlewares/auth.middleware');
const controller = require('../controllers/activity.controller');

router.use(auth);

router.get('/recent', controller.getRecent);

module.exports = router;
