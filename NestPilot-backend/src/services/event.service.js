const db = require('../models');
const ApiError = require('../utils/ApiError');

// ── Create event + notify all society members ─────────────────────────────────
const createEvent = async (data) => {
    const transaction = await db.sequelize.transaction();
    try {
        const event = await db.Event.create(data, { transaction });

        // Notify all active members of the society (except creator)
        const users = await db.User.findAll({
            attributes: ['id'],
            where: { society_id: data.society_id, status: 'active' },
            transaction,
        });

        const usersToNotify = [...new Set(
            users.map(u => u.id).filter(id => id !== data.created_by)
        )];

        if (usersToNotify.length > 0) {
            const notifications = usersToNotify.map(userId => ({
                user_id: userId,
                society_id: data.society_id,
                type: 'EVENT',
                title: 'New Event Posted',
                message: data.title,
                reference_id: event.id,
                is_read: false,
            }));
            await db.Notification.bulkCreate(notifications, { transaction });

            try {
                const io = require('../utils/socket').getIo();
                usersToNotify.forEach(userId => {
                    io.to(`user_${userId}`).emit('new_notification', {
                        title: 'New Event Posted',
                        message: data.title,
                        type: 'EVENT',
                    });
                });
            } catch (socketErr) {
                console.error('Socket emit failed (non-critical):', socketErr);
            }
        }

        await transaction.commit();
        return event;
    } catch (err) {
        await transaction.rollback();
        throw err;
    }
};

// ── Get all upcoming/active events for a society ──────────────────────────────
const getEvents = async (societyId) => {
    return db.Event.findAll({
        where: { society_id: societyId, is_active: true },
        include: [
            {
                model: db.User,
                as: 'createdBy',
                attributes: ['id', 'full_name'],
            },
            {
                model: db.EventAttendee,
                as: 'attendees',
                attributes: ['id', 'user_id', 'status'],
                include: [
                    {
                        model: db.User,
                        as: 'user',
                        attributes: ['id', 'full_name', 'mobile'],
                    },
                ],
            },
        ],
        order: [['event_date', 'ASC'], ['start_time', 'ASC']],
    });
};

// ── Get single event by id ─────────────────────────────────────────────────────
const getEventById = async (eventId, societyId) => {
    const event = await db.Event.findOne({
        where: { id: eventId, society_id: societyId, is_active: true },
        include: [
            {
                model: db.User,
                as: 'createdBy',
                attributes: ['id', 'full_name'],
            },
            {
                model: db.EventAttendee,
                as: 'attendees',
                attributes: ['id', 'user_id', 'status'],
                include: [
                    {
                        model: db.User,
                        as: 'user',
                        attributes: ['id', 'full_name', 'mobile'],
                    },
                ],
            },
        ],
    });
    if (!event) throw new ApiError(404, 'Event not found');
    return event;
};

// ── Update event ───────────────────────────────────────────────────────────────
const updateEvent = async (eventId, societyId, data) => {
    const event = await db.Event.findOne({ where: { id: eventId, society_id: societyId } });
    if (!event) throw new ApiError(404, 'Event not found');
    await event.update(data);
    return event;
};

// ── Soft-delete (deactivate) event ─────────────────────────────────────────────
const deleteEvent = async (eventId, societyId) => {
    const event = await db.Event.findOne({ where: { id: eventId, society_id: societyId } });
    if (!event) throw new ApiError(404, 'Event not found');
    await event.update({ is_active: false });
    return { message: 'Event cancelled' };
};

// ── Register current user for an event ────────────────────────────────────────
const registerAttendee = async (eventId, userId, societyId) => {
    const event = await db.Event.findOne({ where: { id: eventId, society_id: societyId, is_active: true } });
    if (!event) throw new ApiError(404, 'Event not found');

    // Check capacity
    if (event.max_attendees) {
        const count = await db.EventAttendee.count({
            where: { event_id: eventId, status: 'REGISTERED' },
        });
        if (count >= event.max_attendees) throw new ApiError(400, 'Event is fully booked');
    }

    const [attendee, created] = await db.EventAttendee.findOrCreate({
        where: { event_id: eventId, user_id: userId },
        defaults: { status: 'REGISTERED' },
    });

    if (!created && attendee.status === 'CANCELLED') {
        await attendee.update({ status: 'REGISTERED' });
    } else if (!created) {
        throw new ApiError(400, 'You are already registered for this event');
    }

    return attendee;
};

// ── Cancel registration ────────────────────────────────────────────────────────
const cancelRegistration = async (eventId, userId) => {
    const attendee = await db.EventAttendee.findOne({ where: { event_id: eventId, user_id: userId } });
    if (!attendee) throw new ApiError(404, 'Registration not found');
    await attendee.update({ status: 'CANCELLED' });
    return { message: 'Registration cancelled' };
};

module.exports = {
    createEvent,
    getEvents,
    getEventById,
    updateEvent,
    deleteEvent,
    registerAttendee,
    cancelRegistration,
};
