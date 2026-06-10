const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class UserBuilding extends Model {
        static associate(models) {
            UserBuilding.belongsTo(models.User, { foreignKey: 'user_id' });
            UserBuilding.belongsTo(models.Building, { foreignKey: 'building_id' });
            UserBuilding.belongsTo(models.User, { as: 'assignedBy', foreignKey: 'assigned_by' });
        }
    }

    UserBuilding.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        user_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: { model: 'tbl_users', key: 'id' }
        },
        building_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: { model: 'tbl_buildings', key: 'id' }
        },
        assigned_by: {
            type: DataTypes.INTEGER,
            allowNull: true,
            references: { model: 'tbl_users', key: 'id' }
        }
    }, {
        sequelize,
        modelName: 'UserBuilding',
        tableName: 'tbl_user_buildings',
        underscored: true,
        indexes: [
            { unique: true, fields: ['user_id', 'building_id'] },
            { fields: ['user_id'] }
        ]
    });

    return UserBuilding;
};
