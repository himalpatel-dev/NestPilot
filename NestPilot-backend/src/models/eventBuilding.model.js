const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class EventBuilding extends Model {
        static associate(models) {
            EventBuilding.belongsTo(models.Event, { foreignKey: 'event_id' });
            EventBuilding.belongsTo(models.Building, { foreignKey: 'building_id' });
        }
    }

    EventBuilding.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        event_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: { model: 'tbl_events', key: 'id' }
        },
        building_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: { model: 'tbl_buildings', key: 'id' }
        }
    }, {
        sequelize,
        modelName: 'EventBuilding',
        tableName: 'tbl_event_buildings',
        underscored: true,
        indexes: [
            { unique: true, fields: ['event_id', 'building_id'] },
            { fields: ['building_id'] }
        ]
    });

    return EventBuilding;
};
