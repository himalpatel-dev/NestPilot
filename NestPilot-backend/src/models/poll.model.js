const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const Poll = sequelize.define('Poll', {
        id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true
        },
        society_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'tbl_societies',
                key: 'id'
            }
        },
        created_by: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'tbl_users',
                key: 'id'
            }
        },
        question: {
            type: DataTypes.STRING,
            allowNull: false
        },
        description: {
            type: DataTypes.TEXT,
            allowNull: true
        },
        end_date: {
            type: DataTypes.DATE,
            allowNull: false
        },
        is_active: {
            type: DataTypes.BOOLEAN,
            defaultValue: true
        }
    }, {
        tableName: 'polls',
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
    });

    Poll.associate = (models) => {
        Poll.belongsTo(models.Society, { foreignKey: 'society_id' });
        Poll.belongsTo(models.User, { foreignKey: 'created_by', as: 'creator' });
        Poll.hasMany(models.PollOption, { foreignKey: 'poll_id', as: 'options' });
        Poll.hasMany(models.PollVote, { foreignKey: 'poll_id', as: 'votes' });
    };

    return Poll;
};
