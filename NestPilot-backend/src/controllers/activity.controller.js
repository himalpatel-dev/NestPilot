const db = require('../models');
const ApiResponse = require('../utils/ApiResponse');

const ENTITY_LABEL = {
    VISITOR_LOG: 'Visitor',
    VISITOR: 'Visitor',
    BILL: 'Maintenance bill',
    COMPLAINT: 'Complaint',
    NOTICE: 'Notice',
    AMENITY_BOOKING: 'Amenity booking',
    POLL: 'Poll',
    STAFF: 'Staff',
    VEHICLE: 'Vehicle'
};

const ACTION_VERB = {
    APPROVED: 'approved',
    DENIED: 'denied',
    CREATED: 'created',
    PUBLISHED: 'published',
    GENERATED: 'generated',
    RESOLVED: 'resolved',
    CLOSED: 'closed',
    REOPENED: 'reopened',
    IN_PROGRESS: 'in progress',
    ENTERED: 'entered',
    EXITED: 'exited',
    UPDATED: 'updated'
};

const buildMessage = (log) => {
    const entityLabel = ENTITY_LABEL[log.entity_type] || (log.entity_type ? log.entity_type.toLowerCase() : 'Item');
    const verb = ACTION_VERB[log.action] || log.action.toLowerCase().replace(/_/g, ' ');
    const meta = log.new_value || {};

    // Prefer the explicit message captured at log time
    if (meta.message) return meta.message;

    // House/flat reference like "Flat 101"
    let refSuffix = '';
    if (meta.house_no) {
        refSuffix = ` for Flat ${meta.house_no}`;
    } else if (meta.title) {
        refSuffix = `: ${meta.title}`;
    } else if (meta.ref_code) {
        refSuffix = ` #${meta.ref_code}`;
    }

    return `${entityLabel} ${verb}${refSuffix}`;
};

const getRecent = async (req, res, next) => {
    try {
        const limit = Math.min(parseInt(req.query.limit, 10) || 10, 50);

        const logs = await db.AuditLog.findAll({
            where: { society_id: req.user.society_id },
            include: [{ model: db.User, attributes: ['id', 'full_name'] }],
            order: [['created_at', 'DESC']],
            limit
        });

        const data = logs.map(log => ({
            id: log.id,
            action: log.action,
            entity_type: log.entity_type,
            entity_id: log.entity_id,
            message: buildMessage(log),
            actor: log.User ? log.User.full_name : null,
            created_at: log.createdAt || log.created_at || log.get('created_at')
        }));

        res.status(200).json(new ApiResponse(200, data));
    } catch (e) { next(e); }
};

module.exports = { getRecent };
