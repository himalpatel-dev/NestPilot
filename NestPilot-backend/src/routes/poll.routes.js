const express = require('express');
const router = express.Router();
const controller = require('../controllers/poll.controller');
const auth = require('../middlewares/auth.middleware');
const role = require('../middlewares/role.middleware');

router.use(auth);

router.get('/', controller.getActivePolls);
router.post('/', role(['SOCIETY_ADMIN']), controller.createPoll);
router.post('/vote', controller.votePoll);
router.get('/:id/results', controller.getPollResults);

module.exports = router;
