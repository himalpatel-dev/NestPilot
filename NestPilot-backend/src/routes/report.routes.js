const express = require('express');
const router = express.Router();
const auth = require('../middlewares/auth.middleware');
const { hasPermission } = require('../middlewares/permission.middleware');

router.use(auth);

router.get('/monthly-collection', hasPermission('REPORTS', 'view'), (req, res) => res.json({ msg: "Report Stub" }));
router.get('/defaulters', hasPermission('REPORTS', 'view'), (req, res) => res.json({ msg: "Report Stub" }));

module.exports = router;
