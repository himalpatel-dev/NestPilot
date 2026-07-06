const db = require('../models');

const MODULES = [
    { code: 'DASHBOARD',   name: 'Dashboard',           sort_order: 1  },
    { code: 'NOTICES',     name: 'Notices',              sort_order: 2  },
    { code: 'COMPLAINTS',  name: 'Complaints',           sort_order: 3  },
    { code: 'BILLS',       name: 'Bills & Payments',     sort_order: 4  },
    { code: 'EVENTS',      name: 'Events',               sort_order: 5  },
    { code: 'AMENITIES',   name: 'Amenities',            sort_order: 6  },
    { code: 'VISITORS',    name: 'Visitors',             sort_order: 7  },
    { code: 'STAFF',       name: 'Service Staff',        sort_order: 8  },
    { code: 'POLLS',       name: 'Polls & Surveys',      sort_order: 9  },
    { code: 'DOCUMENTS',   name: 'Documents',            sort_order: 10 },
    { code: 'VEHICLES',    name: 'Vehicles',             sort_order: 11 },
    { code: 'USERS',       name: 'User Management',      sort_order: 12 },
    { code: 'BUILDINGS',   name: 'Buildings & Houses',   sort_order: 13 },
    { code: 'REPORTS',     name: 'Reports',              sort_order: 14 },
    { code: 'ROLES',       name: 'Roles & Permissions',  sort_order: 15 },
];

const DEFAULT_ROLES = [
    { code: 'SUPER_ADMIN',    name: 'Super Admin',     is_system: true  },
    { code: 'SOCIETY_ADMIN',  name: 'Society Admin',   is_system: true  },
    { code: 'MEMBER',         name: 'Member',          is_system: true  },
    { code: 'SECURITY_GUARD', name: 'Security Guard',  is_system: false },
];

// Two-flag model: can_view (see list/detail) and can_manage (add/edit/delete/approve).
const MANAGE = { can_view: true,  can_manage: true  };
const VIEW   = { can_view: true,  can_manage: false };
const NONE   = { can_view: false, can_manage: false };

// Permissions per role per module. '*' = applies to every module not listed explicitly.
const DEFAULT_PERMISSIONS = {
    SUPER_ADMIN: { '*': MANAGE },

    SOCIETY_ADMIN: {
        DASHBOARD:  VIEW,
        NOTICES:    MANAGE,
        COMPLAINTS: MANAGE,
        BILLS:      MANAGE,
        EVENTS:     MANAGE,
        AMENITIES:  MANAGE,
        VISITORS:   MANAGE,
        STAFF:      MANAGE,
        POLLS:      MANAGE,
        DOCUMENTS:  MANAGE,
        VEHICLES:   MANAGE,
        USERS:      MANAGE,
        BUILDINGS:  MANAGE,
        REPORTS:    VIEW,
        ROLES:      VIEW,
    },

    MEMBER: {
        DASHBOARD:  VIEW,
        NOTICES:    VIEW,
        COMPLAINTS: MANAGE,
        BILLS:      VIEW,
        EVENTS:     VIEW,
        AMENITIES:  MANAGE,
        VISITORS:   MANAGE,
        STAFF:      MANAGE, // manage = log attendance
        POLLS:      VIEW,
        DOCUMENTS:  VIEW,
        VEHICLES:   MANAGE,
        USERS:      NONE,
        BUILDINGS:  VIEW,
        REPORTS:    NONE,
        ROLES:      NONE,
    },

    SECURITY_GUARD: {
        DASHBOARD:  VIEW,
        NOTICES:    VIEW,
        COMPLAINTS: NONE,
        BILLS:      NONE,
        EVENTS:     VIEW,
        AMENITIES:  NONE,
        VISITORS:   MANAGE,
        STAFF:      MANAGE, // manage = log attendance
        POLLS:      VIEW,
        DOCUMENTS:  NONE,
        VEHICLES:   VIEW,
        USERS:      NONE,
        BUILDINGS:  VIEW,
        REPORTS:    NONE,
        ROLES:      NONE,
    },
};

const runSeeder = async () => {
    try {
        console.log('[Seeder] Running module & permission seeder...');

        // 1. Ensure all default roles exist and have is_system set correctly
        for (const r of DEFAULT_ROLES) {
            const [role, created] = await db.Role.findOrCreate({
                where: { code: r.code },
                defaults: { name: r.name, is_system: r.is_system, is_active: true }
            });
            if (!created && role.is_system == null) {
                await role.update({ is_system: r.is_system });
            }
        }

        // 2. Ensure all modules exist
        for (const m of MODULES) {
            await db.Module.findOrCreate({
                where: { code: m.code },
                defaults: { name: m.name, sort_order: m.sort_order, is_active: true }
            });
        }

        // 3. Seed default permissions (only creates missing rows, never overwrites existing)
        const allModules = await db.Module.findAll();
        const moduleMap = {};
        allModules.forEach(m => { moduleMap[m.code] = m; });

        for (const [roleCode, modulesPerms] of Object.entries(DEFAULT_PERMISSIONS)) {
            const role = await db.Role.findOne({ where: { code: roleCode } });
            if (!role) continue;

            for (const mod of allModules) {
                const existing = await db.RolePermission.findOne({
                    where: { role_id: role.id, module_id: mod.id }
                });
                if (existing) continue; // Never overwrite admin-customised permissions

                const perms = modulesPerms[mod.code] || modulesPerms['*'] || NONE;
                await db.RolePermission.create({
                    role_id: role.id,
                    module_id: mod.id,
                    ...perms
                });
            }
        }

        console.log('[Seeder] Module & permission seeder completed successfully.');
    } catch (err) {
        console.error('[Seeder] Error:', err.message);
    }
};

module.exports = runSeeder;
