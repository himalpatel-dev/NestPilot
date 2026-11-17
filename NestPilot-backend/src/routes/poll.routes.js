const express = require('express');
const router = express.Router();
const controller = require('../controllers/poll.controller');
const auth = require('../middlewares/auth.middleware');
const { hasPermission, attachPermissions } = require('../middlewares/permission.middleware');

router.use(auth);

router.get('/', hasPermission('POLLS', 'view'), controller.getActivePolls);
router.post('/', hasPermission('POLLS', 'manage'), controller.createPoll);
// Vote = ordinary member action; viewing a poll implies the right to vote.
router.post('/vote', hasPermission('POLLS', 'view'), controller.votePoll);
// attachPermissions lets the controller add voter names for POLLS managers only.
router.get('/:id/results', hasPermission('POLLS', 'view'), attachPermissions, controller.getPollResults);
router.put('/:id', hasPermission('POLLS', 'manage'), controller.updatePoll);
router.delete('/:id', hasPermission('POLLS', 'manage'), controller.deletePoll);

module.exports = router;
