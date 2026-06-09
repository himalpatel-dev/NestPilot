const express = require('express');
const router = express.Router();
const controller = require('../controllers/poll.controller');
const auth = require('../middlewares/auth.middleware');
const { hasPermission } = require('../middlewares/permission.middleware');

router.use(auth);

router.get('/', hasPermission('POLLS', 'view'), controller.getActivePolls);
router.post('/', hasPermission('POLLS', 'create'), controller.createPoll);
// Vote = ordinary member action; viewing a poll implies the right to vote.
router.post('/vote', hasPermission('POLLS', 'view'), controller.votePoll);
router.get('/:id/results', hasPermission('POLLS', 'view'), controller.getPollResults);

module.exports = router;
