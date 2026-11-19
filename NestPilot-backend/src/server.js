require('dotenv').config();
const { Client } = require('pg');
const app = require('./app');
// Import db after ensuring DB exists (though requiring it just creates the instance, doesn't connect yet)
const db = require('./models');
// Logger removed
const path = require('path');
const { execFileSync } = require('child_process');

const PORT = process.env.PORT || 5005;

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



const runDatabaseSeeders = () => {
    console.log('Running database seeders...');

    const path = require('path');
    const { execFileSync } = require('child_process');

    // Locate the installed Sequelize CLI package
    const sequelizeCliPackage = require.resolve('sequelize-cli/package.json');

    // Get the actual CLI executable
    const sequelizeCliPath = path.join(
        path.dirname(sequelizeCliPackage),
        'lib',
        'sequelize'
    );

    execFileSync(
        process.execPath,
        [sequelizeCliPath, 'db:seed:all'],
        {
            cwd: path.resolve(__dirname, '..'),
            env: {
                ...process.env,
                NODE_ENV: process.env.NODE_ENV || 'production'
            },
            stdio: 'inherit'
        }
    );

    console.log('All database seeders completed successfully.');
};


const startServer = async () => {
    try {
        // Ensure critical secrets are present before starting
        if (!process.env.JWT_SECRET) {
            console.error('FATAL: JWT_SECRET is not set in environment. Set JWT_SECRET in your .env or environment variables.');
            process.exit(1);
        }

        await ensureDatabaseExists();

        // Check if --force flag is passed to reset DB
        const forceSync = process.argv.includes('--force');
        const syncOptions = forceSync ? { force: true } : { alter: true };

        if (forceSync) {
            console.warn("WARNING: --force flag detected. Database tables will be DROPPED and RECREATED.");
        }

        const http = require('http');
        const socketUtil = require('./utils/socket'); // Import socket util

        // sync({ alter: true }) never widens an existing Postgres enum, so any
        // value added to a model enum has to be applied to the type first.
        const ensureEnumValues = require('./utils/ensureEnumValues');
        await ensureEnumValues();

        // Connect to DB and start server
        db.sequelize.sync(syncOptions) // Auto-create/update tables from models
            .then(async () => {
                console.log("Database synced successfully (Tables created/updated).");

                // Run all Sequelize CLI seeders
                runDatabaseSeeders();

                const server = http.createServer(app);
                socketUtil.init(server); // Initialize Socket.IO

                server.listen(PORT, () => {
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
