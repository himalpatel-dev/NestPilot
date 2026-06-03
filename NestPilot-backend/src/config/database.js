const { Sequelize } = require('sequelize');

const sequelize = new Sequelize(
    process.env.DB_NAME || 'NestPilot',
    process.env.DB_USER || 'postgres',
    process.env.DB_PASS || 'P8L5fE123456_',
    {
        host: process.env.DB_HOST || 'localhost',
        dialect: 'postgres',
        logging: false, // set to console.log to see SQL queries
    }
);

module.exports = sequelize;
