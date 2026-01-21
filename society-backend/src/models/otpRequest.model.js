const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class OtpRequest extends Model {
        static associate(models) {
            // Define associations here if needed
        }
    }

    OtpRequest.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        mobile: {
            type: DataTypes.STRING,
            allowNull: false
        },
        otp_hash: {
            type: DataTypes.STRING,
            allowNull: false
        },
        purpose: {
            type: DataTypes.ENUM('LOGIN', 'REGISTER'),
            defaultValue: 'LOGIN'
        },
        expires_at: {
            type: DataTypes.DATE,
            allowNull: false
        },
        verified_at: {
            type: DataTypes.DATE,
            allowNull: true
        },
        attempts: {
            type: DataTypes.INTEGER,
            defaultValue: 0
        }
    }, {
        sequelize,
        modelName: 'OtpRequest',
        tableName: 'otp_requests',
        underscored: true,
    });
    return OtpRequest;
};
