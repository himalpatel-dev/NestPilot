
'use strict';

const MODULES = [
    { code: 'DASHBOARD', name: 'Dashboard', sort_order: 1 },
    { code: 'NOTICES', name: 'Notices', sort_order: 2 },
    { code: 'COMPLAINTS', name: 'Complaints', sort_order: 3 },
    { code: 'BILLS', name: 'Bills & Payments', sort_order: 4 },
    { code: 'EVENTS', name: 'Events', sort_order: 5 },
    { code: 'AMENITIES', name: 'Amenities', sort_order: 6 },
    { code: 'VISITORS', name: 'Visitors Hub', sort_order: 7 },
    { code: 'GATE_CONTROL', name: 'Gate Control Terminal', sort_order: 8 },
    { code: 'STAFF', name: 'Service Staff', sort_order: 9 },
    { code: 'POLLS', name: 'Polls & Surveys', sort_order: 10 },
    { code: 'DOCUMENTS', name: 'Documents', sort_order: 11 },
    { code: 'VEHICLES', name: 'Vehicles', sort_order: 12 },
    { code: 'USERS', name: 'User Management', sort_order: 13 },
    { code: 'BUILDINGS', name: 'Buildings & Houses', sort_order: 14 },
    { code: 'REPORTS', name: 'Reports', sort_order: 15 },
    { code: 'ROLES', name: 'Roles & Permissions', sort_order: 16 }
];

const DEFAULT_ROLES = [
    { code: 'SUPER_ADMIN', name: 'Super Admin', is_system: true },
    { code: 'SOCIETY_ADMIN', name: 'Society Admin', is_system: true },
    { code: 'MEMBER', name: 'Member', is_system: true },
    { code: 'SECURITY_GUARD', name: 'Security Guard', is_system: false }
];

const MANAGE = { can_view: true, can_manage: true };
const VIEW = { can_view: true, can_manage: false };
const NONE = { can_view: false, can_manage: false };

const DEFAULT_PERMISSIONS = {
    SUPER_ADMIN: {
        '*': MANAGE
    },

    SOCIETY_ADMIN: {
        DASHBOARD: VIEW,
        NOTICES: MANAGE,
        COMPLAINTS: MANAGE,
        BILLS: MANAGE,
        EVENTS: MANAGE,
        AMENITIES: MANAGE,
        VISITORS: MANAGE,
        GATE_CONTROL: VIEW,
        STAFF: MANAGE,
        POLLS: MANAGE,
        DOCUMENTS: MANAGE,
        VEHICLES: MANAGE,
        USERS: MANAGE,
        BUILDINGS: MANAGE,
        REPORTS: VIEW,
        ROLES: VIEW
    },

    MEMBER: {
        DASHBOARD: VIEW,
        NOTICES: VIEW,
        COMPLAINTS: MANAGE,
        BILLS: VIEW,
        EVENTS: VIEW,
        AMENITIES: VIEW,
        VISITORS: MANAGE,
        GATE_CONTROL: NONE,
        STAFF: MANAGE,
        POLLS: VIEW,
        DOCUMENTS: VIEW,
        VEHICLES: MANAGE,
        USERS: NONE,
        BUILDINGS: VIEW,
        REPORTS: NONE,
        ROLES: NONE
    },

    SECURITY_GUARD: {
        DASHBOARD: VIEW,
        NOTICES: VIEW,
        COMPLAINTS: NONE,
        BILLS: NONE,
        EVENTS: VIEW,
        AMENITIES: NONE,
        VISITORS: NONE,
        GATE_CONTROL: MANAGE,
        STAFF: MANAGE,
        POLLS: VIEW,
        DOCUMENTS: NONE,
        VEHICLES: VIEW,
        USERS: NONE,
        BUILDINGS: VIEW,
        REPORTS: NONE,
        ROLES: NONE
    }
};

module.exports = {
    async up(queryInterface, Sequelize) {
        const transaction = await queryInterface.sequelize.transaction();

        try {
            console.log('[Seeder] Creating default roles...');

            // 1. Insert missing roles
            const [existingRoles] = await queryInterface.sequelize.query(
                'SELECT id, code FROM tbl_roles',
                { transaction }
            );

            const roleMap = new Map(
                existingRoles.map(role => [role.code, role.id])
            );

            for (const role of DEFAULT_ROLES) {
                if (!roleMap.has(role.code)) {
                    await queryInterface.bulkInsert(
                        'tbl_roles',
                        [{
                            code: role.code,
                            name: role.name,
                            is_system: role.is_system,
                            is_active: true,
                            created_at: new Date(),
                            updated_at: new Date()
                        }],
                        { transaction }
                    );
                }
            }

            // Reload roles to get generated IDs
            const [allRoles] = await queryInterface.sequelize.query(
                'SELECT id, code FROM tbl_roles',
                { transaction }
            );

            const roles = new Map(
                allRoles.map(role => [role.code, role.id])
            );

            console.log('[Seeder] Creating modules...');

            // 2. Insert missing modules
            const [existingModules] = await queryInterface.sequelize.query(
                'SELECT id, code FROM tbl_modules',
                { transaction }
            );

            const moduleMap = new Map(
                existingModules.map(module => [module.code, module.id])
            );

            for (const module of MODULES) {
                if (!moduleMap.has(module.code)) {
                    await queryInterface.bulkInsert(
                        'tbl_modules',
                        [{
                            code: module.code,
                            name: module.name,
                            sort_order: module.sort_order,
                            is_active: true,
                            created_at: new Date(),
                            updated_at: new Date()
                        }],
                        { transaction }
                    );
                }
            }

            // Reload modules to get generated IDs
            const [allModules] = await queryInterface.sequelize.query(
                'SELECT id, code FROM tbl_modules',
                { transaction }
            );

            console.log('[Seeder] Creating missing permissions...');

            // 3. Fetch existing permissions
            const [existingPermissions] =
                await queryInterface.sequelize.query(
                    'SELECT role_id, module_id FROM tbl_role_permissions',
                    { transaction }
                );

            const permissionSet = new Set(
                existingPermissions.map(
                    permission => `${permission.role_id}_${permission.module_id}`
                )
            );

            const permissionRecords = [];

            // 4. Generate only missing permissions
            for (const [roleCode, modulePermissions] of Object.entries(
                DEFAULT_PERMISSIONS
            )) {
                const roleId = roles.get(roleCode);

                if (!roleId) continue;

                for (const module of allModules) {
                    const permissionKey = `${roleId}_${module.id}`;

                    if (permissionSet.has(permissionKey)) continue;

                    const permissions =
                        modulePermissions[module.code] ||
                        modulePermissions['*'] ||
                        NONE;

                    permissionRecords.push({
                        role_id: roleId,
                        module_id: module.id,
                        can_view: permissions.can_view,
                        can_manage: permissions.can_manage,
                        created_at: new Date(),
                        updated_at: new Date()
                    });
                }
            }

            if (permissionRecords.length > 0) {
                await queryInterface.bulkInsert(
                    'tbl_role_permissions',
                    permissionRecords,
                    { transaction }
                );
            }

            await transaction.commit();

            console.log(
                `[Seeder] Completed successfully. Added ${permissionRecords.length} missing permissions.`
            );
        } catch (error) {
            await transaction.rollback();
            console.error('[Seeder] Failed:', error);
            throw error;
        }
    },

    async down(queryInterface, Sequelize) {
        // Intentionally do not delete role/module/permission data.
        // This protects customized permissions and production records.
        console.log(
            '[Seeder] Rollback skipped to protect existing role and permission data.'
        );
    }
};
