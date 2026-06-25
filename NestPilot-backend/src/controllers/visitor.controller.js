const db = require('../models');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');
const { Op } = require('sequelize');
const auditService = require('../services/audit.service');

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
        const { mobile, name, type, visitor_type, house_id, house_no, vehicle_number, pass_code, gate, purpose } = req.body;
        const resolvedVisitorType = visitor_type || type;

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

            let [visitor, created] = await db.Visitor.findOrCreate({
                where: { mobile, society_id: req.user.society_id },
                defaults: { name, type: resolvedVisitorType },
                transaction
            });

            // Update visitor type on existing visitor records
            if (!created && resolvedVisitorType) {
                visitor.type = resolvedVisitorType;
                await visitor.save({ transaction });
            }

            visitorLog = await db.VisitorLog.create({
                visitor_id: visitor.id,
                house_id: resolvedHouseId,
                society_id: req.user.society_id,
                entry_time: (req.body.status === 'DENIED') ? null : new Date(),
                entry_gate: gate,
                status: req.body.status || 'WAITING_APPROVAL',
                vehicle_number,
                purpose,
                approval_by_user_id: (req.body.status === 'DENIED' || req.body.status === 'INSIDE') ? req.user.id : null
            }, { transaction });
        }

        await transaction.commit();

        // --- Notification Logic Start ---
        try {
            const targetHouseId = visitorLog.house_id || resolvedHouseId;
            if (targetHouseId) {
                const mappings = await db.UserHouseMapping.findAll({
                    where: { house_id: targetHouseId, is_active: true }
                });
                const userIds = mappings.map(m => m.user_id);

                if (userIds.length > 0) {
                    const statusMsg = visitorLog.status;
                    let title = 'Visitor Update';
                    let message = `Visitor is ${statusMsg}`;

                    if (statusMsg === 'INSIDE') {
                        title = 'Visitor Arrived';
                        message = `Visitor ${name || (visitorLog.Visitor ? visitorLog.Visitor.name : 'Guest')} has entered.`;
                    } else if (statusMsg === 'WAITING_APPROVAL') {
                        title = 'New Visitor Waiting';
                        message = `Visitor ${name || 'Guest'} is waiting for your approval.`;
                    } else if (statusMsg === 'DENIED') {
                        title = 'Visitor Denied';
                        message = `Visitor ${name || 'Guest'} entry was denied.`;
                    }

                    const notifications = userIds.map(uid => ({
                        user_id: uid,
                        society_id: req.user.society_id,
                        type: 'VISITOR',
                        title: title,
                        message: message,
                        reference_id: visitorLog.id,
                        is_read: false
                    }));
                    await db.Notification.bulkCreate(notifications);

                    const io = require('../utils/socket').getIo();
                    userIds.forEach(uid => {
                        io.to(`user_${uid}`).emit('new_notification', {
                            title: title,
                            message: message,
                            type: 'VISITOR'
                        });

                        io.to(`user_${uid}`).emit('visitor_update', {
                            visitor_log: visitorLog,
                            status: statusMsg
                        });
                    });
                }
            }
        } catch (notifWarn) {
            console.error('Visitor Notification Error:', notifWarn);
        }
        // --- Notification Logic End ---

        try {
            const finalStatus = visitorLog.status;
            if (finalStatus === 'INSIDE' || finalStatus === 'DENIED') {
                let house_no = null;
                const targetHouseId = visitorLog.house_id || resolvedHouseId;
                if (targetHouseId) {
                    const house = await db.House.findByPk(targetHouseId, { attributes: ['house_no'] });
                    house_no = house ? house.house_no : null;
                }
                await auditService.logAction(
                    req.user.id,
                    req.user.society_id,
                    finalStatus === 'INSIDE' ? 'APPROVED' : 'DENIED',
                    'VISITOR_LOG',
                    String(visitorLog.id),
                    { new_value: { house_no }, ip_address: req.ip }
                );
            }
        } catch (_) {}

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
        const log = await db.VisitorLog.findByPk(visitor_log_id, {
            include: [db.Visitor]
        });
        if (!log) throw new ApiError(404, 'Log not found');

        log.exit_time = new Date();
        log.exit_gate = gate;
        log.status = 'EXITED';
        await log.save();

        // --- Notification Logic ---
        try {
            if (log.house_id) {
                const mappings = await db.UserHouseMapping.findAll({
                    where: { house_id: log.house_id, is_active: true }
                });
                const userIds = mappings.map(m => m.user_id);

                if (userIds.length > 0) {
                    const statusMsg = 'EXITED';
                    const title = 'Visitor Exited';
                    const message = `Visitor ${log.Visitor ? log.Visitor.name : 'Guest'} has exited.`;

                    const notifications = userIds.map(uid => ({
                        user_id: uid,
                        society_id: req.user.society_id,
                        type: 'VISITOR',
                        title: title,
                        message: message,
                        reference_id: log.id,
                        is_read: false
                    }));
                    await db.Notification.bulkCreate(notifications);

                    const io = require('../utils/socket').getIo();
                    userIds.forEach(uid => {
                        io.to(`user_${uid}`).emit('new_notification', {
                            title: title,
                            message: message,
                            type: 'VISITOR'
                        });

                        io.to(`user_${uid}`).emit('visitor_update', {
                            visitor_log: log,
                            status: statusMsg
                        });
                    });
                }
            }
        } catch (notifWarn) { console.error('Exit Notification Error:', notifWarn); }

        res.status(200).json(new ApiResponse(200, log, 'Exit logged'));
    } catch (e) { next(e); }
};

const getMyVisitors = async (req, res, next) => {
    try {
        const mappings = await db.UserHouseMapping.findAll({
            where: { user_id: req.user.id, is_active: true },
            attributes: ['house_id']
        });
        const houseIds = mappings.map(m => m.house_id);
        if (houseIds.length === 0) {
            return res.status(200).json(new ApiResponse(200, []));
        }

        const logs = await db.VisitorLog.findAll({
            where: { house_id: houseIds },
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

        try {
            let house_no = null;
            if (log.house_id) {
                const house = await db.House.findByPk(log.house_id, { attributes: ['house_no'] });
                house_no = house ? house.house_no : null;
            }
            await auditService.logAction(
                req.user.id,
                req.user.society_id,
                status === 'APPROVED' ? 'APPROVED' : 'DENIED',
                'VISITOR_LOG',
                String(log.id),
                { new_value: { house_no }, ip_address: req.ip }
            );
        } catch (_) {}

        res.status(200).json(new ApiResponse(200, log, `Visitor ${status}`));
    } catch (e) { next(e); }
};

const buildHouseInclude = (req, base = {}) => {
    const include = { model: db.House, ...base };
    const isSecurity = req.user && req.user.Role && req.user.Role.code === 'SECURITY_GUARD';
    if (req.userScope && !req.userScope.unscoped && !isSecurity) {
        if (!req.userScope.building_ids.length) return null;
        include.where = { ...(include.where || {}), building_id: { [Op.in]: req.userScope.building_ids } };
        include.required = true;
    }
    return include;
};

// Security: Get all visitors currently inside
const getInsideVisitors = async (req, res, next) => {
    try {
        const houseInclude = buildHouseInclude(req);
        if (houseInclude === null) return res.status(200).json(new ApiResponse(200, []));

        const logs = await db.VisitorLog.findAll({
            where: { society_id: req.user.society_id, status: 'INSIDE' },
            include: [db.Visitor, houseInclude],
            order: [['entry_time', 'DESC']]
        });
        res.status(200).json(new ApiResponse(200, logs));
    } catch (e) { next(e); }
};

// Security/Admin: Get all visitor history for the society
const getAllSocietyVisitors = async (req, res, next) => {
    try {
        const houseInclude = buildHouseInclude(req);
        if (houseInclude === null) return res.status(200).json(new ApiResponse(200, []));

        const logs = await db.VisitorLog.findAll({
            where: { society_id: req.user.society_id },
            include: [
                db.Visitor,
                houseInclude,
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

const getDashboard = async (req, res, next) => {
    try {
        const societyId = req.user.society_id;
        const qt = { type: db.sequelize.QueryTypes.SELECT };
        const isSecurity = req.user.Role && req.user.Role.code === 'SECURITY_GUARD';
        const isScoped = req.userScope && !req.userScope.unscoped && !isSecurity;

        if (isScoped && !req.userScope.building_ids.length) {
            return res.status(200).json(new ApiResponse(200, {
                stats: { inside_count: 0, pending_count: 0, today_count: 0 },
                today_visitors: [],
                history: { yesterday_count: 0, week_count: 0, month_count: 0 }
            }));
        }

        const params = { societyId };
        let bldClauseStats = '';
        let bldClauseVisitors = '';
        if (isScoped) {
            params.buildingIds = req.userScope.building_ids;
            bldClauseStats = `AND EXISTS (SELECT 1 FROM tbl_houses h WHERE h.id = visitor_logs.house_id AND h.building_id IN (:buildingIds))`;
            bldClauseVisitors = `AND h.building_id IN (:buildingIds)`;
        }

        const statsRows = await db.sequelize.query(
            `SELECT
                COUNT(CASE WHEN status = 'INSIDE' THEN 1 END) AS inside_count,
                COUNT(CASE WHEN status = 'WAITING_APPROVAL' THEN 1 END) AS pending_count,
                COUNT(CASE WHEN DATE(created_at) = CURRENT_DATE THEN 1 END) AS today_count
             FROM visitor_logs WHERE society_id = :societyId ${bldClauseStats}`,
            { replacements: params, ...qt }
        );

        const visitorsRows = await db.sequelize.query(
            `SELECT vl.id,
                v.name AS visitor_name,
                CASE WHEN h.wing IS NOT NULL AND h.wing != ''
                     THEN h.wing || '-' || h.house_no ELSE h.house_no END AS flat_no,
                vl.entry_time, vl.status
             FROM visitor_logs vl
             LEFT JOIN visitors v ON v.id = vl.visitor_id
             LEFT JOIN tbl_houses h ON h.id = vl.house_id
             WHERE vl.society_id = :societyId AND DATE(vl.created_at) = CURRENT_DATE ${bldClauseVisitors}
             ORDER BY vl.created_at DESC LIMIT 20`,
            { replacements: params, ...qt }
        );

        const historyRows = await db.sequelize.query(
            `SELECT
                COUNT(CASE WHEN DATE(created_at) = CURRENT_DATE - INTERVAL '1 day' THEN 1 END) AS yesterday_count,
                COUNT(CASE WHEN created_at >= DATE_TRUNC('week', CURRENT_DATE) THEN 1 END) AS week_count,
                COUNT(CASE WHEN created_at >= DATE_TRUNC('month', CURRENT_DATE) THEN 1 END) AS month_count
             FROM visitor_logs WHERE society_id = :societyId ${bldClauseStats}`,
            { replacements: params, ...qt }
        );

        const s = statsRows[0] || {};
        const h = historyRows[0] || {};
        res.status(200).json(new ApiResponse(200, {
            stats: {
                inside_count: parseInt(s.inside_count || 0),
                pending_count: parseInt(s.pending_count || 0),
                today_count: parseInt(s.today_count || 0)
            },
            today_visitors: visitorsRows || [],
            history: {
                yesterday_count: parseInt(h.yesterday_count || 0),
                week_count: parseInt(h.week_count || 0),
                month_count: parseInt(h.month_count || 0)
            }
        }));
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
    verifyPassCode,
    getDashboard
};
