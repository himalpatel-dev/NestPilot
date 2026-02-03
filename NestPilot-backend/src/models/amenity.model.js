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
        price_per_hour: {
            type: DataTypes.DECIMAL(10, 2),
            defaultValue: 0.00
        },
        start_time: {
            type: DataTypes.TIME, // '09:00:00'
            allowNull: false
        },
        end_time: {
            type: DataTypes.TIME, // '22:00:00'
            allowNull: false
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
    };

    return Amenity;
};
