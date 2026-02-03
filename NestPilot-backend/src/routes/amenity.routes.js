const express = require('express');
const router = express.Router();
const controller = require('../controllers/amenity.controller');
const auth = require('../middlewares/auth.middleware');
const role = require('../middlewares/role.middleware');

router.use(auth);

// Amenities
router.get('/', controller.getAllAmenities);
router.post('/', role(['SOCIETY_ADMIN']), controller.createAmenity);

// Bookings
router.post('/book', controller.createBooking);
router.get('/my-bookings', controller.getMyBookings);

// Admin Booking Management
router.get('/bookings', role(['SOCIETY_ADMIN']), controller.getAllBookings);
router.put('/bookings/:id', role(['SOCIETY_ADMIN']), controller.updateBookingStatus);

module.exports = router;
