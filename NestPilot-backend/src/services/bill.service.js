const db = require('../models');
const ApiError = require('../utils/ApiError');

const createBill = async (data) => {
    const transaction = await db.sequelize.transaction();
    try {
        const bill = await db.Bill.create(data, { transaction });

        // Create Bill Targets
        let houses = [];
        if (data.apply_to === 'ALL') {
            houses = await db.House.findAll({ where: { society_id: data.society_id }, attributes: ['id'] });
        } else if (data.selectedHouseIds && data.selectedHouseIds.length) {
            houses = data.selectedHouseIds.map(id => ({ id }));
        }

        if (houses.length > 0) {
            const targets = houses.map(h => ({
                bill_id: bill.id,
                house_id: h.id
            }));
            await db.BillTarget.bulkCreate(targets, { transaction });
        }

        await transaction.commit();
        return bill;
    } catch (err) {
        await transaction.rollback();
        throw err;
    }
};

const publishBill = async (billId, societyId, currentUserId) => {
    const transaction = await db.sequelize.transaction();
    try {
        const bill = await db.Bill.findOne({
            where: { id: billId, society_id: societyId },
            include: [db.BillTarget]
        });

        if (!bill) throw new ApiError(404, 'Bill not found');
        if (bill.status === 'PUBLISHED') throw new ApiError(400, 'Already published');

        bill.status = 'PUBLISHED';
        await bill.save({ transaction });

        // Generate Member Bills
        // 1. Get targets
        const targets = await db.BillTarget.findAll({ where: { bill_id: billId } });

        // 2. Prepare MemberBills
        const memberBills = [];
        let usersToNotify = [];

        for (const target of targets) {
            // Find current primary user for house
            const mapping = await db.UserHouseMapping.findOne({
                where: { house_id: target.house_id, is_active: true }
            });
            const mappedUserId = mapping ? mapping.user_id : null;

            memberBills.push({
                bill_id: bill.id,
                house_id: target.house_id,
                user_id: mappedUserId,
                amount: bill.amount_total,
                due_date: bill.due_date,
                status: 'PENDING'
            });

            if (mappedUserId && mappedUserId !== currentUserId) {
                usersToNotify.push(mappedUserId);
            }
        }

        if (memberBills.length) {
            await db.MemberBill.bulkCreate(memberBills, { transaction });
        }

        // --- Notification Logic Start ---
        usersToNotify = [...new Set(usersToNotify)]; // Unique users

        if (usersToNotify.length > 0) {
            const notifications = usersToNotify.map(userId => ({
                user_id: userId,
                society_id: societyId,
                type: 'BILL',
                title: 'New Bill Generated',
                message: `Bill of amount ${bill.amount_total} is ready for payment`,
                reference_id: bill.id,
                is_read: false
            }));
            await db.Notification.bulkCreate(notifications, { transaction });

            // Emit Socket Events (Non-transactional)
            try {
                const io = require('../utils/socket').getIo();
                usersToNotify.forEach(userId => {
                    io.to(`user_${userId}`).emit('new_notification', {
                        title: 'New Bill Generated',
                        message: `Bill of amount ${bill.amount_total} is ready for payment`,
                        type: 'BILL'
                    });
                });
            } catch (socketError) {
                console.error("Socket emit failed (non-critical):", socketError);
            }
        }
        // --- Notification Logic End ---

        await transaction.commit();
        return bill;
    } catch (err) {
        await transaction.rollback();
        throw err;
    }
};

const getBillsBySociety = async (societyId) => {
    return db.Bill.findAll({
        where: { society_id: societyId },
        order: [['created_at', 'DESC']]
    });
};

const getMemberBills = async (userId, societyId) => {
    const mappings = await db.UserHouseMapping.findAll({
        where: { user_id: userId, is_active: true },
        attributes: ['house_id']
    });
    const houseIds = mappings.map(m => m.house_id);

    if (houseIds.length === 0) {
        return [];
    }

    return db.MemberBill.findAll({
        where: { house_id: houseIds },
        include: [
            {
                model: db.Bill,
                where: { society_id: societyId },
                attributes: ['title', 'bill_type', 'penalty_type', 'penalty_value']
            },
            { model: db.House, attributes: ['house_no', 'wing'] }
        ],
        order: [['created_at', 'DESC']]
    });
};


const getDashboardData = async (societyId, month = null) => {
    const queryType = { type: db.sequelize.QueryTypes.SELECT };

    let monthClause = '';
    const params = { societyId };

    if (month) {
        const parts = month.split('-');
        params.year = parseInt(parts[0]);
        params.mon = parseInt(parts[1]);
        monthClause = `AND EXTRACT(YEAR FROM payment_date) = :year AND EXTRACT(MONTH FROM payment_date) = :mon`;
    }

    const collectedRows = await db.sequelize.query(
        `SELECT COALESCE(SUM(amount), 0) AS total_collected
         FROM tbl_payments
         WHERE society_id = :societyId ${monthClause}`,
        { replacements: params, ...queryType }
    );

    const pendingRows = await db.sequelize.query(
        `SELECT
            COALESCE(SUM(mb.amount + mb.penalty_amount), 0) AS total_pending,
            COUNT(mb.id) AS pending_count
         FROM tbl_member_bills mb
         INNER JOIN tbl_bills b ON b.id = mb.bill_id AND b.society_id = :societyId
         WHERE mb.status IN ('PENDING', 'OVERDUE', 'PARTIAL')`,
        { replacements: { societyId }, ...queryType }
    );

    const recentRows = await db.sequelize.query(
        `SELECT
            p.id,
            CAST(p.amount AS FLOAT) AS amount,
            p.payment_mode,
            p.payment_date,
            CASE WHEN h.wing IS NOT NULL AND h.wing != ''
                 THEN h.wing || '-' || h.house_no
                 ELSE h.house_no END AS flat_no,
            u.full_name AS member_name
         FROM tbl_payments p
         LEFT JOIN tbl_houses h ON h.id = p.house_id
         LEFT JOIN tbl_users u ON u.id = p.user_id
         WHERE p.society_id = :societyId ${monthClause}
         ORDER BY p.payment_date DESC
         LIMIT 10`,
        { replacements: params, ...queryType }
    );

    return {
        stats: {
            total_collected: parseFloat(collectedRows[0]?.total_collected || 0),
            total_pending: parseFloat(pendingRows[0]?.total_pending || 0),
            pending_bills_count: parseInt(pendingRows[0]?.pending_count || 0)
        },
        recent_payments: recentRows || []
    };
};

module.exports = {
    createBill,
    publishBill,
    getMemberBills,
    getBillsBySociety,
    getDashboardData
};
