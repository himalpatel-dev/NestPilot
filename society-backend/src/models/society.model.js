const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class Society extends Model {
        static associate(models) {
            Society.hasMany(models.Building, { foreignKey: 'society_id' });
            Society.hasMany(models.House, { foreignKey: 'society_id' });
            Society.hasMany(models.User, { foreignKey: 'society_id' });
            Society.hasMany(models.Notice, { foreignKey: 'society_id' });
            Society.hasMany(models.Complaint, { foreignKey: 'society_id' });
            Society.hasMany(models.Bill, { foreignKey: 'society_id' });
            Society.hasMany(models.Payment, { foreignKey: 'society_id' });
            Society.hasMany(models.AuditLog, { foreignKey: 'society_id' });
        }
    }

    Society.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        name: {
            type: DataTypes.STRING,
            allowNull: false
        },
        society_type: {
            type: DataTypes.ENUM('APARTMENT', 'TENEMENT', 'ROW_HOUSE', 'COMMERCIAL', 'MIXED'),
            defaultValue: 'APARTMENT' // Default to standard apartment
        },
        address: {
            type: DataTypes.TEXT,
            allowNull: false
        },
        city: {
            type: DataTypes.STRING,
            allowNull: false
        },
        state: {
            type: DataTypes.STRING,
            allowNull: false
        },
        pincode: {
            type: DataTypes.STRING,
            allowNull: false
        },
        status: {
            type: DataTypes.STRING,
            defaultValue: 'active'
        }
    }, {
        sequelize,
        modelName: 'Society',
        tableName: 'societies',
        underscored: true,
    });
    return Society;
};
