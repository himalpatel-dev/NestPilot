const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const Vehicle = sequelize.define('Vehicle', {
        id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true
        },
        user_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'tbl_users',
                key: 'id'
            }
        },
        society_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'tbl_societies',
                key: 'id'
            }
        },
        type: {
            type: DataTypes.ENUM('CAR', 'BIKE', 'OTHER'),
            defaultValue: 'CAR'
        },
        vehicle_number: {
            type: DataTypes.STRING,
            allowNull: false
        },
        brand: {
            type: DataTypes.STRING,
            allowNull: true
        },
        model: {
            type: DataTypes.STRING,
            allowNull: true
        },
        sticker_number: {
            type: DataTypes.STRING,
            allowNull: true
        },
        is_active: {
            type: DataTypes.BOOLEAN,
            defaultValue: true
        }
    }, {
        tableName: 'vehicles',
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
    });

    Vehicle.associate = (models) => {
        Vehicle.belongsTo(models.User, { foreignKey: 'user_id', as: 'owner' });
        Vehicle.belongsTo(models.Society, { foreignKey: 'society_id' });
    };

    return Vehicle;
};
