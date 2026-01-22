const db = require('../models');
const { v4: uuidv4 } = require('uuid');
const receiptGenerator = require('../utils/receiptGenerator');

const syncOfflinePayments = async (paymentsData, receivedByUserId, societyId) => {
    const results = [];
    let syncedCount = 0;
    let failedCount = 0;

    for (const p of paymentsData) {
        const transaction = await db.sequelize.transaction();
        try {
            // 1. Check Idempotency
            const existing = await db.Payment.findOne({ where: { client_ref_id: p.clientRefId } });
            if (existing) {
                results.push({ clientRefId: p.clientRefId, status: 'EXISTS', paymentId: existing.id });
                await transaction.rollback();
                continue;
            }

            // 2. Validate Bill
            const memberBill = await db.MemberBill.findOne({ where: { id: p.memberBillId } });
            if (!memberBill) throw new Error(`Bill ${p.memberBillId} not found`);

            // 3. Create Payment
            const payment = await db.Payment.create({
                society_id: societyId,
                member_bill_id: p.memberBillId,
                house_id: memberBill.house_id,
                user_id: memberBill.user_id,
                amount: p.amount,
                payment_mode: p.paymentMode,
                payment_date: p.paymentDate,
                reference_no: p.referenceNo,
                note: p.note,
                is_offline_entry: true,
                client_ref_id: p.clientRefId,
                sync_status: 'SYNCED',
                received_by: receivedByUserId
            }, { transaction });

            // 4. Update MemberBill
            const allPayments = await db.Payment.findAll({ where: { member_bill_id: memberBill.id }, transaction });
            const total = allPayments.reduce((acc, curr) => acc + Number(curr.amount), 0) + Number(p.amount);

            const billTotal = Number(memberBill.amount) + Number(memberBill.penalty_amount);
            if (total >= billTotal) memberBill.status = 'PAID';
            else if (total > 0) memberBill.status = 'PARTIAL';
            await memberBill.save({ transaction });

            // 5. Generate Receipt
            const society = await db.Society.findByPk(societyId, { transaction });
            const user = await db.User.findByPk(memberBill.user_id, { transaction });
            const house = await db.House.findByPk(memberBill.house_id, { transaction });

            const receiptNo = `REC-${Date.now()}-${uuidv4().substring(0, 4)}`;
            const pdfPath = await receiptGenerator.generateReceipt({ ...payment.dataValues, receipt_no: receiptNo }, society, user, house);

            await db.PaymentReceipt.create({
                payment_id: payment.id,
                receipt_no: receiptNo,
                receipt_pdf_path: pdfPath
            }, { transaction });

            await transaction.commit();
            syncedCount++;
            results.push({ clientRefId: p.clientRefId, status: 'SUCCESS', paymentId: payment.id, receiptUrl: pdfPath });

        } catch (error) {
            await transaction.rollback();
            failedCount++;
            results.push({ clientRefId: p.clientRefId, status: 'FAILED', error: error.message });
        }
    }

    return { syncedCount, failedCount, results };
};

const getReceipt = async (paymentId) => {
    return db.PaymentReceipt.findOne({ where: { payment_id: paymentId } });
};

module.exports = {
    syncOfflinePayments,
    getReceipt
};
