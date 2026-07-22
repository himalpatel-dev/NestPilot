const express = require('express');
const router = express.Router();
const controller = require('../controllers/notice.controller');
const auth = require('../middlewares/auth.middleware');
const { hasPermission } = require('../middlewares/permission.middleware');
const upload = require('../middlewares/upload.middleware');

router.use(auth);

router.post('/', hasPermission('NOTICES', 'manage'), upload.array('attachments', 5), controller.create);
router.get('/', hasPermission('NOTICES', 'view'), controller.getAll);
router.put('/:id', hasPermission('NOTICES', 'manage'), upload.array('attachments', 5), controller.update);
router.delete('/:id', hasPermission('NOTICES', 'manage'), controller.remove);

module.exports = router;
