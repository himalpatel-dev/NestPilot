const PDFDocument = require('pdfkit');
const fs = require('fs');
const path = require('path');
const moment = require('moment');

const generateReceipt = async (payment, society, user, house) => {
    return new Promise((resolve, reject) => {
        try {
            const doc = new PDFDocument();
            const filename = `REC-${moment().format('YYYY')}-${payment.receipt_no || payment.id.substring(0, 6)}.pdf`;
            const relativePath = `uploads/receipts/${filename}`;
            const absolutePath = path.join(__dirname, '../../', relativePath);

            const dir = path.dirname(absolutePath);
            if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

            const stream = fs.createWriteStream(absolutePath);
            doc.pipe(stream);

            // Header
            doc.fontSize(20).text(society.name, { align: 'center' });
            doc.fontSize(10).text(society.address, { align: 'center' });
            doc.moveDown();
            doc.fontSize(16).text('PAYMENT RECEIPT', { align: 'center', underline: true });
            doc.moveDown();

            // Details
            doc.fontSize(12);
            doc.text(`Receipt No: ${payment.receipt_no}`);
            doc.text(`Date: ${moment(payment.payment_date).format('DD-MM-YYYY')}`);
            doc.text(`Member: ${user ? user.full_name : 'N/A'}`);
            doc.text(`Unit: ${house ? (house.house_no + (house.wing ? ' ' + house.wing : '')) : 'N/A'}`);
            doc.moveDown();

            // Amount
            doc.text(`Amount Paid: ₹${payment.amount}`);
            doc.text(`Mode: ${payment.payment_mode}`);
            if (payment.reference_no) doc.text(`Ref No: ${payment.reference_no}`);
            doc.moveDown();

            // Footer
            doc.fontSize(10).text('Thank you for your payment.', { align: 'center' });

            doc.end();

            stream.on('finish', () => {
                resolve(relativePath);
            });
            stream.on('error', (err) => {
                reject(err);
            });

        } catch (err) {
            reject(err);
        }
    });
};

module.exports = { generateReceipt };
