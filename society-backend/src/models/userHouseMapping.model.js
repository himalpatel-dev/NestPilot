const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class UserHouseMapping extends Model {
        static associate(models) {
            UserHouseMapping.belongsTo(models.User, { foreignKey: 'user_id' });
            UserHouseMapping.belongsTo(models.House, { foreignKey: 'house_id' });
        }
    }

    UserHouseMapping.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        user_id: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        house_id: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        relation_type: {
            type: DataTypes.ENUM('OWNER', 'TENANT', 'FAMILY'),
            allowNull: false
        },
        is_primary: {
            type: DataTypes.BOOLEAN,
            defaultValue: false
        },
        start_date: {
            type: DataTypes.DATE,
            defaultValue: DataTypes.NOW
        },
        end_date: {
            type: DataTypes.DATE,
            allowNull: true
        },
        is_active: {
            type: DataTypes.BOOLEAN,
            defaultValue: true
        }
    }, {
        sequelize,
        modelName: 'UserHouseMapping',
        tableName: 'tbl_user_house_mappings',
        underscored: true,
    });
    return UserHouseMapping;
};
