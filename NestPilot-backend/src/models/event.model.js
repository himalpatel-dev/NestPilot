const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class Event extends Model {
        static associate(models) {
            Event.belongsTo(models.Society, { foreignKey: 'society_id' });
            Event.belongsTo(models.User, { as: 'createdBy', foreignKey: 'created_by' });
            Event.hasMany(models.EventAttendee, { foreignKey: 'event_id', as: 'attendees' });
        }
    }

    Event.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true,
        },
        society_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
        },
        created_by: {
            type: DataTypes.INTEGER,
            allowNull: false,
        },
        title: {
            type: DataTypes.STRING,
            allowNull: false,
        },
        description: {
            type: DataTypes.TEXT,
            allowNull: true,
        },
        event_date: {
            type: DataTypes.DATEONLY,
            allowNull: false,
        },
        start_time: {
            type: DataTypes.STRING(10),
            allowNull: false,
        },
        end_time: {
            type: DataTypes.STRING(10),
            allowNull: true,
        },
        location: {
            type: DataTypes.STRING,
            allowNull: false,
        },
        event_type: {
            type: DataTypes.ENUM('MEETING', 'SOCIAL', 'CULTURAL', 'SPORTS', 'MAINTENANCE', 'OTHER'),
            defaultValue: 'OTHER',
        },
        max_attendees: {
            type: DataTypes.INTEGER,
            allowNull: true,
        },
        is_active: {
            type: DataTypes.BOOLEAN,
            defaultValue: true,
        },
    }, {
        sequelize,
        modelName: 'Event',
        tableName: 'tbl_events',
        underscored: true,
    });

    return Event;
};
