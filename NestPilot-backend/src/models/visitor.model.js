const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const Visitor = sequelize.define('Visitor', {
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
        name: {
            type: DataTypes.STRING,
            allowNull: false
        },
        mobile: {
            type: DataTypes.STRING,
            allowNull: false
        },
        profile_image: {
            type: DataTypes.STRING,
            allowNull: true
        },
        type: {
            type: DataTypes.STRING,
            defaultValue: 'GUEST'
        },
        frequent_visitor: {
            type: DataTypes.BOOLEAN,
            defaultValue: false
        }
    }, {
        tableName: 'visitors',
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
    });

    Visitor.associate = (models) => {
        Visitor.belongsTo(models.Society, { foreignKey: 'society_id' });
        Visitor.hasMany(models.VisitorLog, { foreignKey: 'visitor_id' });
    };

    return Visitor;
};
