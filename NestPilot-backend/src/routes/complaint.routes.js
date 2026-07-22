const express = require('express');
const router = express.Router();
const controller = require('../controllers/complaint.controller');
const auth = require('../middlewares/auth.middleware');
const { hasPermission } = require('../middlewares/permission.middleware');
const upload = require('../middlewares/upload.middleware');

router.use(auth);

router.post('/', hasPermission('COMPLAINTS', 'manage'), upload.single('image'), controller.create);
router.get('/', hasPermission('COMPLAINTS', 'view'), controller.getAll);
router.put('/:id', hasPermission('COMPLAINTS', 'manage'), upload.single('image'), controller.update);
router.patch('/:id/status', hasPermission('COMPLAINTS', 'manage'), controller.updateStatus);
router.post('/:id/comments', hasPermission('COMPLAINTS', 'view'), controller.addComment);
router.delete('/:id', hasPermission('COMPLAINTS', 'manage'), controller.remove);

module.exports = router;
