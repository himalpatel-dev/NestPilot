'use strict';

/**
 * Backfill: every existing SOCIETY_ADMIN gets one row in tbl_user_buildings
 * per building in their society. Keeps existing Secretaries from being
 * suddenly locked out when the per-building scope ships.
 *
 * Idempotent: skips any (user_id, building_id) pair that already exists.
 */
module.exports = {
    async up(queryInterface, Sequelize) {
        const [rows] = await queryInterface.sequelize.query(`
            SELECT u.id AS user_id, b.id AS building_id
            FROM tbl_users u
            JOIN tbl_roles r ON r.id = u.role_id
            JOIN tbl_buildings b ON b.society_id = u.society_id
            WHERE r.code = 'SOCIETY_ADMIN'
              AND NOT EXISTS (
                SELECT 1 FROM tbl_user_buildings ub
                WHERE ub.user_id = u.id AND ub.building_id = b.id
              )
        `);

        if (!rows.length) return;

        const now = new Date();
        await queryInterface.bulkInsert('tbl_user_buildings', rows.map(r => ({
            user_id: r.user_id,
            building_id: r.building_id,
            assigned_by: null,
            created_at: now,
            updated_at: now
        })));
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.bulkDelete('tbl_user_buildings', null, {});
    }
};
