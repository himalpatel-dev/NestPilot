const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class Bill extends Model {
        static associate(models) {
            Bill.belongsTo(models.Society, { foreignKey: 'society_id' });
            Bill.belongsTo(models.User, { foreignKey: 'created_by' });
            Bill.hasMany(models.MemberBill, { foreignKey: 'bill_id' });
            Bill.hasMany(models.BillTarget, { foreignKey: 'bill_id' });
        }
    }

    Bill.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        society_id: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        created_by: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        bill_type: {
            type: DataTypes.ENUM('MAINTENANCE', 'SPECIAL'),
            allowNull: false
        },
        title: {
            type: DataTypes.STRING,
            allowNull: false
        },
        description: {
            type: DataTypes.TEXT
        },
        amount_total: {
            type: DataTypes.DECIMAL(10, 2),
            allowNull: false
        },
        due_date: {
            type: DataTypes.DATEONLY,
            allowNull: false
        },
        penalty_type: {
            type: DataTypes.ENUM('FIXED', 'PERCENT'),
            allowNull: true
        },
        penalty_value: {
            type: DataTypes.DECIMAL(10, 2),
            defaultValue: 0
        },
        apply_to: {
            type: DataTypes.ENUM('ALL', 'SELECTED'),
            defaultValue: 'ALL'
        },
        status: {
            type: DataTypes.ENUM('DRAFT', 'PUBLISHED', 'CANCELLED'),
            defaultValue: 'DRAFT'
        }
    }, {
        sequelize,
        modelName: 'Bill',
        tableName: 'bills',
        underscored: true,
    });
    return Bill;
};
