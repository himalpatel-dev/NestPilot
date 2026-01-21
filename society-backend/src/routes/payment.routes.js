const express = require('express');
const router = express.Router();
const controller = require('../controllers/payment.controller');
const auth = require('../middlewares/auth.middleware');
const role = require('../middlewares/role.middleware');

router.use(auth);

router.post('/offline-sync', role(['SOCIETY_ADMIN']), controller.syncOffline);
router.get('/receipts/:paymentId', controller.downloadReceipt);
router.get('/my', controller.getMyPayments);

module.exports = router;
