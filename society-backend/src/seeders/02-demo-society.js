'use strict';

module.exports = {
    async up(queryInterface, Sequelize) {
        // 1. Create Society
        const societyId = 1;
        await queryInterface.bulkInsert('societies', [{
            id: societyId,
            name: 'Gokuldham Society',
            address: 'Powder Galli, Goregaon East',
            city: 'Mumbai',
            state: 'Maharashtra',
            pincode: '400063',
            status: 'active',
            society_type: 'APARTMENT',
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // 2. Create Buildings
        const buildingAId = 1;
        const buildingBId = 2;
        await queryInterface.bulkInsert('buildings', [
            {
                id: buildingAId,
                society_id: societyId,
                name: 'A Wing',
                blocks: 'A',
                wings: 'East',
                floors_count: 5,
                created_at: new Date(),
                updated_at: new Date()
            },
            {
                id: buildingBId,
                society_id: societyId,
                name: 'B Wing',
                blocks: 'B',
                wings: 'West',
                floors_count: 5,
                created_at: new Date(),
                updated_at: new Date()
            }
        ]);

        // 3. Create Units (Houses)
        const houseA101Id = 1;
        const houseA102Id = 2;
        const houseB101Id = 3;

        await queryInterface.bulkInsert('houses', [
            {
                id: houseA101Id,
                society_id: societyId,
                building_id: buildingAId,
                floor_no: 1,
                house_no: '101',
                house_type: '2BHK',
                area_sqft: 1200,
                unit_type: 'FLAT',
                is_active: true,
                created_at: new Date(),
                updated_at: new Date()
            },
            {
                id: houseA102Id,
                society_id: societyId,
                building_id: buildingAId,
                floor_no: 1,
                house_no: '102',
                house_type: '2BHK',
                area_sqft: 1200,
                unit_type: 'FLAT',
                is_active: true,
                created_at: new Date(),
                updated_at: new Date()
            },
            {
                id: houseB101Id,
                society_id: societyId,
                building_id: buildingBId,
                floor_no: 1,
                house_no: '101',
                house_type: '3BHK',
                area_sqft: 1500,
                unit_type: 'FLAT',
                is_active: true,
                created_at: new Date(),
                updated_at: new Date()
            }
        ]);

        // 4. Create Society Admin (Secretary)
        // Mobile: 9000000000
        const secretaryId = 2;
        await queryInterface.bulkInsert('users', [{
            id: secretaryId,
            society_id: societyId,
            role_id: 2, // SOCIETY_ADMIN
            full_name: 'Bhide (Secretary)',
            mobile: '9000000000',
            status: 'active',
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // 5. Create Member (Jethalal)
        // Mobile: 9876543210
        const memberId = 3;
        await queryInterface.bulkInsert('users', [{
            id: memberId,
            society_id: societyId,
            role_id: 3, // MEMBER
            full_name: 'Jethalal Gada',
            mobile: '9876543210',
            status: 'active',
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // 6. Map Member to House B-101
        await queryInterface.bulkInsert('user_house_mappings', [{
            id: 1,
            user_id: memberId,
            house_id: houseB101Id,
            relation_type: 'OWNER',
            is_primary: true,
            is_active: true,
            created_at: new Date(),
            updated_at: new Date()
        }]);

        console.log(`Seeded Society: Gokuldham (${societyId})`);
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.bulkDelete('user_house_mappings', null, {});
        await queryInterface.bulkDelete('users', { mobile: ['9000000000', '9876543210'] });
        await queryInterface.bulkDelete('houses', null, {});
        await queryInterface.bulkDelete('buildings', null, {});
        await queryInterface.bulkDelete('societies', { name: 'Gokuldham Society' });
    }
};
