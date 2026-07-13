const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class District extends Model {
        static associate(models) {
            District.belongsTo(models.State, { foreignKey: 'state_id' });
        }
    }

    District.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        state_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'tbl_states',
                key: 'id'
            }
        },
        name: {
            type: DataTypes.STRING,
            allowNull: false
        },
        is_active: {
            type: DataTypes.BOOLEAN,
            defaultValue: true
        }
    }, {
        sequelize,
        modelName: 'District',
        tableName: 'tbl_districts',
        underscored: true,
    });
    return District;
};
