const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class Notice extends Model {
        static associate(models) {
            Notice.belongsTo(models.Society, { foreignKey: 'society_id' });
            Notice.belongsTo(models.Building, { foreignKey: 'building_id' }); // Optional: building specific
            Notice.belongsTo(models.User, { as: 'createdBy', foreignKey: 'created_by' });
            Notice.hasMany(models.NoticeAttachment, { foreignKey: 'notice_id' });
        }
    }

    Notice.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        society_id: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        building_id: {
            type: DataTypes.INTEGER,
            allowNull: true // Null means "All Buildings" / Society-wide
        },
        created_by: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        title: {
            type: DataTypes.STRING,
            allowNull: false
        },
        description: {
            type: DataTypes.TEXT,
            allowNull: false
        },
        publish_date: {
            type: DataTypes.DATE,
            defaultValue: DataTypes.NOW
        },
        expiry_date: {
            type: DataTypes.DATE,
            allowNull: true
        },
        is_active: {
            type: DataTypes.BOOLEAN,
            defaultValue: true
        }
    }, {
        sequelize,
        modelName: 'Notice',
        tableName: 'notices',
        underscored: true,
    });
    return Notice;
};
