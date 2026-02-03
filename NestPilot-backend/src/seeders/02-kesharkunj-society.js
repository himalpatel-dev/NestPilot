'use strict';

module.exports = {
    async up(queryInterface, Sequelize) {
        // 1. Create Society: Kesharkunj Residency (Row House Society)
        const societyId = 1;
        await queryInterface.bulkInsert('tbl_societies', [{
            id: societyId,
            name: 'Kesharkunj Residency',
            address: 'Scientific Road',
            city: 'Ahmedabad',
            state: 'Gujarat',
            pincode: '380001',
            status: 'active',
            society_type: 'ROW_HOUSE',
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // 2. Create Building: Sector 1 (Representing a group of row houses)
        const buildingId = 1;
        await queryInterface.bulkInsert('tbl_buildings', [{
            id: buildingId,
            society_id: societyId,
            name: 'Sector 1',
            blocks: '1',
            wings: 'All',
            floors_count: 0,
            created_at: new Date(),
            updated_at: new Date()
        }]);

        const houses = [];
        const users = [];
        const userHouseMappings = [];

        // Types Configuration
        const types = [
            { code: 'A', bhk: '5BHK', area: 3000, desc: 'Big Area' },
            { code: 'B', bhk: '5BHK', area: 2200, desc: 'Small Area' },
            { code: 'C', bhk: '4BHK', area: 1800, desc: 'Small Area' }
        ];

        let mobileCounter = 9727376737;
        let houseIdCounter = 1;
        let userIdCounter = 2; // Start after 1 (Super Admin)
        let mappingIdCounter = 1;

        // Generate 5 houses for each type
        for (const type of types) {
            for (let i = 1; i <= 5; i++) {
                const houseNo = `${type.code}-${i}`; // e.g., A-1, B-1, C-1
                const houseId = houseIdCounter++;

                houses.push({
                    id: houseId,
                    society_id: societyId,
                    building_id: buildingId,
                    floor_no: 0,
                    house_no: houseNo,
                    house_type: type.bhk,
                    area_sqft: type.area,
                    unit_type: 'ROW_HOUSE',
                    is_active: true,
                    created_at: new Date(),
                    updated_at: new Date()
                });

                // Create 1 User per house
                const userId = userIdCounter++;
                const isSecretary = (userId === 2); // First user after Super Admin
                const mobile = isSecretary ? '9727376727' : (mobileCounter++).toString();

                users.push({
                    id: userId,
                    society_id: societyId,
                    role_id: isSecretary ? 2 : 3, // 2 = SOCIETY_ADMIN, 3 = MEMBER
                    full_name: isSecretary ? `Secretary Kesharkunj (${houseNo})` : `Resident ${houseNo} (${type.desc})`,
                    mobile: mobile,
                    status: 'active',
                    created_at: new Date(),
                    updated_at: new Date()
                });

                // Map User to House
                userHouseMappings.push({
                    id: mappingIdCounter++,
                    user_id: userId,
                    house_id: houseId,
                    relation_type: 'OWNER',
                    is_primary: true,
                    is_active: true,
                    created_at: new Date(),
                    updated_at: new Date()
                });
            }
        }

        // Seed a Security Guard
        await queryInterface.bulkInsert('tbl_users', [{
            id: userIdCounter++,
            society_id: societyId,
            role_id: 4, // SECURITY_GUARD
            full_name: 'Main Gate Security',
            mobile: '9000000000',
            status: 'active',
            created_at: new Date(),
            updated_at: new Date()
        }]);

        await queryInterface.bulkInsert('tbl_houses', houses);
        await queryInterface.bulkInsert('tbl_users', users);
        await queryInterface.bulkInsert('tbl_user_house_mappings', userHouseMappings);

        console.log(`Seeded Kesharkunj Residency (Row House) with ${houses.length} houses and ${users.length} users.`);
    },

    async down(queryInterface, Sequelize) {
        const societyName = 'Kesharkunj Residency';

        // 1. Get Society ID
        const societies = await queryInterface.sequelize.query(
            `SELECT id FROM tbl_societies WHERE name = '${societyName}'`,
            { type: queryInterface.sequelize.QueryTypes.SELECT }
        );

        if (societies.length > 0) {
            const societyId = societies[0].id;

            // 2. Delete dependent data in reverse order of dependencies
            await queryInterface.sequelize.query(`DELETE FROM tbl_complaint_comments WHERE user_id IN (SELECT id FROM tbl_users WHERE society_id = ${societyId})`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_complaints WHERE society_id = ${societyId}`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_notice_attachments WHERE notice_id IN (SELECT id FROM tbl_notices WHERE society_id = ${societyId})`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_notices WHERE society_id = ${societyId}`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_member_bills WHERE house_id IN (SELECT id FROM tbl_houses WHERE society_id = ${societyId})`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_payments WHERE house_id IN (SELECT id FROM tbl_houses WHERE society_id = ${societyId})`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_bills WHERE society_id = ${societyId}`);

            await queryInterface.sequelize.query(`DELETE FROM tbl_user_house_mappings WHERE house_id IN (SELECT id FROM tbl_houses WHERE society_id = ${societyId})`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_users WHERE society_id = ${societyId}`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_houses WHERE society_id = ${societyId}`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_buildings WHERE society_id = ${societyId}`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_societies WHERE id = ${societyId}`);
        }
    }
};
