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
const vehiclesRoutes = require('./vehicle.routes');
const visitorsRoutes = require('./visitor.routes');
const amenitiesRoutes = require('./amenity.routes');
const staffRoutes = require('./staff.routes');
const pollsRoutes = require('./poll.routes');
const documentsRoutes = require('./document.routes');



router.use('/auth', authRoutes);
router.use('/society', societyRoutes);
router.use('/admin', adminRoutes);
router.use('/notices', noticeRoutes);
router.use('/complaints', complaintRoutes);
router.use('/bills', billRoutes);
router.use('/payments', paymentRoutes);
router.use('/reports', reportRoutes);
router.use('/vehicles', vehiclesRoutes);
router.use('/visitors', visitorsRoutes);
router.use('/amenities', amenitiesRoutes);
router.use('/staff', staffRoutes);
router.use('/polls', pollsRoutes);
router.use('/documents', documentsRoutes);

router.get('/health', (req, res) => {
    res.status(200).send('API is running...');
});

module.exports = router;
