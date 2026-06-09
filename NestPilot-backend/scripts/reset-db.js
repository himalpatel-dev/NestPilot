#!/usr/bin/env node
/**
 * One-shot DB reset:
 *   1. Drops & recreates every table (sequelize.sync({force:true}))
 *   2. Runs modulePermissionSeeder (roles + modules + permission matrix)
 *   3. Runs Sequelize-CLI seeders (01-init-roles-admin, 02-kesharkunj-society)
 *   4. Exits.
 *
 * Usage:
 *   npm run reset-db
 */
require('dotenv').config();

const path = require('path');
const fs = require('fs');
const { Client } = require('pg');

const db = require('../src/models');
const runModulePermissionSeeder = require('../src/seeders/modulePermissionSeeder');

const SEEDERS_DIR = path.join(__dirname, '..', 'src', 'seeders');

const ensureDatabaseExists = async () => {
    const dbName = process.env.DB_NAME || 'NestPilot';
    const user = process.env.DB_USER || 'postgres';
    const password = process.env.DB_PASS || 'P8L5fE123456_';
    const host = process.env.DB_HOST || 'localhost';

    const client = new Client({ user, password, host, database: 'postgres' });
    await client.connect();
    try {
        const res = await client.query(`SELECT 1 FROM pg_database WHERE datname = $1`, [dbName]);
        if (res.rowCount === 0) {
            console.log(`Database '${dbName}' not found. Creating...`);
            await client.query(`CREATE DATABASE "${dbName}"`);
        }
    } finally {
        await client.end();
    }
};

/**
 * Load every Sequelize-CLI-style seeder in src/seeders (the ones exporting
 * { up, down }) and return them sorted by filename so 01- runs before 02-.
 * Skips files that don't expose an `up` function (e.g. modulePermissionSeeder.js).
 */
const loadCliSeeders = () => {
    const files = fs.readdirSync(SEEDERS_DIR)
        .filter(f => f.endsWith('.js'))
        .sort();

    const seeders = [];
    for (const file of files) {
        const mod = require(path.join(SEEDERS_DIR, file));
        if (mod && typeof mod.up === 'function') {
            seeders.push({ file, up: mod.up });
        }
    }
    return seeders;
};

(async () => {
    try {
        if (!process.env.JWT_SECRET) {
            console.warn('Note: JWT_SECRET is not set — fine for a reset, but the server will refuse to start without it.');
        }

        console.log('[1/4] Ensuring database exists...');
        await ensureDatabaseExists();

        console.log('[2/4] Dropping & recreating all tables (sync { force: true })...');
        await db.sequelize.sync({ force: true });
        console.log('       Schema rebuilt.');

        // Order matters: CLI seeders insert rows with hardcoded ids (roles 1-4,
        // super admin user, society, etc). modulePermissionSeeder must run AFTER
        // them — it uses findOrCreate so existing roles are kept, and it only
        // adds the modules + permission matrix on top.
        console.log('[3/4] Running Sequelize-CLI seeders...');
        const cliSeeders = loadCliSeeders();
        for (const { file, up } of cliSeeders) {
            console.log(`       -> ${file}`);
            await up(db.sequelize.getQueryInterface(), db.Sequelize);
        }

        console.log('[4/4] Running modulePermissionSeeder (modules + permission matrix)...');
        await runModulePermissionSeeder();

        console.log('\nDatabase reset complete.');
        console.log('Demo accounts available:');
        console.log('  Super Admin    : 9999999999');
        console.log('  Society Admin  : 9727376727  (Secretary, house A-1)');
        console.log('  Member         : 9727376737..9727376750');
        console.log('  Security Guard : 9000000000');
        process.exit(0);
    } catch (err) {
        console.error('\nReset failed:', err);
        process.exit(1);
    }
})();
