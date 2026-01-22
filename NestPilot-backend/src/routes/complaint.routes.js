const express = require('express');
const router = express.Router();
const controller = require('../controllers/complaint.controller');
const auth = require('../middlewares/auth.middleware');
const role = require('../middlewares/role.middleware');
const upload = require('../middlewares/upload.middleware');

router.use(auth);

router.post('/', role(['MEMBER']), upload.single('image'), controller.create);
router.get('/', controller.getAll);
router.patch('/:id/status', role(['SOCIETY_ADMIN']), controller.updateStatus);
router.post('/:id/comments', controller.addComment);

module.exports = router;
