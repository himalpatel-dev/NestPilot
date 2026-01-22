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

const publishBill = async (billId, societyId) => {
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
        for (const target of targets) {
            // Find current primary user for house
            const mapping = await db.UserHouseMapping.findOne({
                where: { house_id: target.house_id, is_active: true }
            });

            memberBills.push({
                bill_id: bill.id,
                house_id: target.house_id,
                user_id: mapping ? mapping.user_id : null,
                amount: bill.amount_total,
                due_date: bill.due_date,
                status: 'PENDING'
            });
        }

        if (memberBills.length) {
            await db.MemberBill.bulkCreate(memberBills, { transaction });
        }

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
