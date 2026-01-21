'use strict';

module.exports = {
    async up(queryInterface, Sequelize) {
        // 1. Create Row House Society
        const societyId = 2;
        await queryInterface.bulkInsert('societies', [{
            id: societyId,
            name: 'Green Valley Row Houses',
            society_type: 'ROW_HOUSE',
            address: 'MG Road, Pune',
            city: 'Pune',
            state: 'Maharashtra',
            pincode: '411001',
            status: 'active',
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // 2. Create "Building" (Acts as Lane or Sector)
        const lane1Id = 3;
        await queryInterface.bulkInsert('buildings', [{
            id: lane1Id,
            society_id: societyId,
            name: 'Lane 1', // Logical grouping
            blocks: 'L1',
            wings: null, // No wings in a lane usually
            floors_count: 1, // Ground structures
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // 3. Create Units (Row Houses)
        await queryInterface.bulkInsert('houses', [
            {
                id: 4,
                society_id: societyId,
                building_id: lane1Id,
                unit_type: 'ROW_HOUSE',
                floor_no: 0, // Ground
                house_no: 'RH-01',
                house_type: '3BHK Duplex',
                area_sqft: 2000,
                is_active: true,
                created_at: new Date(),
                updated_at: new Date()
            },
            {
                id: 5,
                society_id: societyId,
                building_id: lane1Id,
                unit_type: 'ROW_HOUSE',
                floor_no: 0,
                house_no: 'RH-02',
                house_type: '3BHK Duplex',
                area_sqft: 2000,
                is_active: true,
                created_at: new Date(),
                updated_at: new Date()
            }
        ]);

        // ---------------------------------------------------------

        // 4. Create Single Building Society
        const singleSocId = 3;
        await queryInterface.bulkInsert('societies', [{
            id: singleSocId,
            name: 'Standalone Tower',
            society_type: 'APARTMENT',
            address: 'City Center',
            city: 'Mumbai',
            state: 'Maharashtra',
            pincode: '400001',
            status: 'active',
            created_at: new Date(),
            updated_at: new Date()
        }]);

        const towerId = 4;
        await queryInterface.bulkInsert('buildings', [{
            id: towerId,
            society_id: singleSocId,
            name: 'Main Tower', // Just one building
            blocks: null,
            wings: null,
            floors_count: 10,
            created_at: new Date(),
            updated_at: new Date()
        }]);

        await queryInterface.bulkInsert('houses', [{
            id: 6,
            society_id: singleSocId,
            building_id: towerId,
            unit_type: 'FLAT',
            floor_no: 5,
            house_no: '501',
            house_type: '2BHK',
            area_sqft: 900,
            is_active: true,
            created_at: new Date(),
            updated_at: new Date()
        }]);

        console.log(`Seeded Row House Society: Green Valley (${societyId})`);
        console.log(`Seeded Single Building Society: Standalone Tower (${singleSocId})`);
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.bulkDelete('user_house_mappings', null, {});
        await queryInterface.bulkDelete('houses', null, {});
        await queryInterface.bulkDelete('buildings', null, {});
        await queryInterface.bulkDelete('societies', { name: ['Green Valley Row Houses', 'Standalone Tower'] });
    }
};
