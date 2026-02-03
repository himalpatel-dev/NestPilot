const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const ServiceStaff = sequelize.define('ServiceStaff', {
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
        role: {
            type: DataTypes.ENUM('MAID', 'DRIVER', 'COOK', 'GARDENER', 'SECURITY', 'OTHER'),
            defaultValue: 'MAID'
        },
        mobile: {
            type: DataTypes.STRING,
            allowNull: false
        },
        profile_image: {
            type: DataTypes.STRING,
            allowNull: true
        },
        aadhaar_number: {
            type: DataTypes.STRING,
            allowNull: true
        },
        is_active: {
            type: DataTypes.BOOLEAN,
            defaultValue: true
        }
    }, {
        tableName: 'service_staff',
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
    });

    ServiceStaff.associate = (models) => {
        ServiceStaff.belongsTo(models.Society, { foreignKey: 'society_id' });
        ServiceStaff.hasMany(models.StaffAttendance, { foreignKey: 'staff_id' });
    };

    return ServiceStaff;
};
