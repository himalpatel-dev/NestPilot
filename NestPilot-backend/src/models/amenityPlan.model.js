const { DataTypes } = require('sequelize');

/**
 * A purchasable period for a MEMBERSHIP amenity, e.g. "Monthly" = 1 MONTH
 * for ₹500. A membership itself is a Booking that snapshots the plan's name
 * and price, so editing or retiring a plan never rewrites past memberships —
 * plans are only ever soft-deleted (is_active = false).
 */
module.exports = (sequelize) => {
    const AmenityPlan = sequelize.define('AmenityPlan', {
        id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true
        },
        amenity_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'amenities',
                key: 'id'
            }
        },
        name: {
            type: DataTypes.STRING(60),
            allowNull: false
        },
        duration_value: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        // DAY | MONTH | YEAR — a plain string (validated in the controller)
        // rather than a Postgres enum, which sync can't widen later.
        duration_unit: {
            type: DataTypes.STRING(10),
            allowNull: false
        },
        price: {
            type: DataTypes.DECIMAL(10, 2),
            defaultValue: 0.00
        },
        sort_order: {
            type: DataTypes.INTEGER,
            defaultValue: 0
        },
        is_active: {
            type: DataTypes.BOOLEAN,
            defaultValue: true
        }
    }, {
        tableName: 'amenity_plans',
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
    });

    AmenityPlan.associate = (models) => {
        AmenityPlan.belongsTo(models.Amenity, { foreignKey: 'amenity_id' });
    };

    return AmenityPlan;
};
