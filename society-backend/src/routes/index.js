const express = require('express');
const router = express.Router();

const authRoutes = require('./auth.routes');
const societyRoutes = require('./society.routes');
const adminRoutes = require('./admin.routes');
const noticeRoutes = require('./notice.routes');
const complaintRoutes = require('./complaint.routes');
const billRoutes = require('./bill.routes');
const paymentRoutes = require('./payment.routes');
const reportRoutes = require('./report.routes');


router.use('/auth', authRoutes);
router.use('/society', societyRoutes);
router.use('/admin', adminRoutes);
router.use('/notices', noticeRoutes);
router.use('/complaints', complaintRoutes);
router.use('/bills', billRoutes);
router.use('/payments', paymentRoutes);
router.use('/reports', reportRoutes);

router.get('/health', (req, res) => {
    res.status(200).send('API is running...');
});

module.exports = router;
