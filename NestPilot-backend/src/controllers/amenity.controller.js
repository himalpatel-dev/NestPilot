const db = require('../models');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');
const { Op } = require('sequelize');
const auditService = require('../services/audit.service');

const BOOKING_TYPES = ['SLOT', 'FULL_DAY', 'MEMBERSHIP'];
const LIVE_STATUS = { [Op.notIn]: ['CANCELLED', 'REJECTED'] };

// ─── Membership helpers ─────────────────────────────────────────────────────

const PLAN_UNITS = { DAY: 365, MONTH: 36, YEAR: 5 }; // unit → max duration_value
const MAX_PLANS = 10;
const MAX_START_AHEAD_DAYS = 731; // a renewal may start after a 1-year plan ends

const pad2 = (n) => String(n).padStart(2, '0');
const isoUTC = (ms) => {
    const d = new Date(ms);
    return `${d.getUTCFullYear()}-${pad2(d.getUTCMonth() + 1)}-${pad2(d.getUTCDate())}`;
};
// Today in the server's local calendar, as 'YYYY-MM-DD'.
const todayStr = () => {
    const d = new Date();
    return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
};
const addDays = (dateStr, days) => {
    const [y, m, d] = dateStr.split('-').map(Number);
    return isoUTC(Date.UTC(y, m - 1, d + days));
};
const isDateStr = (s) => typeof s === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(s)
    && isoUTC(Date.parse(`${s}T00:00:00Z`)) === s;
const prettyDate = (dateStr) => {
    const [y, m, d] = dateStr.split('-').map(Number);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return `${d} ${months[m - 1]} ${y}`;
};

/**
 * Last day (inclusive) of a membership starting on [startStr]. A month runs
 * to the day before the same date next month (16 Nov → 15 Dec); when that
 * date doesn't exist the month ends on the last day instead (31 Jan → 28 Feb).
 * The app mirrors this in AmenityPlan.endDateFor, so the dates it shows are
 * the dates saved.
 */
const membershipEnd = (startStr, value, unit) => {
    const [y, m, d] = startStr.split('-').map(Number);
    if (unit === 'DAY') return isoUTC(Date.UTC(y, m - 1, d + value - 1));

    const monthIndex = (m - 1) + (unit === 'YEAR' ? value * 12 : value);
    const ty = y + Math.floor(monthIndex / 12);
    const tm = monthIndex % 12;
    const daysInTarget = new Date(Date.UTC(ty, tm + 1, 0)).getUTCDate();
    if (d > daysInTarget) return isoUTC(Date.UTC(ty, tm, daysInTarget));
    return isoUTC(Date.UTC(ty, tm, d - 1));
};

const durationLabel = (value, unit) => {
    const word = { DAY: 'Day', MONTH: 'Month', YEAR: 'Year' }[unit];
    return `${value} ${word}${value === 1 ? '' : 's'}`;
};

/** Validates the `plans` array sent with a MEMBERSHIP amenity. */
const normalizePlans = (raw, isPaid) => {
    if (!Array.isArray(raw) || !raw.length) {
        throw new ApiError(400, 'Add at least one membership plan');
    }
    if (raw.length > MAX_PLANS) throw new ApiError(400, `At most ${MAX_PLANS} plans`);

    return raw.map((p, i) => {
        const unit = String(p?.duration_unit || '').toUpperCase();
        if (!PLAN_UNITS[unit]) throw new ApiError(400, `Plan ${i + 1}: choose days, months or years`);
        const value = Number(p.duration_value);
        if (!Number.isInteger(value) || value < 1 || value > PLAN_UNITS[unit]) {
            throw new ApiError(400, `Plan ${i + 1}: duration must be 1–${PLAN_UNITS[unit]} ${unit.toLowerCase()}s`);
        }
        const price = isPaid ? Number(p.price) : 0;
        if (!Number.isFinite(price) || price < 0 || (isPaid && price <= 0)) {
            throw new ApiError(400, `Plan ${i + 1}: enter a valid price`);
        }
        const name = String(p.name || '').trim().slice(0, 60) || durationLabel(value, unit);
        const id = Number(p.id);
        return {
            id: Number.isInteger(id) && id > 0 ? id : null,
            name,
            duration_value: value,
            duration_unit: unit,
            price,
            sort_order: i
        };
    });
};

/**
 * Makes the amenity's active plans match [plans]: rows with a known id are
 * updated, new ones created, and any left out are retired (soft-deleted —
 * past memberships keep pointing at them).
 */
const syncPlans = async (amenityId, plans, transaction) => {
    const existing = await db.AmenityPlan.findAll({
        where: { amenity_id: amenityId, is_active: true },
        transaction
    });
    const byId = new Map(existing.map(p => [p.id, p]));
    const kept = new Set();

    for (const p of plans) {
        const { id, ...fields } = p;
        const row = id ? byId.get(id) : null;
        if (row) {
            await row.update(fields, { transaction });
            kept.add(row.id);
        } else {
            await db.AmenityPlan.create({ ...fields, amenity_id: amenityId }, { transaction });
        }
    }
    for (const row of existing) {
        if (!kept.has(row.id)) await row.update({ is_active: false }, { transaction });
    }
};

const retirePlans = (amenityId, transaction) => db.AmenityPlan.update(
    { is_active: false },
    { where: { amenity_id: amenityId, is_active: true }, transaction }
);

const parseMaxMembers = (raw) => {
    if (raw === undefined) return undefined;
    if (raw === null || raw === '') return null;
    const n = Number(raw);
    if (!Number.isInteger(n) || n < 1) throw new ApiError(400, 'Member limit must be a whole number above 0');
    return n;
};

// Include / order options are built per call: Sequelize mutates them.
const activePlansInclude = () => ({
    model: db.AmenityPlan,
    as: 'plans',
    required: false,
    where: { is_active: true }
});

const planOrder = () => [
    [{ model: db.AmenityPlan, as: 'plans' }, 'sort_order', 'ASC'],
    [{ model: db.AmenityPlan, as: 'plans' }, 'id', 'ASC']
];

const loadAmenity = (id, transaction) => db.Amenity.findByPk(id, {
    include: [activePlansInclude()],
    order: planOrder(),
    transaction
});

// ─── Amenity Management (Admin) ─────────────────────────────────────────────

const createAmenity = async (req, res, next) => {
    try {
        const { plans, max_members, ...fields } = req.body;
        const bookingType = fields.booking_type || 'SLOT';
        if (!BOOKING_TYPES.includes(bookingType)) throw new ApiError(400, 'Invalid booking type');
        const isMembership = bookingType === 'MEMBERSHIP';
        const normalized = isMembership ? normalizePlans(plans, !!fields.is_paid) : null;

        const amenityId = await db.sequelize.transaction(async (transaction) => {
            const amenity = await db.Amenity.create({
                ...fields,
                booking_type: bookingType,
                max_members: isMembership ? (parseMaxMembers(max_members) ?? null) : null,
                society_id: req.user.society_id
            }, { transaction });
            if (isMembership) await syncPlans(amenity.id, normalized, transaction);
            return amenity.id;
        });
        const amenity = await loadAmenity(amenityId);

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
            where: { society_id: req.user.society_id, is_active: true },
            include: [activePlansInclude()],
            order: [['id', 'ASC'], ...planOrder()]
        });

        // How many memberships are running today, per membership amenity.
        const membershipIds = amenities.filter(a => a.booking_type === 'MEMBERSHIP').map(a => a.id);
        const activeCounts = new Map();
        if (membershipIds.length) {
            const today = todayStr();
            const rows = await db.Booking.findAll({
                attributes: ['amenity_id', [db.sequelize.fn('COUNT', db.sequelize.col('id')), 'n']],
                where: {
                    amenity_id: membershipIds,
                    plan_id: { [Op.ne]: null },
                    status: 'CONFIRMED',
                    date: { [Op.lte]: today },
                    end_date: { [Op.gte]: today }
                },
                group: ['amenity_id'],
                raw: true
            });
            rows.forEach(r => activeCounts.set(r.amenity_id, Number(r.n) || 0));
        }

        const data = amenities.map(a => {
            const json = a.toJSON();
            if (a.booking_type === 'MEMBERSHIP') json.active_members = activeCounts.get(a.id) || 0;
            return json;
        });
        res.status(200).json(new ApiResponse(200, data));
    } catch (e) { next(e); }
};

const updateAmenity = async (req, res, next) => {
    try {
        const amenity = await db.Amenity.findOne({
            where: { id: req.params.id, society_id: req.user.society_id, is_active: true }
        });
        if (!amenity) throw new ApiError(404, 'Amenity not found');

        const { name, description, image_url, is_paid, booking_type, price_per_hour, price_per_day, start_time, end_time, max_members, plans } = req.body;

        const nextType = booking_type !== undefined ? booking_type : amenity.booking_type;
        if (!BOOKING_TYPES.includes(nextType)) throw new ApiError(400, 'Invalid booking type');
        const nextPaid = is_paid !== undefined ? !!is_paid : amenity.is_paid;

        // Memberships and reservations read the same rows differently, so the
        // type can't flip to or from MEMBERSHIP while any are still running.
        const switchesMembership = nextType !== amenity.booking_type
            && (nextType === 'MEMBERSHIP' || amenity.booking_type === 'MEMBERSHIP');
        if (switchesMembership) {
            const running = await db.Booking.count({
                where: {
                    amenity_id: amenity.id,
                    status: LIVE_STATUS,
                    [Op.or]: [
                        { end_date: { [Op.gte]: todayStr() } },
                        { end_date: null, date: { [Op.gte]: todayStr() } }
                    ]
                }
            });
            if (running) {
                throw new ApiError(400, 'This amenity has active or upcoming bookings — they must end (or be cancelled) before switching to or from Membership');
            }
        }

        const isMembership = nextType === 'MEMBERSHIP';
        // Plans are required when becoming a membership amenity, optional on
        // later edits (omitted = keep the current ones).
        const normalized = isMembership && (plans !== undefined || switchesMembership)
            ? normalizePlans(plans, nextPaid)
            : null;

        await db.sequelize.transaction(async (transaction) => {
            if (name !== undefined) amenity.name = name;
            if (description !== undefined) amenity.description = description;
            if (image_url !== undefined) amenity.image_url = image_url;
            if (is_paid !== undefined) amenity.is_paid = is_paid;
            if (booking_type !== undefined) amenity.booking_type = booking_type;
            if (price_per_hour !== undefined) amenity.price_per_hour = price_per_hour;
            if (price_per_day !== undefined) amenity.price_per_day = price_per_day;
            if (start_time !== undefined) amenity.start_time = start_time;
            if (end_time !== undefined) amenity.end_time = end_time;
            if (isMembership) {
                const cap = parseMaxMembers(max_members);
                if (cap !== undefined) amenity.max_members = cap;
            } else {
                amenity.max_members = null;
            }
            await amenity.save({ transaction });

            if (normalized) await syncPlans(amenity.id, normalized, transaction);
            else if (!isMembership) await retirePlans(amenity.id, transaction);
        });

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

        res.status(200).json(new ApiResponse(200, await loadAmenity(amenity.id), 'Amenity updated successfully'));
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

// ─── Booking Management (Resident) ──────────────────────────────────────────

/**
 * A membership is a Booking over [date, end_date] for one of the amenity's
 * plans. It reserves nothing — members share the facility — so the only
 * checks are: no overlap with the resident's own memberships of this amenity,
 * and the optional member cap.
 */
const createMembership = async (req, amenity, { plan_id, date }, transaction) => {
    const plan = await db.AmenityPlan.findOne({
        where: { id: plan_id, amenity_id: amenity.id, is_active: true },
        transaction
    });
    if (!plan) throw new ApiError(400, 'Choose one of the available plans');

    const today = todayStr();
    const start = date || today;
    if (!isDateStr(start)) throw new ApiError(400, 'Invalid start date');
    if (start < today) throw new ApiError(400, "Start date can't be in the past");
    if (start > addDays(today, MAX_START_AHEAD_DAYS)) throw new ApiError(400, 'Start date is too far ahead');
    const end = membershipEnd(start, plan.duration_value, plan.duration_unit);

    const own = await db.Booking.findOne({
        where: {
            user_id: req.user.id,
            amenity_id: amenity.id,
            plan_id: { [Op.ne]: null },
            status: LIVE_STATUS,
            date: { [Op.lte]: end },
            end_date: { [Op.gte]: start }
        },
        order: [['end_date', 'DESC']],
        transaction
    });
    if (own) {
        throw new ApiError(400,
            `You already have a membership until ${prettyDate(own.end_date)} — ` +
            `start the new one from ${prettyDate(addDays(own.end_date, 1))}`);
    }

    if (amenity.max_members) {
        // Peak overlap within [start, end] happens on the range start or on
        // the start date of one of the overlapping memberships.
        const overlapping = await db.Booking.findAll({
            attributes: ['date', 'end_date'],
            where: {
                amenity_id: amenity.id,
                plan_id: { [Op.ne]: null },
                status: LIVE_STATUS,
                date: { [Op.lte]: end },
                end_date: { [Op.gte]: start }
            },
            raw: true,
            transaction
        });
        const points = [start, ...overlapping.map(b => b.date).filter(d => d > start)];
        const fullOn = points.sort().find(p =>
            overlapping.filter(b => b.date <= p && b.end_date >= p).length >= amenity.max_members);
        if (fullOn) {
            throw new ApiError(400,
                `${amenity.name} is full on ${prettyDate(fullOn)} ` +
                `(limit ${amenity.max_members} members) — try a later start date`);
        }
    }

    const price = amenity.is_paid ? Number(plan.price) : 0;
    return db.Booking.create({
        user_id: req.user.id,
        society_id: req.user.society_id,
        amenity_id: amenity.id,
        date: start,
        end_date: end,
        plan_id: plan.id,
        plan_name: plan.name,
        amount: price,
        payment_status: amenity.is_paid ? 'PENDING' : 'NOT_APPLICABLE',
        // Free memberships start right away; paid ones wait for the admin
        // to confirm the payment.
        status: amenity.is_paid ? 'PENDING' : 'CONFIRMED'
    }, { transaction });
};

const createBooking = async (req, res, next) => {
    const transaction = await db.sequelize.transaction();
    try {
        const { amenity_id, date, end_date, start_time, end_time, plan_id } = req.body;

        const amenity = await db.Amenity.findOne({
            where: { id: amenity_id, society_id: req.user.society_id, is_active: true },
            transaction
        });
        if (!amenity) throw new ApiError(404, 'Amenity not found');

        if (amenity.booking_type === 'MEMBERSHIP') {
            const membership = await createMembership(req, amenity, { plan_id, date }, transaction);
            await transaction.commit();
            return res.status(201).json(new ApiResponse(
                201,
                membership,
                amenity.is_paid ? 'Membership requested' : 'Membership activated'
            ));
        }

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
                        status: LIVE_STATUS,
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
                        status: LIVE_STATUS,
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
                        status: LIVE_STATUS,
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
            // Fixed-slot booking (courts, party room, etc.)
            if (!start_time || !end_time) throw new ApiError(400, 'start_time and end_time are required');

            const existingBooking = await db.Booking.findOne({
                where: {
                    amenity_id,
                    date,
                    status: LIVE_STATUS,
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

// ─── Booking Management (Admin) ─────────────────────────────────────────────

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
        const { status } = req.body; // CONFIRMED, REJECTED, CANCELLED
        if (!['CONFIRMED', 'REJECTED', 'CANCELLED'].includes(status)) {
            throw new ApiError(400, 'status must be CONFIRMED, REJECTED or CANCELLED');
        }
        const booking = await db.Booking.findOne({
            where: { id: req.params.id, society_id: req.user.society_id }
        });
        if (!booking) throw new ApiError(404, 'Booking not found');

        booking.status = status;
        // Approving a paid membership is the admin confirming it was paid.
        if (status === 'CONFIRMED' && booking.plan_id && Number(booking.amount) > 0) {
            booking.payment_status = 'PAID';
        }
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
    updateBookingStatus,
    // Exposed for tests / reuse.
    _membershipEnd: membershipEnd
};
