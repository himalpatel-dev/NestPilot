const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class State extends Model {
        static associate(models) {
            State.hasMany(models.District, { foreignKey: 'state_id' });
        }
    }

    State.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        name: {
            type: DataTypes.STRING,
            allowNull: false,
            unique: true
        },
        code: {
            type: DataTypes.STRING, // Short code e.g. 'GJ', 'MH'
            allowNull: true
        },
        is_active: {
            type: DataTypes.BOOLEAN,
            defaultValue: true
        }
    }, {
        sequelize,
        modelName: 'State',
        tableName: 'tbl_states',
        underscored: true,
    });
    return State;
};
