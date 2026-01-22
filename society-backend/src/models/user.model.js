const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class User extends Model {
        static associate(models) {
            User.belongsTo(models.Society, { foreignKey: 'society_id' });
            User.belongsTo(models.Role, { foreignKey: 'role_id' });
            User.belongsToMany(models.House, { through: 'UserHouseMapping', foreignKey: 'user_id' });
            User.hasMany(models.UserHouseMapping, { foreignKey: 'user_id' }); // Direct access
        }
    }

    User.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        society_id: {
            type: DataTypes.INTEGER,
            allowNull: true
        },
        role_id: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        full_name: {
            type: DataTypes.STRING,
            allowNull: false
        },
        mobile: {
            type: DataTypes.STRING,
            unique: true,
            allowNull: false
        },
        email: {
            type: DataTypes.STRING,
            allowNull: true // make unique if needed
        },
        status: {
            type: DataTypes.ENUM('pending', 'active', 'rejected', 'blocked'),
            defaultValue: 'pending'
        }
    }, {
        sequelize,
        modelName: 'User',
        tableName: 'tbl_users',
        underscored: true,
    });
    return User;
};
