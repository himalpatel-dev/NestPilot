const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const StaffAttendance = sequelize.define('StaffAttendance', {
        id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true
        },
        staff_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'service_staff',
                key: 'id'
            }
        },
        date: {
            type: DataTypes.DATEONLY,
            defaultValue: DataTypes.NOW
        },
        in_time: {
            type: DataTypes.DATE,
            allowNull: true
        },
        out_time: {
            type: DataTypes.DATE,
            allowNull: true
        },
        is_present: {
            type: DataTypes.BOOLEAN,
            defaultValue: true
        }
    }, {
        tableName: 'staff_attendance',
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
    });

    StaffAttendance.associate = (models) => {
        StaffAttendance.belongsTo(models.ServiceStaff, { foreignKey: 'staff_id' });
    };

    return StaffAttendance;
};
