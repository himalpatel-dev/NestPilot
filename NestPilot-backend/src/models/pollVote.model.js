const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const PollVote = sequelize.define('PollVote', {
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
        option_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'poll_options',
                key: 'id'
            }
        },
        user_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'tbl_users',
                key: 'id'
            }
        }
    }, {
        tableName: 'poll_votes',
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
    });

    PollVote.associate = (models) => {
        PollVote.belongsTo(models.Poll, { foreignKey: 'poll_id' });
        PollVote.belongsTo(models.PollOption, { foreignKey: 'option_id' });
        PollVote.belongsTo(models.User, { foreignKey: 'user_id' });
    };

    return PollVote;
};
