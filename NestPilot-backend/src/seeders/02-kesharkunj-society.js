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

        // 6. Amenities
        await queryInterface.bulkInsert('amenities', [
            {
                id: 1,
                society_id: societyId,
                name: 'Clubhouse',
                description: 'A spacious clubhouse for social gatherings',
                image_url: null,
                is_paid: false,
                price_per_hour: 0.00,
                start_time: '09:00:00',
                end_time: '22:00:00',
                is_active: true,
                created_at: new Date(),
                updated_at: new Date()
            },
            {
                id: 2,
                society_id: societyId,
                name: 'Swimming Pool',
                description: 'A clean swimming pool open for all residents',
                image_url: null,
                is_paid: true,
                price_per_hour: 100.00,
                start_time: '06:00:00',
                end_time: '21:00:00',
                is_active: true,
                created_at: new Date(),
                updated_at: new Date()
            }
        ]);

        // 7. Bookings
        await queryInterface.bulkInsert('bookings', [{
            id: 1,
            user_id: 2, // Secretary Kesharkunj
            amenity_id: 2, // Swimming Pool
            society_id: societyId,
            date: new Date().toISOString().split('T')[0],
            start_time: '10:00:00',
            end_time: '12:00:00',
            status: 'CONFIRMED',
            payment_status: 'PAID',
            amount: 200.00,
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // 8. Bills
        const billId = 1;
        await queryInterface.bulkInsert('tbl_bills', [{
            id: billId,
            society_id: societyId,
            created_by: 2, // Secretary
            bill_type: 'MAINTENANCE',
            title: 'Monthly Maintenance Fee - June 2026',
            description: 'Maintenance fee including water, cleaning, and security services',
            amount_total: 30000.00,
            due_date: '2026-06-15',
            penalty_type: 'FIXED',
            penalty_value: 200.00,
            apply_to: 'ALL',
            status: 'PUBLISHED',
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // 9. Bill Targets & 10. Member Bills
        const billTargets = [];
        const memberBills = [];
        // Map all houses (ids 1 to 15)
        for (let houseId = 1; houseId <= 15; houseId++) {
            billTargets.push({
                id: houseId,
                bill_id: billId,
                house_id: houseId,
                created_at: new Date(),
                updated_at: new Date()
            });

            // user_id for houseId is houseId + 1 (since userId starts at 2)
            const userId = houseId + 1;
            // Make house 1 (user 2) paid, others pending
            const billStatus = (houseId === 1) ? 'PAID' : 'PENDING';

            memberBills.push({
                id: houseId,
                bill_id: billId,
                house_id: houseId,
                user_id: userId,
                amount: 2000.00,
                due_date: '2026-06-15',
                penalty_amount: 0.00,
                status: billStatus,
                created_at: new Date(),
                updated_at: new Date()
            });
        }

        await queryInterface.bulkInsert('tbl_bill_targets', billTargets);
        await queryInterface.bulkInsert('tbl_member_bills', memberBills);

        // 11. Payments
        const paymentId = 1;
        await queryInterface.bulkInsert('tbl_payments', [{
            id: paymentId,
            society_id: societyId,
            member_bill_id: 1, // for House 1 (user 2)
            house_id: 1,
            user_id: 2,
            amount: 2000.00,
            payment_mode: 'UPI',
            payment_date: new Date(),
            reference_no: 'UPI1234567890',
            note: 'Paid online via UPI',
            is_offline_entry: false,
            sync_status: 'SYNCED',
            received_by: null,
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // 12. Payment Receipts
        await queryInterface.bulkInsert('tbl_payment_receipts', [{
            id: 1,
            payment_id: paymentId,
            receipt_no: 'REC-2026-0001',
            receipt_pdf_path: '/uploads/receipts/rec-2026-0001.pdf',
            generated_at: new Date(),
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // 13. Notices
        const noticeId = 1;
        await queryInterface.bulkInsert('tbl_notices', [{
            id: noticeId,
            society_id: societyId,
            building_id: null,
            created_by: 2, // Secretary
            title: 'Annual General Body Meeting',
            description: 'The annual general meeting of Kesharkunj Residency is scheduled on June 5, 2026 at the Clubhouse.',
            publish_date: new Date(),
            expiry_date: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000),
            is_active: true,
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // 14. Notice Attachments
        await queryInterface.bulkInsert('tbl_notice_attachments', [{
            id: 1,
            notice_id: noticeId,
            file_type: 'application/pdf',
            file_path: '/uploads/notices/agm_agenda_2026.pdf',
            original_name: 'agm_agenda_2026.pdf',
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // 15. Complaints
        const complaintId = 1;
        await queryInterface.bulkInsert('tbl_complaints', [{
            id: complaintId,
            society_id: societyId,
            house_id: 2,
            created_by: 3, // Owner of house 2
            category: 'PLUMBING',
            description: 'Water leakage in the kitchen sink area',
            image_path: null,
            priority: 'HIGH',
            status: 'OPEN',
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // 16. Complaint Comments
        await queryInterface.bulkInsert('tbl_complaint_comments', [{
            id: 1,
            complaint_id: complaintId,
            user_id: 2, // Secretary
            message: 'Plumber has been assigned. He will visit today by 4 PM.',
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // 17. Polls
        const pollId = 1;
        await queryInterface.bulkInsert('polls', [{
            id: pollId,
            society_id: societyId,
            created_by: 2, // Secretary
            question: 'Should we paint the outer walls of the society?',
            description: 'The society was last painted 5 years ago. The estimated budget is 5,000 INR per house.',
            end_date: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
            is_active: true,
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // 18. Poll Options
        await queryInterface.bulkInsert('poll_options', [
            { id: 1, poll_id: pollId, option_text: 'Yes, absolutely' },
            { id: 2, poll_id: pollId, option_text: 'No, not now' },
            { id: 3, poll_id: pollId, option_text: 'Maybe later' }
        ]);

        // 19. Poll Votes
        await queryInterface.bulkInsert('poll_votes', [
            {
                id: 1,
                poll_id: pollId,
                option_id: 1, // Yes
                user_id: 3,
                created_at: new Date(),
                updated_at: new Date()
            },
            {
                id: 2,
                poll_id: pollId,
                option_id: 1, // Yes
                user_id: 4,
                created_at: new Date(),
                updated_at: new Date()
            }
        ]);

        // 20. Documents
        await queryInterface.bulkInsert('documents', [{
            id: 1,
            society_id: societyId,
            uploaded_by: 2, // Secretary
            title: 'Society By-laws and Rules',
            category: 'BY_LAWS',
            file_url: '/uploads/documents/society_by_laws.pdf',
            is_private: false,
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // 21. Vehicles
        await queryInterface.bulkInsert('vehicles', [
            {
                id: 1,
                user_id: 3,
                society_id: societyId,
                type: 'CAR',
                vehicle_number: 'GJ-01-AA-1234',
                brand: 'Maruti Suzuki',
                model: 'Swift',
                sticker_number: 'KKR-001',
                is_active: true,
                created_at: new Date(),
                updated_at: new Date()
            },
            {
                id: 2,
                user_id: 4,
                society_id: societyId,
                type: 'BIKE',
                vehicle_number: 'GJ-01-BB-5678',
                brand: 'Honda',
                model: 'Activa',
                sticker_number: 'KKR-002',
                is_active: true,
                created_at: new Date(),
                updated_at: new Date()
            }
        ]);

        // 22. Visitors
        const visitorId = 1;
        await queryInterface.bulkInsert('visitors', [{
            id: visitorId,
            society_id: societyId,
            name: 'Delivery Boy',
            mobile: '9876543210',
            profile_image: null,
            type: 'DELIVERY',
            frequent_visitor: true,
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // 23. Visitor Logs
        await queryInterface.bulkInsert('visitor_logs', [{
            id: 1,
            visitor_id: visitorId,
            house_id: 2,
            society_id: societyId,
            entry_time: new Date(Date.now() - 2 * 60 * 60 * 1000),
            exit_time: new Date(Date.now() - 1.8 * 60 * 60 * 1000),
            entry_gate: 'Gate 1',
            exit_gate: 'Gate 1',
            status: 'APPROVED',
            pass_code: '1234',
            vehicle_number: 'GJ-01-XY-9999',
            purpose: 'Amazon Delivery',
            approval_by_user_id: 3, // Owner of house 2
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // 24. Service Staff
        const staffId = 1;
        await queryInterface.bulkInsert('service_staff', [{
            id: staffId,
            society_id: societyId,
            name: 'Ramesh Patel',
            role: 'GARDENER',
            mobile: '9988776655',
            profile_image: null,
            aadhaar_number: '123456789012',
            is_active: true,
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // 25. Staff Attendance
        await queryInterface.bulkInsert('staff_attendance', [{
            id: 1,
            staff_id: staffId,
            date: new Date().toISOString().split('T')[0],
            in_time: new Date(Date.now() - 4 * 60 * 60 * 1000),
            out_time: new Date(Date.now() - 1 * 60 * 60 * 1000),
            is_present: true,
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // 26. Notifications
        await queryInterface.bulkInsert('tbl_notifications', [{
            id: 1,
            user_id: 3,
            society_id: societyId,
            type: 'NOTICE',
            title: 'New Notice Published',
            message: 'Annual General Body Meeting notice has been published.',
            reference_id: 1,
            is_read: false,
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // 27. OTP Requests
        await queryInterface.bulkInsert('tbl_otp_requests', [{
            id: 1,
            mobile: '9727376727',
            otp_hash: '$2b$10$X8O5K16B1pYy1z2.4g5p6eLp7hI4s.k2uP1wT3qA5uF6eI1r8o1y2', // Example bcrypt hash
            purpose: 'LOGIN',
            expires_at: new Date(Date.now() + 5 * 60 * 1000),
            verified_at: null,
            attempts: 0,
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // 28. Audit Logs
        await queryInterface.bulkInsert('tbl_audit_logs', [{
            id: 1,
            society_id: societyId,
            building_id: buildingId,
            user_id: 2, // Secretary
            action: 'CREATE_NOTICE',
            entity_type: 'Notice',
            entity_id: '1',
            old_value: null,
            new_value: JSON.stringify({ title: 'Annual General Body Meeting' }),
            ip_address: '127.0.0.1',
            created_at: new Date(),
            updated_at: new Date()
        }]);

        // Reset sequences for PostgreSQL to avoid duplicate key errors on new inserts
        const tablesToSync = [
            'tbl_roles',
            'tbl_societies',
            'tbl_buildings',
            'tbl_houses',
            'tbl_users',
            'tbl_user_house_mappings',
            'amenities',
            'bookings',
            'tbl_bills',
            'tbl_bill_targets',
            'tbl_member_bills',
            'tbl_payments',
            'tbl_payment_receipts',
            'tbl_notices',
            'tbl_notice_attachments',
            'tbl_complaints',
            'tbl_complaint_comments',
            'polls',
            'poll_options',
            'poll_votes',
            'documents',
            'vehicles',
            'visitors',
            'visitor_logs',
            'service_staff',
            'staff_attendance',
            'tbl_notifications',
            'tbl_otp_requests',
            'tbl_audit_logs'
        ];

        for (const table of tablesToSync) {
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

        console.log(`Seeded Kesharkunj Residency (Row House) with ${houses.length} houses, ${users.length} users, and all remaining tables seeded.`);
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
            await queryInterface.sequelize.query(`DELETE FROM tbl_audit_logs WHERE society_id = ${societyId}`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_otp_requests WHERE mobile = '9727376727'`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_notifications WHERE society_id = ${societyId}`);
            await queryInterface.sequelize.query(`DELETE FROM staff_attendance WHERE staff_id IN (SELECT id FROM service_staff WHERE society_id = ${societyId})`);
            await queryInterface.sequelize.query(`DELETE FROM service_staff WHERE society_id = ${societyId}`);
            await queryInterface.sequelize.query(`DELETE FROM visitor_logs WHERE society_id = ${societyId}`);
            await queryInterface.sequelize.query(`DELETE FROM visitors WHERE society_id = ${societyId}`);
            await queryInterface.sequelize.query(`DELETE FROM vehicles WHERE society_id = ${societyId}`);
            await queryInterface.sequelize.query(`DELETE FROM documents WHERE society_id = ${societyId}`);
            await queryInterface.sequelize.query(`DELETE FROM poll_votes WHERE poll_id IN (SELECT id FROM polls WHERE society_id = ${societyId})`);
            await queryInterface.sequelize.query(`DELETE FROM poll_options WHERE poll_id IN (SELECT id FROM polls WHERE society_id = ${societyId})`);
            await queryInterface.sequelize.query(`DELETE FROM polls WHERE society_id = ${societyId}`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_complaint_comments WHERE complaint_id IN (SELECT id FROM tbl_complaints WHERE society_id = ${societyId})`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_complaints WHERE society_id = ${societyId}`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_notice_attachments WHERE notice_id IN (SELECT id FROM tbl_notices WHERE society_id = ${societyId})`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_notices WHERE society_id = ${societyId}`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_payment_receipts WHERE payment_id IN (SELECT id FROM tbl_payments WHERE society_id = ${societyId})`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_payments WHERE society_id = ${societyId}`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_member_bills WHERE bill_id IN (SELECT id FROM tbl_bills WHERE society_id = ${societyId})`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_bill_targets WHERE bill_id IN (SELECT id FROM tbl_bills WHERE society_id = ${societyId})`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_bills WHERE society_id = ${societyId}`);
            await queryInterface.sequelize.query(`DELETE FROM bookings WHERE society_id = ${societyId}`);
            await queryInterface.sequelize.query(`DELETE FROM amenities WHERE society_id = ${societyId}`);

            await queryInterface.sequelize.query(`DELETE FROM tbl_user_house_mappings WHERE house_id IN (SELECT id FROM tbl_houses WHERE society_id = ${societyId})`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_users WHERE society_id = ${societyId}`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_houses WHERE society_id = ${societyId}`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_buildings WHERE society_id = ${societyId}`);
            await queryInterface.sequelize.query(`DELETE FROM tbl_societies WHERE id = ${societyId}`);
        }
    }
};
