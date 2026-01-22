const express = require('express');
const router = express.Router();
const controller = require('../controllers/notice.controller');
const auth = require('../middlewares/auth.middleware');
const role = require('../middlewares/role.middleware');
const upload = require('../middlewares/upload.middleware');

router.use(auth);

router.post('/', role(['SOCIETY_ADMIN']), upload.array('attachments', 5), controller.create);
router.get('/', controller.getAll);

module.exports = router;
