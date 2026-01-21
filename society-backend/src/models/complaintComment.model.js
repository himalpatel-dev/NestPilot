const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class ComplaintComment extends Model {
        static associate(models) {
            ComplaintComment.belongsTo(models.Complaint, { foreignKey: 'complaint_id' });
            ComplaintComment.belongsTo(models.User, { foreignKey: 'user_id' });
        }
    }

    ComplaintComment.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        complaint_id: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        user_id: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        message: {
            type: DataTypes.TEXT,
            allowNull: false
        }
    }, {
        sequelize,
        modelName: 'ComplaintComment',
        tableName: 'complaint_comments',
        underscored: true,
    });
    return ComplaintComment;
};
