const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class Building extends Model {
        static associate(models) {
            Building.belongsTo(models.Society, { foreignKey: 'society_id' });
            Building.hasMany(models.House, { foreignKey: 'building_id' });
        }
    }

    Building.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        society_id: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        name: {
            type: DataTypes.STRING,
            allowNull: false
        },
        blocks: {
            type: DataTypes.STRING
        },
        wings: {
            type: DataTypes.STRING
        },
        floors_count: {
            type: DataTypes.INTEGER,
            defaultValue: 0
        }
    }, {
        sequelize,
        modelName: 'Building',
        tableName: 'tbl_buildings',
        underscored: true,
    });
    return Building;
};
