const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const PollOption = sequelize.define('PollOption', {
        id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true
        },
        poll_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'polls',
                key: 'id'
            }
        },
        option_text: {
            type: DataTypes.STRING,
            allowNull: false
        }
    }, {
        tableName: 'poll_options',
        timestamps: false
    });

    PollOption.associate = (models) => {
        PollOption.belongsTo(models.Poll, { foreignKey: 'poll_id' });
        PollOption.hasMany(models.PollVote, { foreignKey: 'option_id' });
    };

    return PollOption;
};
