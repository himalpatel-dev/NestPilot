const db = require('../models');

/**
 * Postgres ENUM types can gain values, but sequelize's sync({ alter: true })
 * does not add them — so widening an enum in a model silently keeps failing at
 * insert time with "invalid input value for enum". Anything we widen is listed
 * here and reconciled against the database before sync runs.
 *
 * Type names follow sequelize's convention: enum_<table>_<column>.
 */
const ENUM_VALUES = {
    enum_tbl_bills_bill_type: ['MAINTENANCE', 'SPECIAL', 'UTILITY', 'EVENT', 'OTHER']
};

const ensureEnumValues = async () => {
    for (const [typeName, values] of Object.entries(ENUM_VALUES)) {
        const existing = await db.sequelize.query(
            `SELECT e.enumlabel AS label
               FROM pg_enum e
               JOIN pg_type t ON t.oid = e.enumtypid
              WHERE t.typname = :typeName`,
            { replacements: { typeName }, type: db.sequelize.QueryTypes.SELECT }
        );

        // Type doesn't exist yet (fresh database) — sync creates it from the
        // model with every value already in place, so there is nothing to add.
        if (!existing.length) continue;

        const present = new Set(existing.map(row => row.label));
        for (const value of values) {
            if (present.has(value)) continue;
            // ALTER TYPE ... ADD VALUE cannot run inside a transaction block on
            // Postgres < 12, so this deliberately runs unwrapped (autocommit).
            // Both identifiers are constants from this file, never user input.
            await db.sequelize.query(
                `ALTER TYPE "${typeName}" ADD VALUE IF NOT EXISTS '${value}'`
            );
            console.log(`Enum ${typeName}: added missing value '${value}'.`);
        }
    }
};

module.exports = ensureEnumValues;
