const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class RolePermission extends Model {
        static associate(models) {
            RolePermission.belongsTo(models.Role, { foreignKey: 'role_id' });
            RolePermission.belongsTo(models.Module, { foreignKey: 'module_id' });
        }
    }

    RolePermission.init({
        id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true
        },
        role_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: { model: 'tbl_roles', key: 'id' }
        },
        module_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: { model: 'tbl_modules', key: 'id' }
        },
        can_view: {
            type: DataTypes.BOOLEAN,
            defaultValue: false
        },
        can_create: {
            type: DataTypes.BOOLEAN,
            defaultValue: false
        },
        can_update: {
            type: DataTypes.BOOLEAN,
            defaultValue: false
        },
        can_delete: {
            type: DataTypes.BOOLEAN,
            defaultValue: false
        },
        can_approve: {
            type: DataTypes.BOOLEAN,
            defaultValue: false
        }
    }, {
        sequelize,
        modelName: 'RolePermission',
        tableName: 'tbl_role_permissions',
        underscored: true,
        indexes: [
            { unique: true, fields: ['role_id', 'module_id'] }
        ]
    });

    return RolePermission;
};
