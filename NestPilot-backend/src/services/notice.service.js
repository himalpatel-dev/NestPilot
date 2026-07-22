const db = require('../models');
const { Op } = require('sequelize');
const ApiError = require('../utils/ApiError');


const createNoticeSingle = async (data, files, externalTransaction) => {
    const transaction = externalTransaction || await db.sequelize.transaction();
    const ownsTx = !externalTransaction;
    try {
        const notice = await db.Notice.create(data, { transaction });

        if (files && files.length > 0) {
            const attachments = files.map(f => ({
                notice_id: notice.id,
                file_type: f.mimetype,
                file_path: f.path,
                original_name: f.originalname
            }));
            await db.NoticeAttachment.bulkCreate(attachments, { transaction });
        }

        let usersToNotify = [];
        if (data.building_id) {
            const users = await db.User.findAll({
                attributes: ['id'],
                include: [{
                    model: db.UserHouseMapping,
                    required: true,
                    include: [{
                        model: db.House,
                        attributes: [],
                        where: { building_id: data.building_id },
                        required: true
                    }]
                }],
                where: { society_id: data.society_id, status: 'active' },
                transaction
            });
            usersToNotify = users.map(u => u.id);
        } else {
            const users = await db.User.findAll({
                attributes: ['id'],
                where: { society_id: data.society_id, status: 'active' },
                transaction
            });
            usersToNotify = users.map(u => u.id);
        }

        usersToNotify = [...new Set(usersToNotify)].filter(id => id !== data.created_by);

        if (usersToNotify.length > 0) {
            const notifications = usersToNotify.map(userId => ({
                user_id: userId,
                society_id: data.society_id,
                type: 'NOTICE',
                title: 'New Notice Posted',
                message: data.title,
                reference_id: notice.id,
                is_read: false
            }));
            await db.Notification.bulkCreate(notifications, { transaction });

            try {
                const io = require('../utils/socket').getIo();
                usersToNotify.forEach(userId => {
                    io.to(`user_${userId}`).emit('new_notification', {
                        title: 'New Notice Posted',
                        message: data.title,
                        type: 'NOTICE'
                    });
                });
            } catch (socketError) {
                console.error("Socket emit failed (non-critical):", socketError);
            }
        }

        if (ownsTx) await transaction.commit();
        return notice;
    } catch (err) {
        if (ownsTx) await transaction.rollback();
        throw err;
    }
};

/**
 * Public entry. If the caller's scope restricts them to certain buildings
 * and `building_id` was not explicitly set, fan out one notice per assigned
 * building so each building gets its own copy (and only its residents see it).
 */
const createNotice = async (data, files, userScope) => {
    const explicitBuildingId = data.building_id ? Number(data.building_id) : null;
    const isUnscoped = !userScope || userScope.unscoped;

    if (isUnscoped) {
        // Super Admin: respect explicit building_id (null = society-wide)
        return createNoticeSingle(data, files);
    }

    if (!userScope.building_ids.length) {
        const err = new Error('You have no assigned buildings — cannot post a notice');
        err.statusCode = 403;
        throw err;
    }

    if (explicitBuildingId) {
        if (!userScope.building_ids.includes(explicitBuildingId)) {
            const err = new Error('Building outside your assigned buildings');
            err.statusCode = 403;
            throw err;
        }
        return createNoticeSingle(data, files);
    }

    // Fan out: one notice row per assigned building so each building's residents
    // get exactly one notice, and no resident outside scope ever sees it.
    const t = await db.sequelize.transaction();
    try {
        const created = [];
        for (const buildingId of userScope.building_ids) {
            const copy = { ...data, building_id: buildingId };
            const n = await createNoticeSingle(copy, files, t);
            created.push(n);
        }
        await t.commit();
        return created[0]; // return first for backwards compat with the controller response
    } catch (err) {
        await t.rollback();
        throw err;
    }
};

const getNotices = async (societyId, userScope) => {
    const where = { society_id: societyId, is_active: true };

    if (userScope && !userScope.unscoped) {
        if (!userScope.building_ids.length) {
            // No assigned buildings → only society-wide notices
            where.building_id = null;
        } else {
            where[Op.or] = [
                { building_id: null },
                { building_id: { [Op.in]: userScope.building_ids } }
            ];
        }
    }

    return db.Notice.findAll({
        where,
        include: [
            db.NoticeAttachment,
            { model: db.User, as: 'createdBy', attributes: ['full_name'] }
        ],
        order: [['publish_date', 'DESC']]
    });
};

/**
 * A scoped caller may only act on notices belonging to one of their assigned
 * buildings. Society-wide notices (building_id null) are visible to everyone
 * but only an unscoped caller may delete one — this mirrors createNotice,
 * which never lets a scoped caller post society-wide in the first place.
 */
const assertNoticeInScope = (notice, userScope) => {
    if (!userScope || userScope.unscoped) return;

    if (notice.building_id === null) {
        throw new ApiError(403, 'Only an administrator can delete a society-wide notice');
    }
    if (!userScope.building_ids.includes(Number(notice.building_id))) {
        throw new ApiError(403, 'Notice outside your assigned buildings');
    }
};

// Only title/description are editable — building_id and attachments already
// posted are left alone; a newly uploaded file is appended, not swapped in,
// so editing never silently drops an earlier attachment.
const updateNotice = async (noticeId, societyId, data, files, userScope) => {
    const notice = await db.Notice.findOne({
        where: { id: noticeId, society_id: societyId, is_active: true }
    });
    if (!notice) throw new ApiError(404, 'Notice not found');

    assertNoticeInScope(notice, userScope);

    await notice.update({
        title: data.title ?? notice.title,
        description: data.description ?? notice.description
    });

    if (files && files.length > 0) {
        const attachments = files.map(f => ({
            notice_id: notice.id,
            file_type: f.mimetype,
            file_path: f.path,
            original_name: f.originalname
        }));
        await db.NoticeAttachment.bulkCreate(attachments);
    }

    return notice;
};

// ── Soft-delete (deactivate) notice ───────────────────────────────────────────
// getNotices filters on is_active, so flipping the flag is what removes it from
// every list — the row and its attachments are kept for audit.
const deleteNotice = async (noticeId, societyId, userScope) => {
    const notice = await db.Notice.findOne({
        where: { id: noticeId, society_id: societyId, is_active: true }
    });
    if (!notice) throw new ApiError(404, 'Notice not found');

    assertNoticeInScope(notice, userScope);

    await notice.update({ is_active: false });
    return { message: 'Notice deleted' };
};

module.exports = {
    createNotice,
    getNotices,
    updateNotice,
    deleteNotice
};
