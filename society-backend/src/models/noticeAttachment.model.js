const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class NoticeAttachment extends Model {
        static associate(models) {
            NoticeAttachment.belongsTo(models.Notice, { foreignKey: 'notice_id' });
        }
    }

    NoticeAttachment.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        notice_id: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        file_type: {
            type: DataTypes.STRING, // image/pdf
            allowNull: false
        },
        file_path: {
            type: DataTypes.STRING,
            allowNull: false
        },
        original_name: {
            type: DataTypes.STRING,
            allowNull: true
        }
    }, {
        sequelize,
        modelName: 'NoticeAttachment',
        tableName: 'tbl_notice_attachments',
        underscored: true,
    });
    return NoticeAttachment;
};
