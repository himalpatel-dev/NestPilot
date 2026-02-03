const db = require('../models');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');
const { Op } = require('sequelize');

// --- Amenity Management (Admin) ---

const createAmenity = async (req, res, next) => {
    try {
        const data = { ...req.body, society_id: req.user.society_id };
        const amenity = await db.Amenity.create(data);
        res.status(201).json(new ApiResponse(201, amenity, 'Amenity created successfully'));
    } catch (e) { next(e); }
};

const getAllAmenities = async (req, res, next) => {
    try {
        const amenities = await db.Amenity.findAll({
            where: { society_id: req.user.society_id, is_active: true }
        });
        res.status(200).json(new ApiResponse(200, amenities));
    } catch (e) { next(e); }
};

// --- Booking Management (Resident) ---

const createBooking = async (req, res, next) => {
    const transaction = await db.sequelize.transaction();
    try {
        const { amenity_id, date, start_time, end_time } = req.body;

        const amenity = await db.Amenity.findByPk(amenity_id);
        if (!amenity) throw new ApiError(404, 'Amenity not found');

        // Check availability (Basic overlap check)
        const existingBooking = await db.Booking.findOne({
            where: {
                amenity_id,
                date,
                status: { [Op.notIn]: ['CANCELLED', 'REJECTED'] },
                [Op.or]: [
                    {
                        start_time: { [Op.lt]: end_time },
                        end_time: { [Op.gt]: start_time }
                    }
                ]
            }
        });

        if (existingBooking) throw new ApiError(400, 'Slot already booked');

        // Calculate Cost
        let amount = 0;
        let payment_status = 'NOT_APPLICABLE';

        if (amenity.is_paid) {
            // Simple logic: assume hourly blocks for now or flat rate. 
            // For MVP, let's just take price_per_hour * duration
            const start = new Date(`1970-01-01T${start_time}Z`);
            const end = new Date(`1970-01-01T${end_time}Z`);
            const hours = (end - start) / 36e5;
            amount = hours * amenity.price_per_hour;
            payment_status = 'PENDING';
        }

        const booking = await db.Booking.create({
            user_id: req.user.id,
            society_id: req.user.society_id,
            amenity_id,
            date,
            start_time,
            end_time,
            amount,
            payment_status,
            status: amenity.is_paid ? 'PENDING' : 'CONFIRMED' // Auto-confirm free bookings
        }, { transaction });

        await transaction.commit();
        res.status(201).json(new ApiResponse(201, booking, 'Booking request created'));
    } catch (e) {
        await transaction.rollback();
        next(e);
    }
};

const getMyBookings = async (req, res, next) => {
    try {
        const bookings = await db.Booking.findAll({
            where: { user_id: req.user.id },
            include: [db.Amenity],
            order: [['date', 'DESC'], ['start_time', 'DESC']]
        });
        res.status(200).json(new ApiResponse(200, bookings));
    } catch (e) { next(e); }
};

// --- Booking Management (Admin) ---

const getAllBookings = async (req, res, next) => {
    try {
        const bookings = await db.Booking.findAll({
            where: { society_id: req.user.society_id },
            include: [
                { model: db.User, attributes: ['full_name', 'mobile'] },
                { model: db.Amenity }
            ],
            order: [['date', 'DESC']]
        });
        res.status(200).json(new ApiResponse(200, bookings));
    } catch (e) { next(e); }
};

const updateBookingStatus = async (req, res, next) => {
    try {
        const { status } = req.body; // CONFIRMED, REJECTED
        const booking = await db.Booking.findByPk(req.params.id);
        if (!booking) throw new ApiError(404, 'Booking not found');

        booking.status = status;
        await booking.save();

        // TODO: Send notification to user

        res.status(200).json(new ApiResponse(200, booking, `Booking ${status}`));
    } catch (e) { next(e); }
};

module.exports = {
    createAmenity,
    getAllAmenities,
    createBooking,
    getMyBookings,
    getAllBookings,
    updateBookingStatus
};
