#!/usr/bin/env node
/**
 * One-off fix for databases seeded before AMENITIES became a view-level module
 * for members.
 *
 * The MEMBER role used to be seeded with can_manage on AMENITIES, which let any
 * resident add/edit/delete facilities and approve bookings — and, because the
 * app routes managers to the admin screen, left them with no way to actually
 * book anything. modulePermissionSeeder never overwrites existing rows
 * ("Never overwrite admin-customised permissions"), so changing the seeder only
 * affects fresh installs. This flips the existing rows.
 *
 * Only the MEMBER role is touched. SOCIETY_ADMIN / SUPER_ADMIN keep manage, and
 * any custom role an admin created is left exactly as it is.
 *
 * Usage:
 *   npm run fix-member-amenities            (report + apply)
 *   npm run fix-member-amenities -- --dry   (report only, change nothing)
 */
require('dotenv').config();

const db = require('../src/models');

const DRY_RUN = process.argv.includes('--dry');

(async () => {
    try {
        const role = await db.Role.findOne({ where: { code: 'MEMBER' } });
        if (!role) {
            console.log('No MEMBER role found — nothing to do.');
            process.exit(0);
        }

        const module = await db.Module.findOne({ where: { code: 'AMENITIES' } });
        if (!module) {
            console.log('No AMENITIES module found — nothing to do.');
            process.exit(0);
        }

        const perm = await db.RolePermission.findOne({
            where: { role_id: role.id, module_id: module.id }
        });

        if (!perm) {
            console.log('MEMBER has no AMENITIES permission row. Creating it as view-only...');
            if (!DRY_RUN) {
                await db.RolePermission.create({
                    role_id: role.id,
                    module_id: module.id,
                    can_view: true,
                    can_manage: false
                });
            }
            console.log(DRY_RUN ? 'Dry run — nothing written.' : 'Done.');
            process.exit(0);
        }

        console.log(`Current: MEMBER / AMENITIES -> can_view=${perm.can_view}, can_manage=${perm.can_manage}`);

        if (perm.can_view && !perm.can_manage) {
            console.log('Already view-only — nothing to do.');
            process.exit(0);
        }

        console.log('Target : MEMBER / AMENITIES -> can_view=true, can_manage=false');

        if (DRY_RUN) {
            console.log('Dry run — nothing written.');
            process.exit(0);
        }

        await perm.update({ can_view: true, can_manage: false });
        console.log('Done. Members now browse + book; approving stays with manage roles.');
        console.log('Members already logged in must reopen the app (or re-login) to pick up the change.');
        process.exit(0);
    } catch (err) {
        console.error('Fix failed:', err);
        process.exit(1);
    }
})();
