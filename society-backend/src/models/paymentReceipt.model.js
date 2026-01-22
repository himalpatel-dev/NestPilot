const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class PaymentReceipt extends Model {
        static associate(models) {
            PaymentReceipt.belongsTo(models.Payment, { foreignKey: 'payment_id' });
        }
    }

    PaymentReceipt.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        payment_id: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        receipt_no: {
            type: DataTypes.STRING,
            unique: true,
            allowNull: false
        },
        receipt_pdf_path: {
            type: DataTypes.STRING,
            allowNull: true
        },
        generated_at: {
            type: DataTypes.DATE,
            defaultValue: DataTypes.NOW
        }
    }, {
        sequelize,
        modelName: 'PaymentReceipt',
        tableName: 'tbl_payment_receipts',
        underscored: true,
    });
    return PaymentReceipt;
};
