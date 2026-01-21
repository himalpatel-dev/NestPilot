'use strict';

module.exports = {
    async up(queryInterface, Sequelize) {
        // 1. Create Society: Kesharkunj Residency (Row House Society)
        const societyId = 4;
        await queryInterface.bulkInsert('societies', [{
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
        const buildingId = 5;
        await queryInterface.bulkInsert('buildings', [{
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

        let mobileCounter = 9910000001;
        let houseIdCounter = 7;
        let userIdCounter = 4;
        let mappingIdCounter = 2; // Start after 1 (which was used in 02-demo)

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
                const mobile = (mobileCounter++).toString();

                users.push({
                    id: userId,
                    society_id: societyId,
                    role_id: 3, // MEMBER
                    full_name: `Resident ${houseNo} (${type.desc})`,
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

        await queryInterface.bulkInsert('houses', houses);
        await queryInterface.bulkInsert('users', users);
        await queryInterface.bulkInsert('user_house_mappings', userHouseMappings);

        console.log(`Seeded Kesharkunj Residency (Row House) with ${houses.length} houses and ${users.length} users.`);
    },

    async down(queryInterface, Sequelize) {
        const societyName = 'Kesharkunj Residency';

        // Cleanup based on society name logic or ID ranges if known
        await queryInterface.sequelize.query(`
            DELETE FROM user_house_mappings WHERE house_id IN (
                SELECT id FROM houses WHERE society_id IN (
                    SELECT id FROM societies WHERE name = '${societyName}'
                )
            );
        `);

        await queryInterface.sequelize.query(`
            DELETE FROM users WHERE society_id IN (
                SELECT id FROM societies WHERE name = '${societyName}'
            );
        `);

        await queryInterface.sequelize.query(`
            DELETE FROM houses WHERE society_id IN (
                SELECT id FROM societies WHERE name = '${societyName}'
            );
        `);

        await queryInterface.sequelize.query(`
            DELETE FROM buildings WHERE society_id IN (
                SELECT id FROM societies WHERE name = '${societyName}'
            );
        `);

        await queryInterface.sequelize.query(`
            DELETE FROM societies WHERE name = '${societyName}';
        `);
    }
};
