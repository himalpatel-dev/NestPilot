const express = require('express');
const router = express.Router();
const controller = require('../controllers/notice.controller');
const auth = require('../middlewares/auth.middleware');
const { hasPermission } = require('../middlewares/permission.middleware');
const upload = require('../middlewares/upload.middleware');

router.use(auth);

router.post('/', hasPermission('NOTICES', 'create'), upload.array('attachments', 5), controller.create);
router.get('/', hasPermission('NOTICES', 'view'), controller.getAll);

module.exports = router;
