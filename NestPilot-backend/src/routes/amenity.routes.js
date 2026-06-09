const express = require('express');
const router = express.Router();
const controller = require('../controllers/amenity.controller');
const auth = require('../middlewares/auth.middleware');
const { hasPermission } = require('../middlewares/permission.middleware');

router.use(auth);

// Amenities
router.get('/', hasPermission('AMENITIES', 'view'), controller.getAllAmenities);
router.post('/', hasPermission('AMENITIES', 'create'), controller.createAmenity);

// Bookings — creating a booking is `create` on the AMENITIES module
router.post('/book', hasPermission('AMENITIES', 'create'), controller.createBooking);
router.get('/my-bookings', hasPermission('AMENITIES', 'view'), controller.getMyBookings);

// Admin Booking Management
router.get('/bookings', hasPermission('AMENITIES', 'view'), controller.getAllBookings);
router.put('/bookings/:id', hasPermission('AMENITIES', 'approve'), controller.updateBookingStatus);

module.exports = router;
