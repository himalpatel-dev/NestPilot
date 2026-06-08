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
 * Check a single module permission.
 * action: 'view' | 'create' | 'update' | 'delete' | 'approve'
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

            if (!perm || !perm[`can_${action}`]) {
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
 * Usage: hasAnyPermission([{ module: 'VISITORS', action: 'approve' }, { module: 'USERS', action: 'approve' }])
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

                if (perm && perm[`can_${action}`]) return next();
            }

            return next(new ApiError(403, 'Forbidden: insufficient permissions'));
        } catch (e) {
            next(e);
        }
    };
};

/**
 * Attach the full permission map for the current user to req.userPermissions.
 * { NOTICES: { can_view, can_create, ... }, COMPLAINTS: { ... }, ... }
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
                req.userPermissions[m.code] = {
                    can_view: true, can_create: true, can_update: true,
                    can_delete: true, can_approve: true
                };
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
                    can_view: p.can_view,
                    can_create: p.can_create,
                    can_update: p.can_update,
                    can_delete: p.can_delete,
                    can_approve: p.can_approve
                };
            }
        });

        next();
    } catch (e) {
        next(e);
    }
};

module.exports = { hasPermission, hasAnyPermission, attachPermissions };
