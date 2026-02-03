const db = require('../models');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');
const { Op } = require('sequelize');

// Resident: Pre-approve a guest
const preApproveVisitor = async (req, res, next) => {
    const transaction = await db.sequelize.transaction();
    try {
        const { name, mobile, type, expected_date, purpose } = req.body;

        // 1. Find or Create Visitor Profile
        let [visitor] = await db.Visitor.findOrCreate({
            where: { mobile, society_id: req.user.society_id },
            defaults: { name, type },
            transaction
        });

        // 2. Create Log Entry
        const passCode = Math.floor(100000 + Math.random() * 900000).toString(); // 6 digit code

        // Find user's primary house
        const mapping = await db.UserHouseMapping.findOne({ where: { user_id: req.user.id, is_active: true } });
        if (!mapping) throw new ApiError(400, 'User is not assigned to any house');

        const log = await db.VisitorLog.create({
            visitor_id: visitor.id,
            house_id: mapping.house_id,
            society_id: req.user.society_id,
            status: 'PRE_APPROVED',
            pass_code: passCode,
            purpose,
            approval_by_user_id: req.user.id
        }, { transaction });

        await transaction.commit();
        res.status(201).json(new ApiResponse(201, { ...log.toJSON(), visitor }, 'Visitor pre-approved. Share code: ' + passCode));
    } catch (e) {
        await transaction.rollback();
        next(e);
    }
};

// Security: Log Entry
const logEntry = async (req, res, next) => {
    const transaction = await db.sequelize.transaction();
    try {
        const { mobile, name, type, house_id, house_no, vehicle_number, pass_code, gate } = req.body;

        let visitorLog;
        let resolvedHouseId = house_id;

        // Scenario A: Pre-approved with Code
        if (pass_code) {
            visitorLog = await db.VisitorLog.findOne({
                where: { pass_code, status: 'PRE_APPROVED' },
                include: [db.Visitor]
            });
            if (!visitorLog) throw new ApiError(404, 'Invalid or expired pass code');

            const targetStatus = req.body.status || 'INSIDE';
            visitorLog.status = targetStatus;
            visitorLog.entry_time = targetStatus === 'INSIDE' ? new Date() : null;
            visitorLog.entry_gate = gate;
            visitorLog.vehicle_number = vehicle_number;
            visitorLog.approval_by_user_id = req.user.id;
            await visitorLog.save({ transaction });
        }
        // Scenario B: Walk-in / Delivery (New Entry)
        else {
            if (!resolvedHouseId && house_no) {
                const house = await db.House.findOne({
                    where: { house_no, society_id: req.user.society_id }
                });
                if (house) resolvedHouseId = house.id;
            }

            let [visitor] = await db.Visitor.findOrCreate({
                where: { mobile, society_id: req.user.society_id },
                defaults: { name, type },
                transaction
            });

            visitorLog = await db.VisitorLog.create({
                visitor_id: visitor.id,
                house_id: resolvedHouseId,
                society_id: req.user.society_id,
                entry_time: (req.body.status === 'DENIED') ? null : new Date(),
                entry_gate: gate,
                status: req.body.status || 'WAITING_APPROVAL',
                vehicle_number,
                type: type || 'WALK_IN',
                approval_by_user_id: (req.body.status === 'DENIED' || req.body.status === 'INSIDE') ? req.user.id : null
            }, { transaction });
        }

        await transaction.commit();
        res.status(201).json(new ApiResponse(201, visitorLog, 'Visitor entry logged'));
    } catch (e) {
        await transaction.rollback();
        next(e);
    }
};

// Security: Log Exit
const logExit = async (req, res, next) => {
    try {
        const { visitor_log_id, gate } = req.body;
        const log = await db.VisitorLog.findByPk(visitor_log_id);
        if (!log) throw new ApiError(404, 'Log not found');

        log.exit_time = new Date();
        log.exit_gate = gate;
        log.status = 'EXITED';
        await log.save();

        res.status(200).json(new ApiResponse(200, log, 'Exit logged'));
    } catch (e) { next(e); }
};

const getMyVisitors = async (req, res, next) => {
    try {
        const mapping = await db.UserHouseMapping.findOne({ where: { user_id: req.user.id, is_active: true } });
        if (!mapping) throw new ApiError(400, 'No house assigned');

        const logs = await db.VisitorLog.findAll({
            where: { house_id: mapping.house_id },
            include: [db.Visitor],
            order: [['created_at', 'DESC']]
        });
        res.status(200).json(new ApiResponse(200, logs));
    } catch (e) { next(e); }
};

// Resident: Respond to Waiting Approval
const respondToVisitor = async (req, res, next) => {
    try {
        const { log_id, status } = req.body; // APPROVED or DENIED

        const log = await db.VisitorLog.findByPk(log_id);
        if (!log) throw new ApiError(404, 'Visitor log entry not found');

        log.status = status === 'APPROVED' ? 'INSIDE' : 'DENIED';
        log.approval_by_user_id = req.user.id;
        await log.save();

        res.status(200).json(new ApiResponse(200, log, `Visitor ${status}`));
    } catch (e) { next(e); }
};

// Security: Get all visitors currently inside
const getInsideVisitors = async (req, res, next) => {
    try {
        const logs = await db.VisitorLog.findAll({
            where: { society_id: req.user.society_id, status: 'INSIDE' },
            include: [db.Visitor, db.House],
            order: [['entry_time', 'DESC']]
        });
        res.status(200).json(new ApiResponse(200, logs));
    } catch (e) { next(e); }
};

// Security/Admin: Get all visitor history for the society
const getAllSocietyVisitors = async (req, res, next) => {
    try {
        const logs = await db.VisitorLog.findAll({
            where: { society_id: req.user.society_id },
            include: [
                db.Visitor,
                db.House,
                { model: db.User, as: 'approver', attributes: ['full_name'] }
            ],
            order: [['created_at', 'DESC']]
        });
        res.status(200).json(new ApiResponse(200, logs));
    } catch (e) { next(e); }
};

// Security: Just check a pass code without logging entry
const verifyPassCode = async (req, res, next) => {
    try {
        const { code } = req.params;
        const log = await db.VisitorLog.findOne({
            where: { pass_code: code, status: 'PRE_APPROVED' },
            include: [db.Visitor, db.House]
        });
        if (!log) throw new ApiError(404, 'Invalid or expired pass code');
        res.status(200).json(new ApiResponse(200, log));
    } catch (e) { next(e); }
};

module.exports = {
    preApproveVisitor,
    logEntry,
    logExit,
    getMyVisitors,
    respondToVisitor,
    getInsideVisitors,
    getAllSocietyVisitors,
    verifyPassCode
};
