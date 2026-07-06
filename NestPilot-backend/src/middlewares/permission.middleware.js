const db = require('../models');
const ApiError = require('../utils/ApiError');

let _superAdminRoleId = null;

const getSuperAdminRoleId = async () => {
    if (!_superAdminRoleId) {
        const role = await db.Role.findOne({ where: { code: 'SUPER_ADMIN' } });
        _superAdminRoleId = role ? role.id : null;
    }
    return _superAdminRoleId;
};

/**
 * Resolve an action against a permission row.
 * 'view'   → can_view OR can_manage (manage implies view)
 * 'manage' → can_manage (legacy 'create'/'update'/'delete'/'approve' map here too)
 */
const allows = (perm, action) => {
    if (!perm) return false;
    if (action === 'view') return !!(perm.can_view || perm.can_manage);
    return !!perm.can_manage;
};

/**
 * Check a single module permission.
 * action: 'view' | 'manage'
 *
 * Usage: router.get('/', auth, hasPermission('NOTICES', 'view'), controller.list)
 */
const hasPermission = (moduleCode, action) => {
    return async (req, res, next) => {
        try {
            if (!req.user || !req.user.role_id) {
                return next(new ApiError(403, 'Forbidden'));
            }

            const saId = await getSuperAdminRoleId();
            if (req.user.role_id === saId) return next();

            const module = await db.Module.findOne({ where: { code: moduleCode, is_active: true } });
            if (!module) return next(new ApiError(403, `Module '${moduleCode}' not found or inactive`));

            const perm = await db.RolePermission.findOne({
                where: { role_id: req.user.role_id, module_id: module.id }
            });

            if (!allows(perm, action)) {
                return next(new ApiError(403, `Forbidden: no '${action}' permission on ${moduleCode}`));
            }

            next();
        } catch (e) {
            next(e);
        }
    };
};

/**
 * Check multiple module+action pairs (OR logic — user passes if ANY match).
 *
 * Usage: hasAnyPermission([{ module: 'VISITORS', action: 'manage' }, { module: 'USERS', action: 'manage' }])
 */
const hasAnyPermission = (checks) => {
    return async (req, res, next) => {
        try {
            if (!req.user || !req.user.role_id) return next(new ApiError(403, 'Forbidden'));

            const saId = await getSuperAdminRoleId();
            if (req.user.role_id === saId) return next();

            for (const { module: moduleCode, action } of checks) {
                const module = await db.Module.findOne({ where: { code: moduleCode, is_active: true } });
                if (!module) continue;

                const perm = await db.RolePermission.findOne({
                    where: { role_id: req.user.role_id, module_id: module.id }
                });

                if (allows(perm, action)) return next();
            }

            return next(new ApiError(403, 'Forbidden: insufficient permissions'));
        } catch (e) {
            next(e);
        }
    };
};

/**
 * Attach the full permission map for the current user to req.userPermissions.
 * { NOTICES: { can_view, can_manage }, COMPLAINTS: { ... }, ... }
 * Useful for controllers that need to conditionally show/hide data.
 */
const attachPermissions = async (req, res, next) => {
    try {
        if (!req.user || !req.user.role_id) return next();

        const saId = await getSuperAdminRoleId();

        if (req.user.role_id === saId) {
            // SUPER_ADMIN gets everything
            const modules = await db.Module.findAll({ where: { is_active: true } });
            req.userPermissions = {};
            modules.forEach(m => {
                req.userPermissions[m.code] = { can_view: true, can_manage: true };
            });
            return next();
        }

        const perms = await db.RolePermission.findAll({
            where: { role_id: req.user.role_id },
            include: [{ model: db.Module, attributes: ['code'] }]
        });

        req.userPermissions = {};
        perms.forEach(p => {
            if (p.Module) {
                req.userPermissions[p.Module.code] = {
                    can_view: p.can_view || p.can_manage,
                    can_manage: p.can_manage
                };
            }
        });

        next();
    } catch (e) {
        next(e);
    }
};

module.exports = { hasPermission, hasAnyPermission, attachPermissions };
