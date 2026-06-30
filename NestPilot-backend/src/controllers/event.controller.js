const service = require('../services/event.service');
const ApiResponse = require('../utils/ApiResponse');
const auditService = require('../services/audit.service');

const create = async (req, res, next) => {
    try {
        const data = {
            ...req.body,
            society_id: req.user.society_id,
            created_by: req.user.id,
        };
        const event = await service.createEvent(data, req.userScope);

        try {
            await auditService.logAction(
                req.user.id,
                req.user.society_id,
                'CREATED',
                'EVENT',
                String(event.id),
                { new_value: { title: event.title }, ip_address: req.ip }
            );
        } catch (_) {}

        res.status(201).json(new ApiResponse(201, event, 'Event created successfully'));
    } catch (e) { next(e); }
};

const getAll = async (req, res, next) => {
    try {
        const events = await service.getEvents(req.user.society_id);
        res.status(200).json(new ApiResponse(200, events));
    } catch (e) { next(e); }
};

const getById = async (req, res, next) => {
    try {
        const event = await service.getEventById(req.params.id, req.user.society_id, req.userScope);
        res.status(200).json(new ApiResponse(200, event));
    } catch (e) { next(e); }
};

const update = async (req, res, next) => {
    try {
        const event = await service.updateEvent(req.params.id, req.user.society_id, req.body, req.userScope);

        try {
            await auditService.logAction(
                req.user.id,
                req.user.society_id,
                'UPDATED',
                'EVENT',
                String(event.id),
                { new_value: { title: event.title }, ip_address: req.ip }
            );
        } catch (_) {}

        res.status(200).json(new ApiResponse(200, event, 'Event updated successfully'));
    } catch (e) { next(e); }
};

const remove = async (req, res, next) => {
    try {
        const result = await service.deleteEvent(req.params.id, req.user.society_id, req.userScope);

        try {
            await auditService.logAction(
                req.user.id,
                req.user.society_id,
                'CANCELLED',
                'EVENT',
                String(req.params.id),
                { ip_address: req.ip }
            );
        } catch (_) {}

        res.status(200).json(new ApiResponse(200, result));
    } catch (e) { next(e); }
};

const register = async (req, res, next) => {
    try {
        const attendee = await service.registerAttendee(
            req.params.id,
            req.user.id,
            req.user.society_id
        );
        res.status(201).json(new ApiResponse(201, attendee, 'Registered successfully'));
    } catch (e) { next(e); }
};

const cancelRegistration = async (req, res, next) => {
    try {
        const result = await service.cancelRegistration(req.params.id, req.user.id);
        res.status(200).json(new ApiResponse(200, result));
    } catch (e) { next(e); }
};

module.exports = { create, getAll, getById, update, remove, register, cancelRegistration };
