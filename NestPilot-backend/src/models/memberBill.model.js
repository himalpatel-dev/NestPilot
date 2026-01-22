const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class MemberBill extends Model {
        static associate(models) {
            MemberBill.belongsTo(models.Bill, { foreignKey: 'bill_id' });
            MemberBill.belongsTo(models.House, { foreignKey: 'house_id' });
            MemberBill.belongsTo(models.User, { foreignKey: 'user_id' }); // Can be null if house is empty
            MemberBill.hasMany(models.Payment, { foreignKey: 'member_bill_id' });
        }
    }

    MemberBill.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        bill_id: {
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
        due_date: {
            type: DataTypes.DATEONLY,
            allowNull: false
        },
        penalty_amount: {
            type: DataTypes.DECIMAL(10, 2),
            defaultValue: 0
        },
        status: {
            type: DataTypes.ENUM('PENDING', 'PARTIAL', 'PAID', 'OVERDUE'),
            defaultValue: 'PENDING'
        }
    }, {
        sequelize,
        modelName: 'MemberBill',
        tableName: 'tbl_member_bills',
        underscored: true,
    });
    return MemberBill;
};
