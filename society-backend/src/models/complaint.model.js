const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class Complaint extends Model {
        static associate(models) {
            Complaint.belongsTo(models.Society, { foreignKey: 'society_id' });
            Complaint.belongsTo(models.House, { foreignKey: 'house_id' });
            Complaint.belongsTo(models.User, { as: 'createdBy', foreignKey: 'created_by' });
            Complaint.hasMany(models.ComplaintComment, { foreignKey: 'complaint_id' });
        }
    }

    Complaint.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        society_id: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        house_id: {
            type: DataTypes.INTEGER,
            allowNull: true
        },
        created_by: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        category: {
            type: DataTypes.STRING,
            allowNull: false
        },
        description: {
            type: DataTypes.TEXT,
            allowNull: false
        },
        image_path: {
            type: DataTypes.STRING,
            allowNull: true
        },
        priority: {
            type: DataTypes.ENUM('LOW', 'MEDIUM', 'HIGH'),
            defaultValue: 'MEDIUM'
        },
        status: {
            type: DataTypes.ENUM('OPEN', 'IN_PROGRESS', 'RESOLVED', 'REJECTED'),
            defaultValue: 'OPEN'
        }
    }, {
        sequelize,
        modelName: 'Complaint',
        tableName: 'tbl_complaints',
        underscored: true,
    });
    return Complaint;
};
