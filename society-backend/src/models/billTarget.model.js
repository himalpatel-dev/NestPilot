const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class BillTarget extends Model {
        static associate(models) {
            BillTarget.belongsTo(models.Bill, { foreignKey: 'bill_id' });
            BillTarget.belongsTo(models.House, { foreignKey: 'house_id' });
        }
    }

    BillTarget.init({
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
        }
    }, {
        sequelize,
        modelName: 'BillTarget',
        tableName: 'bill_targets',
        underscored: true,
    });
    return BillTarget;
};
