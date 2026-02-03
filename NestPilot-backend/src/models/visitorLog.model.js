const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const VisitorLog = sequelize.define('VisitorLog', {
        id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true
        },
        visitor_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'visitors',
                key: 'id'
            }
        },
        house_id: {
            type: DataTypes.INTEGER,
            allowNull: true, // Can be null if visiting society office or general
            references: {
                model: 'tbl_houses',
                key: 'id'
            }
        },
        society_id: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        entry_time: {
            type: DataTypes.DATE,
            allowNull: true
        },
        exit_time: {
            type: DataTypes.DATE,
            allowNull: true
        },
        entry_gate: {
            type: DataTypes.STRING,
            allowNull: true
        },
        exit_gate: {
            type: DataTypes.STRING,
            allowNull: true
        },
        status: {
            type: DataTypes.STRING,
            defaultValue: 'WAITING_APPROVAL'
        },
        pass_code: {
            type: DataTypes.STRING,
            allowNull: true
        },
        vehicle_number: {
            type: DataTypes.STRING,
            allowNull: true
        },
        purpose: {
            type: DataTypes.STRING,
            allowNull: true
        },
        approval_by_user_id: {
            type: DataTypes.INTEGER,
            allowNull: true
        }
    }, {
        tableName: 'visitor_logs',
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
    });

    VisitorLog.associate = (models) => {
        VisitorLog.belongsTo(models.Visitor, { foreignKey: 'visitor_id' });
        VisitorLog.belongsTo(models.House, { foreignKey: 'house_id' });
        VisitorLog.belongsTo(models.User, { foreignKey: 'approval_by_user_id', as: 'approver' });
    };

    return VisitorLog;
};
