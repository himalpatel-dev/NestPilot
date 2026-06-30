const db = require('../models');
const { Op } = require('sequelize');
const ApiError = require('../utils/ApiError');

// ── Create event + notify members in target buildings ─────────────────────────
const createEvent = async (data, userScope) => {
    const transaction = await db.sequelize.transaction();
    try {
        const event = await db.Event.create(data, { transaction });

        let targetBuildingIds = [];
        if (userScope && !userScope.unscoped) {
            if (!userScope.building_ids.length) {
                throw new ApiError(403, 'No assigned buildings — cannot create event');
            }
            targetBuildingIds = userScope.building_ids;
            await db.EventBuilding.bulkCreate(
                targetBuildingIds.map(bid => ({ event_id: event.id, building_id: bid })),
                { transaction }
            );
        }

        let userQuery = {
            attributes: ['id'],
            where: { society_id: data.society_id, status: 'active' },
            transaction,
        };
        if (targetBuildingIds.length) {
            userQuery.include = [{
                model: db.UserHouseMapping,
                required: true,
                include: [{
                    model: db.House,
                    attributes: [],
                    where: { building_id: { [Op.in]: targetBuildingIds } },
                    required: true
                }]
            }];
        }
        const users = await db.User.findAll(userQuery);

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
    const where = { society_id: societyId, is_active: true };

    return db.Event.findAll({
        where,
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

/**
 * Returns the event ids visible to the caller, or null when unscoped (no filter).
 * Visible = no EventBuilding rows (Super-Admin society-wide) OR at least one
 * row matching the caller's assigned/owned buildings.
 */
const visibleEventIds = async (societyId, userScope) => {
    if (!userScope || userScope.unscoped) return null;
    if (!userScope.building_ids.length) {
        // Only show society-wide (untargeted) events
        const events = await db.Event.findAll({
            attributes: ['id'],
            where: { society_id: societyId },
            include: [{ model: db.EventBuilding, required: false }]
        });
        return events.filter(e => !e.EventBuildings || !e.EventBuildings.length).map(e => e.id);
    }
    const events = await db.Event.findAll({
        attributes: ['id'],
        where: { society_id: societyId },
        include: [{
            model: db.EventBuilding,
            required: false,
            where: { building_id: { [Op.in]: userScope.building_ids } }
        }]
    });
    // Now also include events with no EventBuilding rows at all (society-wide)
    const taggedIds = new Set(events.map(e => e.id));
    const allEvents = await db.Event.findAll({
        attributes: ['id'],
        where: { society_id: societyId },
        include: [{ model: db.EventBuilding, required: false, attributes: ['id'] }]
    });
    allEvents.forEach(e => {
        if (!e.EventBuildings || !e.EventBuildings.length) taggedIds.add(e.id);
    });
    return Array.from(taggedIds);
};

// ── Get single event by id ─────────────────────────────────────────────────────
const getEventById = async (eventId, societyId, userScope) => {
    if (userScope && !userScope.unscoped) {
        const visibleIds = await visibleEventIds(societyId, userScope);
        if (!visibleIds.includes(Number(eventId))) {
            throw new ApiError(404, 'Event not found');
        }
    }
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
const assertEventInScope = async (eventId, societyId, userScope) => {
    if (!userScope || userScope.unscoped) return;
    const visibleIds = await visibleEventIds(societyId, userScope);
    if (!visibleIds.includes(Number(eventId))) {
        throw new ApiError(403, 'Event outside your assigned buildings');
    }
};

const updateEvent = async (eventId, societyId, data, userScope) => {
    await assertEventInScope(eventId, societyId, userScope);
    const event = await db.Event.findOne({ where: { id: eventId, society_id: societyId } });
    if (!event) throw new ApiError(404, 'Event not found');
    await event.update(data);
    return event;
};

// ── Soft-delete (deactivate) event ─────────────────────────────────────────────
const deleteEvent = async (eventId, societyId, userScope) => {
    await assertEventInScope(eventId, societyId, userScope);
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
