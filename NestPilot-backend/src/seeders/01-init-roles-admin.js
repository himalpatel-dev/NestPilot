'use strict';

module.exports = {
    async up(queryInterface, Sequelize) {
        // Seed Roles
        await queryInterface.bulkInsert('tbl_roles', [
            { id: 1, code: 'SUPER_ADMIN', name: 'Super Admin', created_at: new Date(), updated_at: new Date() },
            { id: 2, code: 'SOCIETY_ADMIN', name: 'Society Admin (Secretary)', created_at: new Date(), updated_at: new Date() },
            { id: 3, code: 'MEMBER', name: 'Member', created_at: new Date(), updated_at: new Date() },
            { id: 4, code: 'SECURITY_GUARD', name: 'Security Guard / Gatekeeper', created_at: new Date(), updated_at: new Date() }
        ]);

        // Seed Super Admin
        // Using default super admin mobile 9999999999
        await queryInterface.bulkInsert('tbl_users', [{
            id: 1,
            society_id: null,
            role_id: 1, // SUPER_ADMIN
            full_name: 'Super Admin',
            mobile: '9999999999',
            status: 'active',
            created_at: new Date(),
            updated_at: new Date()
        }]);
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.bulkDelete('tbl_users', { mobile: '9999999999' });
        await queryInterface.bulkDelete('tbl_roles', null, {});
    }
};
