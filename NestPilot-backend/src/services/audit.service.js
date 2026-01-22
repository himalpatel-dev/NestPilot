const db = require('../models');

const logAction = async (userId, societyId, action, entityType, entityId, additionalData = {}) => {
    try {
        const { old_value, new_value, ip_address } = additionalData;
        await db.AuditLog.create({
            user_id: userId,
            society_id: societyId,
            action,
            entity_type: entityType,
            entity_id: entityId,
            old_value,
            new_value,
            ip_address
        });
    } catch (err) {
        console.error('Audit Log Error:', err);
        // Don't throw, just log error so main flow isn't interrupted
    }
};

module.exports = {
    logAction
};
