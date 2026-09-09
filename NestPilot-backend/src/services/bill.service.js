const db = require('../models');
const { Op } = require('sequelize');
const ApiError = require('../utils/ApiError');

const createBill = async (data, userScope) => {
    const transaction = await db.sequelize.transaction();
    try {
        const isScoped = userScope && !userScope.unscoped;
        if (isScoped && !userScope.building_ids.length) {
            throw new ApiError(403, 'No assigned buildings — cannot create bill');
        }

        const bill = await db.Bill.create(data, { transaction });

        let houses = [];
        if (data.apply_to === 'ALL') {
            const houseWhere = { society_id: data.society_id };
            if (isScoped) houseWhere.building_id = { [Op.in]: userScope.building_ids };
            houses = await db.House.findAll({ where: houseWhere, attributes: ['id'] });
        } else if (data.selectedHouseIds && data.selectedHouseIds.length) {
            if (isScoped) {
                const inScope = await db.House.findAll({
                    where: {
                        id: { [Op.in]: data.selectedHouseIds },
                        building_id: { [Op.in]: userScope.building_ids }
                    },
                    attributes: ['id']
                });
                if (inScope.length !== data.selectedHouseIds.length) {
                    throw new ApiError(403, 'One or more selected houses are outside your assigned buildings');
                }
                houses = inScope;
            } else {
                houses = data.selectedHouseIds.map(id => ({ id }));
            }
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

// A building-scoped user (e.g. a wing secretary) may only touch bills whose
// targets all sit inside their assigned buildings. Shared by publish/update/
// delete so the three paths can never drift apart.
const assertBillInScope = async (bill, userScope) => {
    if (!userScope || userScope.unscoped) return;
    const targetHouseIds = bill.BillTargets ? bill.BillTargets.map(t => t.house_id) : [];
    if (!targetHouseIds.length) return;

    const outOfScope = await db.House.count({
        where: {
            id: { [Op.in]: targetHouseIds },
            building_id: { [Op.notIn]: userScope.building_ids }
        }
    });
    if (outOfScope > 0) throw new ApiError(403, 'Bill targets houses outside your assigned buildings');
};

const publishBill = async (billId, societyId, currentUserId, userScope) => {
    const transaction = await db.sequelize.transaction();
    try {
        const bill = await db.Bill.findOne({
            where: { id: billId, society_id: societyId },
            include: [db.BillTarget]
        });

        if (!bill) throw new ApiError(404, 'Bill not found');
        if (bill.status === 'PUBLISHED') throw new ApiError(400, 'Already published');

        await assertBillInScope(bill, userScope);

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

// Editable while the bill is still a DRAFT only. Once published, MemberBill
// rows and the "new bill" notifications are already out with the old amount
// and due date, so an edit here would silently disagree with what residents
// were told.
const EDITABLE_FIELDS = [
    'bill_type',
    'title',
    'description',
    'amount_total',
    'due_date',
    'penalty_type',
    'penalty_value'
];

const updateBill = async (billId, societyId, data, userScope) => {
    const bill = await db.Bill.findOne({
        where: { id: billId, society_id: societyId },
        include: [db.BillTarget]
    });
    if (!bill) throw new ApiError(404, 'Bill not found');
    if (bill.status !== 'DRAFT') {
        throw new ApiError(400, `Cannot edit a ${bill.status.toLowerCase()} bill`);
    }

    await assertBillInScope(bill, userScope);

    for (const field of EDITABLE_FIELDS) {
        if (data[field] !== undefined) bill[field] = data[field];
    }
    await bill.save();
    return bill;
};

// Soft-cancel only — the model already defines a CANCELLED status for this.
// A published bill can't be cancelled here since MemberBill rows and payment
// notifications already went out; unpublishing would leave those dangling.
const deleteBill = async (billId, societyId, userScope) => {
    const bill = await db.Bill.findOne({
        where: { id: billId, society_id: societyId },
        include: [db.BillTarget]
    });
    if (!bill) throw new ApiError(404, 'Bill not found');
    if (bill.status === 'PUBLISHED') throw new ApiError(400, 'Cannot delete a published bill');

    await assertBillInScope(bill, userScope);

    bill.status = 'CANCELLED';
    await bill.save();
    return { message: 'Bill deleted' };
};

const getBillsBySociety = async (societyId, userScope) => {
    const include = [];
    if (userScope && !userScope.unscoped) {
        if (!userScope.building_ids.length) return [];
        include.push({
            model: db.BillTarget,
            attributes: [],
            required: true,
            include: [{
                model: db.House,
                attributes: [],
                where: { building_id: { [Op.in]: userScope.building_ids } },
                required: true
            }]
        });
    }
    return db.Bill.findAll({
        where: { society_id: societyId },
        include,
        group: include.length ? ['Bill.id'] : undefined,
        subQuery: false,
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


const getDashboardData = async (societyId, month = null, userScope = null) => {
    const queryType = { type: db.sequelize.QueryTypes.SELECT };

    let monthClause = '';
    let buildingClausePayment = '';
    let buildingClauseMemberBill = '';
    const params = { societyId };
    const isScoped = userScope && !userScope.unscoped;

    if (isScoped) {
        if (!userScope.building_ids.length) {
            return {
                stats: { total_collected: 0, total_pending: 0, pending_bills_count: 0 },
                recent_payments: [],
                pending_by_bill: []
            };
        }
        params.buildingIds = userScope.building_ids;
        buildingClausePayment = `AND EXISTS (SELECT 1 FROM tbl_houses h2 WHERE h2.id = tbl_payments.house_id AND h2.building_id IN (:buildingIds))`;
        buildingClauseMemberBill = `AND EXISTS (SELECT 1 FROM tbl_houses h3 WHERE h3.id = mb.house_id AND h3.building_id IN (:buildingIds))`;
    }

    if (month) {
        const parts = month.split('-');
        params.year = parseInt(parts[0]);
        params.mon = parseInt(parts[1]);
        monthClause = `AND EXTRACT(YEAR FROM payment_date) = :year AND EXTRACT(MONTH FROM payment_date) = :mon`;
    }

    const collectedRows = await db.sequelize.query(
        `SELECT COALESCE(SUM(amount), 0) AS total_collected
         FROM tbl_payments
         WHERE society_id = :societyId ${monthClause} ${buildingClausePayment}`,
        { replacements: params, ...queryType }
    );

    const pendingRows = await db.sequelize.query(
        `SELECT
            COALESCE(SUM(mb.amount + mb.penalty_amount), 0) AS total_pending,
            COUNT(mb.id) AS pending_count
         FROM tbl_member_bills mb
         INNER JOIN tbl_bills b ON b.id = mb.bill_id AND b.society_id = :societyId
         WHERE mb.status IN ('PENDING', 'OVERDUE', 'PARTIAL') ${buildingClauseMemberBill}`,
        { replacements: params, ...queryType }
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
           ${isScoped ? 'AND h.building_id IN (:buildingIds)' : ''}
         ORDER BY p.payment_date DESC
         LIMIT 10`,
        { replacements: params, ...queryType }
    );

    // Bill-wise report: every member bill, paid and unpaid, carrying its parent
    // bill so the API can nest the full roster under each bill. The pending
    // totals count only unpaid rows, so they still reconcile with the headline
    // total_pending figure above.
    const memberBillRows = await db.sequelize.query(
        `SELECT
            b.id AS bill_id,
            b.title,
            b.bill_type,
            b.due_date,
            mb.user_id,
            u.full_name AS member_name,
            CASE WHEN h.wing IS NOT NULL AND h.wing != ''
                 THEN h.wing || '-' || h.house_no
                 ELSE h.house_no END AS flat_no,
            CAST(mb.amount + mb.penalty_amount AS FLOAT) AS amount,
            mb.status
         FROM tbl_member_bills mb
         INNER JOIN tbl_bills b ON b.id = mb.bill_id
         LEFT JOIN tbl_houses h ON h.id = mb.house_id
         LEFT JOIN tbl_users u ON u.id = mb.user_id
         WHERE b.society_id = :societyId ${buildingClauseMemberBill}
         ORDER BY b.due_date DESC, flat_no ASC`,
        { replacements: params, ...queryType }
    );

    const UNPAID = ['PENDING', 'OVERDUE', 'PARTIAL'];
    const billIndex = new Map();
    for (const row of memberBillRows) {
        let entry = billIndex.get(row.bill_id);
        if (!entry) {
            entry = {
                bill_id: row.bill_id,
                title: row.title,
                bill_type: row.bill_type,
                due_date: row.due_date,
                pending_count: 0,
                pending_amount: 0,
                paid_count: 0,
                paid_amount: 0,
                members: []
            };
            billIndex.set(row.bill_id, entry);
        }

        const amount = Number(row.amount) || 0;
        if (UNPAID.includes(row.status)) {
            entry.pending_count += 1;
            entry.pending_amount += amount;
        } else {
            entry.paid_count += 1;
            entry.paid_amount += amount;
        }

        entry.members.push({
            user_id: row.user_id,
            member_name: row.member_name,
            flat_no: row.flat_no,
            amount,
            status: row.status
        });
    }

    // A fully settled bill has nothing outstanding to report on.
    const pendingByBill = [...billIndex.values()].filter(b => b.pending_count > 0);

    return {
        stats: {
            total_collected: parseFloat(collectedRows[0]?.total_collected || 0),
            total_pending: parseFloat(pendingRows[0]?.total_pending || 0),
            pending_bills_count: parseInt(pendingRows[0]?.pending_count || 0)
        },
        recent_payments: recentRows || [],
        pending_by_bill: pendingByBill
    };
};

module.exports = {
    createBill,
    publishBill,
    updateBill,
    deleteBill,
    getMemberBills,
    getBillsBySociety,
    getDashboardData
};
