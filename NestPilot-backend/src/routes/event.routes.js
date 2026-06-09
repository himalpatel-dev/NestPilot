const express = require('express');
const router = express.Router();
const controller = require('../controllers/event.controller');
const auth = require('../middlewares/auth.middleware');
const { hasPermission } = require('../middlewares/permission.middleware');

router.use(auth);

// List & create
router.get('/', hasPermission('EVENTS', 'view'), controller.getAll);
router.post('/', hasPermission('EVENTS', 'create'), controller.create);

// Single event
router.get('/:id', hasPermission('EVENTS', 'view'), controller.getById);
router.patch('/:id', hasPermission('EVENTS', 'update'), controller.update);
router.delete('/:id', hasPermission('EVENTS', 'delete'), controller.remove);

// Attendee registration — viewing events implies you can register for them
router.post('/:id/register', hasPermission('EVENTS', 'view'), controller.register);
router.delete('/:id/register', hasPermission('EVENTS', 'view'), controller.cancelRegistration);

module.exports = router;
