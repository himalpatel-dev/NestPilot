const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const Document = sequelize.define('Document', {
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
        uploaded_by: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'tbl_users',
                key: 'id'
            }
        },
        title: {
            type: DataTypes.STRING,
            allowNull: false
        },
        category: {
            type: DataTypes.ENUM('BY_LAWS', 'MEETING_MINUTES', 'AUDIT_REPORT', 'FORM', 'OTHER'),
            defaultValue: 'OTHER'
        },
        file_url: {
            type: DataTypes.STRING,
            allowNull: false
        },
        is_private: {
            type: DataTypes.BOOLEAN,
            defaultValue: false // If true, maybe restricted to Owners only
        }
    }, {
        tableName: 'documents',
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
    });

    Document.associate = (models) => {
        Document.belongsTo(models.Society, { foreignKey: 'society_id' });
        Document.belongsTo(models.User, { foreignKey: 'uploaded_by', as: 'uploader' });
    };

    return Document;
};
