const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class AuditLog extends Model {
        static associate(models) {
            AuditLog.belongsTo(models.User, { foreignKey: 'user_id' });
            AuditLog.belongsTo(models.Society, { foreignKey: 'society_id' });
            AuditLog.belongsTo(models.Building, { foreignKey: 'building_id' });
        }
    }

    AuditLog.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        society_id: {
            type: DataTypes.INTEGER,
            allowNull: true
        },
        building_id: {
            type: DataTypes.INTEGER,
            allowNull: true
        },
        user_id: {
            type: DataTypes.INTEGER,
            allowNull: true
        },
        action: {
            type: DataTypes.STRING,
            allowNull: false
        },
        entity_type: {
            type: DataTypes.STRING,
            allowNull: true
        },
        entity_id: {
            type: DataTypes.STRING, // Or UUID
            allowNull: true
        },
        old_value: {
            type: DataTypes.JSONB,
            allowNull: true
        },
        new_value: {
            type: DataTypes.JSONB,
            allowNull: true
        },
        ip_address: {
            type: DataTypes.STRING,
            allowNull: true
        }
    }, {
        sequelize,
        modelName: 'AuditLog',
        tableName: 'audit_logs',
        underscored: true,
    });
    return AuditLog;
};
