const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class EventAttendee extends Model {
        static associate(models) {
            EventAttendee.belongsTo(models.Event, { foreignKey: 'event_id' });
            EventAttendee.belongsTo(models.User, { foreignKey: 'user_id', as: 'user' });
        }
    }

    EventAttendee.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true,
        },
        event_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
        },
        user_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
        },
        status: {
            type: DataTypes.ENUM('REGISTERED', 'CANCELLED', 'ATTENDED'),
            defaultValue: 'REGISTERED',
        },
    }, {
        sequelize,
        modelName: 'EventAttendee',
        tableName: 'tbl_event_attendees',
        underscored: true,
        indexes: [
            { unique: true, fields: ['event_id', 'user_id'] },
        ],
    });

    return EventAttendee;
};
