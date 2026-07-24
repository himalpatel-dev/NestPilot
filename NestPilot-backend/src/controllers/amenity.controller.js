const db = require('../models');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');
const { Op } = require('sequelize');
const auditService = require('../services/audit.service');

// --- Amenity Management (Admin) ---

const createAmenity = async (req, res, next) => {
    try {
        const data = { ...req.body, society_id: req.user.society_id };
        const amenity = await db.Amenity.create(data);

        try {
            await auditService.logAction(
                req.user.id,
                req.user.society_id,
                'CREATED',
                'AMENITY',
                String(amenity.id),
                { new_value: { title: amenity.name }, ip_address: req.ip }
            );
        } catch (_) {}

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

const updateAmenity = async (req, res, next) => {
    try {
        const amenity = await db.Amenity.findOne({
            where: { id: req.params.id, society_id: req.user.society_id, is_active: true }
        });
        if (!amenity) throw new ApiError(404, 'Amenity not found');

        const { name, description, image_url, is_paid, booking_type, price_per_hour, price_per_day, start_time, end_time } = req.body;
        if (name !== undefined) amenity.name = name;
        if (description !== undefined) amenity.description = description;
        if (image_url !== undefined) amenity.image_url = image_url;
        if (is_paid !== undefined) amenity.is_paid = is_paid;
        if (booking_type !== undefined) amenity.booking_type = booking_type;
        if (price_per_hour !== undefined) amenity.price_per_hour = price_per_hour;
        if (price_per_day !== undefined) amenity.price_per_day = price_per_day;
        if (start_time !== undefined) amenity.start_time = start_time;
        if (end_time !== undefined) amenity.end_time = end_time;
        await amenity.save();

        try {
            await auditService.logAction(
                req.user.id,
                req.user.society_id,
                'UPDATED',
                'AMENITY',
                String(amenity.id),
                { new_value: { title: amenity.name }, ip_address: req.ip }
            );
        } catch (_) {}

        res.status(200).json(new ApiResponse(200, amenity, 'Amenity updated successfully'));
    } catch (e) { next(e); }
};

// Soft delete — existing bookings are left intact.
const deleteAmenity = async (req, res, next) => {
    try {
        const amenity = await db.Amenity.findOne({
            where: { id: req.params.id, society_id: req.user.society_id, is_active: true }
        });
        if (!amenity) throw new ApiError(404, 'Amenity not found');

        amenity.is_active = false;
        await amenity.save();

        try {
            await auditService.logAction(
                req.user.id,
                req.user.society_id,
                'DELETED',
                'AMENITY',
                String(amenity.id),
                { ip_address: req.ip }
            );
        } catch (_) {}

        res.status(200).json(new ApiResponse(200, null, 'Amenity deleted'));
    } catch (e) { next(e); }
};

// --- Booking Management (Resident) ---

const createBooking = async (req, res, next) => {
    const transaction = await db.sequelize.transaction();
    try {
        const { amenity_id, date, end_date, start_time, end_time } = req.body;

        const amenity = await db.Amenity.findByPk(amenity_id);
        if (!amenity) throw new ApiError(404, 'Amenity not found');

        const bookingData = {
            user_id: req.user.id,
            society_id: req.user.society_id,
            amenity_id,
            date
        };
        let amount = 0;

        if (amenity.booking_type === 'FULL_DAY') {
            // Hall / plot style — either the whole date(s), or just a few hours on one date.
            const isHourly = !!(start_time && end_time);

            if (isHourly) {
                // Block if the date is already covered by a whole-day booking.
                const wholeDayConflict = await db.Booking.findOne({
                    where: {
                        amenity_id,
                        status: { [Op.notIn]: ['CANCELLED', 'REJECTED'] },
                        start_time: null,
                        date: { [Op.lte]: date },
                        end_date: { [Op.gte]: date }
                    }
                });
                if (wholeDayConflict) throw new ApiError(400, 'Already booked for the whole day on this date');

                // Block if another hourly booking overlaps the requested time on this date.
                const hourlyConflict = await db.Booking.findOne({
                    where: {
                        amenity_id,
                        date,
                        status: { [Op.notIn]: ['CANCELLED', 'REJECTED'] },
                        start_time: { [Op.ne]: null },
                        [Op.or]: [
                            {
                                start_time: { [Op.lt]: end_time },
                                end_time: { [Op.gt]: start_time }
                            }
                        ]
                    }
                });
                if (hourlyConflict) throw new ApiError(400, 'Slot already booked');

                if (amenity.is_paid) {
                    const start = new Date(`1970-01-01T${start_time}Z`);
                    const end = new Date(`1970-01-01T${end_time}Z`);
                    const hours = (end - start) / 36e5;
                    amount = hours * amenity.price_per_hour;
                }

                bookingData.start_time = start_time;
                bookingData.end_time = end_time;
            } else {
                const rangeEnd = end_date || date;
                if (new Date(rangeEnd) < new Date(date)) {
                    throw new ApiError(400, 'End date cannot be before start date');
                }

                // Block if any booking (whole-day or hourly) falls within the requested range.
                const existingBooking = await db.Booking.findOne({
                    where: {
                        amenity_id,
                        status: { [Op.notIn]: ['CANCELLED', 'REJECTED'] },
                        date: { [Op.lte]: rangeEnd },
                        [Op.or]: [
                            { end_date: { [Op.gte]: date } },
                            { end_date: null, date: { [Op.gte]: date } }
                        ]
                    }
                });
                if (existingBooking) throw new ApiError(400, 'Already booked for the selected date(s)');

                const days = Math.round((new Date(rangeEnd) - new Date(date)) / 86400000) + 1;
                if (amenity.is_paid) amount = days * amenity.price_per_day;

                bookingData.end_date = rangeEnd;
            }
        } else {
            // Fixed-slot booking (gym, yoga, courts, etc.)
            if (!start_time || !end_time) throw new ApiError(400, 'start_time and end_time are required');

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

            if (amenity.is_paid) {
                const start = new Date(`1970-01-01T${start_time}Z`);
                const end = new Date(`1970-01-01T${end_time}Z`);
                const hours = (end - start) / 36e5;
                amount = hours * amenity.price_per_hour;
            }

            bookingData.start_time = start_time;
            bookingData.end_time = end_time;
        }

        bookingData.amount = amount;
        bookingData.payment_status = amenity.is_paid ? 'PENDING' : 'NOT_APPLICABLE';
        bookingData.status = amenity.is_paid ? 'PENDING' : 'CONFIRMED'; // Auto-confirm free bookings

        const booking = await db.Booking.create(bookingData, { transaction });

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
    updateAmenity,
    deleteAmenity,
    createBooking,
    getMyBookings,
    getAllBookings,
    updateBookingStatus
};
