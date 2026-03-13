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
    return db.MemberBill.findAll({
        where: { user_id: userId },
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

module.exports = {
    createBill,
    publishBill,
    getMemberBills,
    getBillsBySociety
};
