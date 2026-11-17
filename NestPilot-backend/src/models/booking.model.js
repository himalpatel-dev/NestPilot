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
            type: DataTypes.DATEONLY, // '2023-10-25' — start date for FULL_DAY bookings
            allowNull: false
        },
        // FULL_DAY bookings only: last date covered (inclusive). Equals `date` for a single-day booking.
        end_date: {
            type: DataTypes.DATEONLY,
            allowNull: true
        },
        start_time: {
            type: DataTypes.TIME, // SLOT bookings only
            allowNull: true
        },
        end_time: {
            type: DataTypes.TIME, // SLOT bookings only
            allowNull: true
        },
        // MEMBERSHIP bookings only: the plan bought, with its name kept as a
        // snapshot so renaming/retiring the plan never rewrites history.
        // `date`..`end_date` is the validity period; amount is the plan price.
        plan_id: {
            type: DataTypes.INTEGER,
            allowNull: true,
            references: {
                model: 'amenity_plans',
                key: 'id'
            }
        },
        plan_name: {
            type: DataTypes.STRING(60),
            allowNull: true
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
        Booking.belongsTo(models.AmenityPlan, { foreignKey: 'plan_id' });
    };

    return Booking;
};
