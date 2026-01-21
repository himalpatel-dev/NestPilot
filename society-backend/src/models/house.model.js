const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class House extends Model {
        static associate(models) {
            House.belongsTo(models.Society, { foreignKey: 'society_id' });
            House.belongsTo(models.Building, { foreignKey: 'building_id' }); // Represents Building, Block, or Lane
            House.belongsToMany(models.User, { through: 'UserHouseMapping', foreignKey: 'house_id' });
            House.hasMany(models.UserHouseMapping, { foreignKey: 'house_id' });
        }
    }

    // "House" is the generic term for any Unit (Apartment, Row House, Villa, Shop)
    House.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        society_id: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        building_id: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        unit_type: {
            type: DataTypes.ENUM('FLAT', 'ROW_HOUSE', 'VILLA', 'SHOP', 'OFFICE'),
            defaultValue: 'FLAT'
        },
        wing: {
            type: DataTypes.STRING
        },
        floor_no: {
            type: DataTypes.INTEGER,
            defaultValue: 0
        },
        house_no: {
            type: DataTypes.STRING,
            allowNull: false
        },
        house_type: {
            type: DataTypes.STRING
        },
        area_sqft: {
            type: DataTypes.DECIMAL(10, 2)
        },
        is_active: {
            type: DataTypes.BOOLEAN,
            defaultValue: true
        }
    }, {
        sequelize,
        modelName: 'House',
        tableName: 'houses',
        underscored: true,
    });
    return House;
};
