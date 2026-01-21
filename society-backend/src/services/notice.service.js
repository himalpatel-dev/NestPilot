const db = require('../models');


const createNotice = async (data, files) => {
    const transaction = await db.sequelize.transaction();
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

        await transaction.commit();



        return notice;
    } catch (err) {
        await transaction.rollback();
        throw err;
    }
};

const getNotices = async (societyId) => {
    return db.Notice.findAll({
        where: { society_id: societyId, is_active: true },
        include: [db.NoticeAttachment],
        order: [['publish_date', 'DESC']]
    });
};

module.exports = {
    createNotice,
    getNotices
};
