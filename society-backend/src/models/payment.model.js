const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class Payment extends Model {
        static associate(models) {
            Payment.belongsTo(models.Society, { foreignKey: 'society_id' });
            Payment.belongsTo(models.MemberBill, { foreignKey: 'member_bill_id' });
            Payment.belongsTo(models.House, { foreignKey: 'house_id' });
            Payment.belongsTo(models.User, { foreignKey: 'user_id' });
            Payment.belongsTo(models.User, { as: 'receivedBy', foreignKey: 'received_by' });
            Payment.hasOne(models.PaymentReceipt, { foreignKey: 'payment_id' });
        }
    }

    Payment.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        society_id: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        member_bill_id: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        house_id: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        user_id: {
            type: DataTypes.INTEGER,
            allowNull: true
        },
        amount: {
            type: DataTypes.DECIMAL(10, 2),
            allowNull: false
        },
        payment_mode: {
            type: DataTypes.ENUM('CASH', 'CHEQUE', 'UPI', 'ONLINE'),
            allowNull: false
        },
        payment_date: {
            type: DataTypes.DATE,
            defaultValue: DataTypes.NOW
        },
        reference_no: {
            type: DataTypes.STRING,
            allowNull: true
        },
        note: {
            type: DataTypes.TEXT,
            allowNull: true
        },
        is_offline_entry: {
            type: DataTypes.BOOLEAN,
            defaultValue: false
        },
        client_ref_id: {
            type: DataTypes.INTEGER,
            allowNull: true,
            unique: true // For idempotency
        },
        sync_status: {
            type: DataTypes.ENUM('PENDING', 'SYNCED', 'FAILED'),
            defaultValue: 'SYNCED' // Default synced if online, else PENDING
        },
        received_by: {
            type: DataTypes.INTEGER,
            allowNull: true
        }
    }, {
        sequelize,
        modelName: 'Payment',
        tableName: 'tbl_payments',
        underscored: true,
    });
    return Payment;
};
