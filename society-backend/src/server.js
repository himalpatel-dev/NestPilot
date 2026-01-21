require('dotenv').config();
const { Client } = require('pg');
const app = require('./app');
// Import db after ensuring DB exists (though requiring it just creates the instance, doesn't connect yet)
const db = require('./models');
// Logger removed

const PORT = process.env.PORT || 5000;

const ensureDatabaseExists = async () => {
    const dbName = process.env.DB_NAME || 'NestPilot';
    const user = process.env.DB_USER || 'postgres';
    const password = process.env.DB_PASS || 'P8L5fE123456_';
    const host = process.env.DB_HOST || 'localhost';

    const client = new Client({
        user,
        password,
        host,
        database: 'postgres' // Connect to default 'postgres' database to create new DB
    });

    try {
        await client.connect();
        const res = await client.query(`SELECT 1 FROM pg_database WHERE datname = $1`, [dbName]);

        if (res.rowCount === 0) {
            console.log(`Database '${dbName}' not found. Creating...`);
            await client.query(`CREATE DATABASE "${dbName}"`);
            console.log(`Database '${dbName}' created successfully.`);
        } else {
            console.log(`Database '${dbName}' already exists. Proceeding...`);
        }
    } catch (err) {
        console.error("Critical Error during Database check/creation:", err);
        // We might choose to suppress this if the only error is "database already exists" which race conditionwise could happen, 
        // but rowCount check handles that. Connection errors to 'postgres' are fatal usually.
        throw err;
    } finally {
        await client.end();
    }
};

const startServer = async () => {
    try {
        await ensureDatabaseExists();

        // Check if --force flag is passed to reset DB
        const forceSync = process.argv.includes('--force');
        const syncOptions = forceSync ? { force: true } : { alter: true };

        if (forceSync) {
            console.warn("WARNING: --force flag detected. Database tables will be DROPPED and RECREATED.");
        }

        // Connect to DB and start server
        db.sequelize.sync(syncOptions) // Auto-create/update tables from models
            .then(() => {
                console.log("Database synced successfully (Tables created/updated).");
                app.listen(PORT, () => {
                    console.log(`Server is running on port ${PORT}`);
                });
            })
            .catch((err) => {
                console.error("Unable to connect/sync with the database:", err);
            });
    } catch (error) {
        console.error("Server failed to start:", error);
    }
};

startServer();
