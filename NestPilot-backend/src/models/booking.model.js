const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const Booking = sequelize.define('Booking', {
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
        amenity_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'amenities',
                key: 'id'
            }
        },
        society_id: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        date: {
            type: DataTypes.DATEONLY, // '2023-10-25'
            allowNull: false
        },
        start_time: {
            type: DataTypes.TIME,
            allowNull: false
        },
        end_time: {
            type: DataTypes.TIME,
            allowNull: false
        },
        status: {
            type: DataTypes.ENUM('PENDING', 'CONFIRMED', 'CANCELLED', 'REJECTED'),
            defaultValue: 'PENDING'
        },
        payment_status: {
            type: DataTypes.ENUM('PENDING', 'PAID', 'NOT_APPLICABLE'),
            defaultValue: 'NOT_APPLICABLE'
        },
        amount: {
            type: DataTypes.DECIMAL(10, 2),
            defaultValue: 0.00
        }
    }, {
        tableName: 'bookings',
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
    });

    Booking.associate = (models) => {
        Booking.belongsTo(models.User, { foreignKey: 'user_id' });
        Booking.belongsTo(models.Amenity, { foreignKey: 'amenity_id' });
        Booking.belongsTo(models.Society, { foreignKey: 'society_id' });
    };

    return Booking;
};
