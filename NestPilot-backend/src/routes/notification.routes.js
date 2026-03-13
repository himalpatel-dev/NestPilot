const express = require('express');
const router = express.Router();
const controller = require('../controllers/notification.controller');
const auth = require('../middlewares/auth.middleware');

router.get('/', auth, controller.getNotifications);
router.put('/:id/read', auth, controller.markAsRead);

module.exports = router;
