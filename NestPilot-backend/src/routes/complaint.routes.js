const express = require('express');
const router = express.Router();
const controller = require('../controllers/complaint.controller');
const auth = require('../middlewares/auth.middleware');
const { hasPermission } = require('../middlewares/permission.middleware');
const upload = require('../middlewares/upload.middleware');

router.use(auth);

router.post('/', hasPermission('COMPLAINTS', 'create'), upload.single('image'), controller.create);
router.get('/', hasPermission('COMPLAINTS', 'view'), controller.getAll);
router.patch('/:id/status', hasPermission('COMPLAINTS', 'update'), controller.updateStatus);
router.post('/:id/comments', hasPermission('COMPLAINTS', 'view'), controller.addComment);

module.exports = router;
