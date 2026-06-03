const express = require('express');
const router = express.Router();
const controller = require('../controllers/event.controller');
const auth = require('../middlewares/auth.middleware');
const role = require('../middlewares/role.middleware');

router.use(auth);

// List & create
router.get('/', controller.getAll);
router.post('/', role(['SOCIETY_ADMIN']), controller.create);

// Single event
router.get('/:id', controller.getById);
router.patch('/:id', role(['SOCIETY_ADMIN']), controller.update);
router.delete('/:id', role(['SOCIETY_ADMIN']), controller.remove);

// Attendee registration
router.post('/:id/register', controller.register);
router.delete('/:id/register', controller.cancelRegistration);

module.exports = router;
