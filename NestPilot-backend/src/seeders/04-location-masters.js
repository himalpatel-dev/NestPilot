'use strict';

const fs = require('fs');
const path = require('path');

const DATA_FILE = path.join(__dirname, 'data', 'state_district.json');

// Optional short codes, keyed by the exact state name as it appears in the
// data file. Missing entries just fall back to null (code is nullable).
const STATE_CODES = {
    'Andaman And Nicobar Islands': 'AN',
    'Andhra Pradesh': 'AP',
    'Arunachal Pradesh': 'AR',
    'Assam': 'AS',
    'Bihar': 'BR',
    'Chandigarh': 'CH',
    'Chhattisgarh': 'CG',
    'Delhi': 'DL',
    'Goa': 'GA',
    'Gujarat': 'GJ',
    'Haryana': 'HR',
    'Himachal Pradesh': 'HP',
    'Jammu And Kashmir': 'JK',
    'Jharkhand': 'JH',
    'Karnataka': 'KA',
    'Kerala': 'KL',
    'Ladakh': 'LA',
    'Lakshadweep': 'LD',
    'Madhya Pradesh': 'MP',
    'Maharashtra': 'MH',
    'Manipur': 'MN',
    'Meghalaya': 'ML',
    'Mizoram': 'MZ',
    'Nagaland': 'NL',
    'Odisha': 'OD',
    'Puducherry': 'PY',
    'Punjab': 'PB',
    'Rajasthan': 'RJ',
    'Sikkim': 'SK',
    'Tamil Nadu': 'TN',
    'Telangana': 'TS',
    'The Dadra And Nagar Haveli And Daman And Diu': 'DN',
    'Tripura': 'TR',
    'Uttar Pradesh': 'UP',
    'Uttarakhand': 'UK',
    'West Bengal': 'WB',
};

module.exports = {
    async up(queryInterface, Sequelize) {
        const rows = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));

        // 1. Unique, alphabetically-sorted states -> stable ids (1..N)
        const stateNames = [...new Set(
            rows.map(r => (r['State Name'] || '').trim()).filter(Boolean)
        )].sort((a, b) => a.localeCompare(b));

        const stateIdByName = {};
        const states = stateNames.map((name, i) => {
            stateIdByName[name] = i + 1;
            return {
                id: i + 1,
                name,
                code: STATE_CODES[name] || null,
                is_active: true,
                created_at: new Date(),
                updated_at: new Date(),
            };
        });

        // 2. Unique (state, district) pairs, sorted -> stable ids, linked by FK
        const sortedRows = [...rows].sort((a, b) => {
            const sa = (a['State Name'] || '').trim();
            const sb = (b['State Name'] || '').trim();
            if (sa !== sb) return sa.localeCompare(sb);
            return (a['District Name'] || '').trim()
                .localeCompare((b['District Name'] || '').trim());
        });

        const seen = new Set();
        const districts = [];
        let districtId = 1;
        for (const r of sortedRows) {
            const stateName = (r['State Name'] || '').trim();
            const districtName = (r['District Name'] || '').trim();
            if (!stateName || !districtName) continue;

            const key = `${stateName}||${districtName}`;
            if (seen.has(key)) continue; // skip exact duplicates
            seen.add(key);

            districts.push({
                id: districtId++,
                state_id: stateIdByName[stateName],
                name: districtName,
                is_active: true,
                created_at: new Date(),
                updated_at: new Date(),
            });
        }

        // 3. Insert (clear first so re-runs stay clean; a no-op on a fresh reset)
        await queryInterface.bulkDelete('tbl_districts', null, {});
        await queryInterface.bulkDelete('tbl_states', null, {});
        await queryInterface.bulkInsert('tbl_states', states);
        await queryInterface.bulkInsert('tbl_districts', districts);

        // 4. Reset PostgreSQL sequences so future inserts don't collide with ids
        for (const table of ['tbl_states', 'tbl_districts']) {
            await queryInterface.sequelize.query(`
                DO $$
                DECLARE
                    seq_name text;
                BEGIN
                    seq_name := pg_get_serial_sequence('${table}', 'id');
                    IF seq_name IS NOT NULL THEN
                        EXECUTE 'SELECT setval(' || quote_literal(seq_name) || ', COALESCE((SELECT MAX(id) FROM "${table}"), 1))';
                    END IF;
                END $$;
            `);
        }

        console.log(`Seeded ${states.length} states and ${districts.length} districts.`);
    },

    async down(queryInterface) {
        await queryInterface.bulkDelete('tbl_districts', null, {});
        await queryInterface.bulkDelete('tbl_states', null, {});
    },
};
