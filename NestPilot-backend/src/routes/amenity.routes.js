const express = require('express');
const router = express.Router();
const controller = require('../controllers/amenity.controller');
const auth = require('../middlewares/auth.middleware');
const { hasPermission } = require('../middlewares/permission.middleware');

router.use(auth);

// Amenities
router.get('/', hasPermission('AMENITIES', 'view'), controller.getAllAmenities);
router.post('/', hasPermission('AMENITIES', 'manage'), controller.createAmenity);
router.put('/:id', hasPermission('AMENITIES', 'manage'), controller.updateAmenity);
router.delete('/:id', hasPermission('AMENITIES', 'manage'), controller.deleteAmenity);

// Bookings — any resident who can see the amenities can request one. `manage`
// stays the admin side: it gates approving/rejecting those requests, and paid
// bookings are created PENDING regardless, so nothing is auto-granted here.
router.post('/book', hasPermission('AMENITIES', 'view'), controller.createBooking);
router.get('/my-bookings', hasPermission('AMENITIES', 'view'), controller.getMyBookings);

// Admin Booking Management — society-wide bookings carry every resident's name
// and mobile, so this is `manage`, not `view`.
router.get('/bookings', hasPermission('AMENITIES', 'manage'), controller.getAllBookings);
router.put('/bookings/:id', hasPermission('AMENITIES', 'manage'), controller.updateBookingStatus);

module.exports = router;
