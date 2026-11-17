const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const Amenity = sequelize.define('Amenity', {
        id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true
        },
        society_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'tbl_societies',
                key: 'id'
            }
        },
        name: {
            type: DataTypes.STRING,
            allowNull: false
        },
        description: {
            type: DataTypes.TEXT,
            allowNull: true
        },
        image_url: {
            type: DataTypes.STRING,
            allowNull: true
        },
        is_paid: {
            type: DataTypes.BOOLEAN,
            defaultValue: false
        },
        // SLOT = fixed hourly slots within a daily window (courts, party room)
        // FULL_DAY = booked for whole date(s) as needed (banquet hall, common plot)
        // MEMBERSHIP = shared facility used on a pass for a period (gym, pool):
        //   residents buy one of the amenity's plans; no slot is reserved.
        // A new value here must also be listed in utils/ensureEnumValues.js.
        booking_type: {
            type: DataTypes.ENUM('SLOT', 'FULL_DAY', 'MEMBERSHIP'),
            defaultValue: 'SLOT',
            allowNull: false
        },
        // MEMBERSHIP only: most memberships that may overlap on any one day.
        // null = unlimited.
        max_members: {
            type: DataTypes.INTEGER,
            allowNull: true
        },
        price_per_hour: {
            type: DataTypes.DECIMAL(10, 2),
            defaultValue: 0.00
        },
        price_per_day: {
            type: DataTypes.DECIMAL(10, 2),
            defaultValue: 0.00
        },
        start_time: {
            type: DataTypes.TIME, // '09:00:00' — SLOT booking window; MEMBERSHIP opening hours (display only)
            allowNull: true
        },
        end_time: {
            type: DataTypes.TIME, // '22:00:00' — SLOT booking window; MEMBERSHIP opening hours (display only)
            allowNull: true
        },
        is_active: {
            type: DataTypes.BOOLEAN,
            defaultValue: true
        }
    }, {
        tableName: 'amenities',
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
    });

    Amenity.associate = (models) => {
        Amenity.belongsTo(models.Society, { foreignKey: 'society_id' });
        Amenity.hasMany(models.Booking, { foreignKey: 'amenity_id' });
        Amenity.hasMany(models.AmenityPlan, { foreignKey: 'amenity_id', as: 'plans' });
    };

    return Amenity;
};
