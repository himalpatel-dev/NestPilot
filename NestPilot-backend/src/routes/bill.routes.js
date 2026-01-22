const express = require('express');
const router = express.Router();
const controller = require('../controllers/bill.controller');
const auth = require('../middlewares/auth.middleware');
const role = require('../middlewares/role.middleware');

router.use(auth);

// Admin Bill Mgmt
router.post('/', role(['SOCIETY_ADMIN']), controller.create);
router.get('/', role(['SOCIETY_ADMIN']), controller.getAll);
router.get('/user/:userId', role(['SOCIETY_ADMIN']), controller.getUserBills);
router.post('/:id/publish', role(['SOCIETY_ADMIN']), controller.publish);

// Member Bills
router.get('/my', controller.getMyBills);

module.exports = router;
