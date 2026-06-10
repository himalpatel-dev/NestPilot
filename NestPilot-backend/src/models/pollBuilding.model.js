const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class PollBuilding extends Model {
        static associate(models) {
            PollBuilding.belongsTo(models.Poll, { foreignKey: 'poll_id' });
            PollBuilding.belongsTo(models.Building, { foreignKey: 'building_id' });
        }
    }

    PollBuilding.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        poll_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: { model: 'polls', key: 'id' }
        },
        building_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: { model: 'tbl_buildings', key: 'id' }
        }
    }, {
        sequelize,
        modelName: 'PollBuilding',
        tableName: 'tbl_poll_buildings',
        underscored: true,
        indexes: [
            { unique: true, fields: ['poll_id', 'building_id'] },
            { fields: ['building_id'] }
        ]
    });

    return PollBuilding;
};
