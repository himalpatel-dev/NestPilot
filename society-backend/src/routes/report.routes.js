const express = require('express');
const router = express.Router();
const auth = require('../middlewares/auth.middleware');

router.use(auth);

router.get('/monthly-collection', (req, res) => res.json({ msg: "Report Stub" }));
router.get('/defaulters', (req, res) => res.json({ msg: "Report Stub" }));

module.exports = router;
