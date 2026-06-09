const db = require('../models');
const ApiError = require('../utils/ApiError');
const ApiResponse = require('../utils/ApiResponse');

const getAllRoles = async (req, res, next) => {
    try {
        const roles = await db.Role.findAll({
            where: { is_active: true },
            order: [['id', 'ASC']]
        });
        res.json(new ApiResponse(200, roles));
    } catch (e) { next(e); }
};

/**
 * Returns roles as a key→value enum object so the frontend can do:
 *   const ROLES = data.enum  =>  { SUPER_ADMIN: 'SUPER_ADMIN', MEMBER: 'MEMBER', ... }
 */
const getRolesEnum = async (req, res, next) => {
    try {
        const roles = await db.Role.findAll({
            where: { is_active: true },
            attributes: ['id', 'code', 'name', 'description', 'is_system'],
            order: [['id', 'ASC']]
        });

        const enumObj = {};
        roles.forEach(r => { enumObj[r.code] = r.code; });

        res.json(new ApiResponse(200, { enum: enumObj, list: roles }));
    } catch (e) { next(e); }
};

const getModules = async (req, res, next) => {
    try {
        const modules = await db.Module.findAll({
            where: { is_active: true },
            order: [['sort_order', 'ASC']]
        });
        res.json(new ApiResponse(200, modules));
    } catch (e) { next(e); }
};

const createRole = async (req, res, next) => {
    try {
        const { code, name, description, permissions } = req.body;

        if (!code || !name) throw new ApiError(400, 'code and name are required');

        const codeUpper = String(code).toUpperCase().replace(/\s+/g, '_');

        const existing = await db.Role.findOne({ where: { code: codeUpper } });
        if (existing) throw new ApiError(409, `Role '${codeUpper}' already exists`);

        const role = await db.Role.create({
            code: codeUpper,
            name,
            description: description || null,
            is_system: false,
            is_active: true
        });

        const modules = await db.Module.findAll({ where: { is_active: true } });

        if (permissions && Array.isArray(permissions)) {
            // Build a map: module_code → perms
            const permMap = {};
            permissions.forEach(p => { permMap[p.module_code] = p; });

            for (const mod of modules) {
                const p = permMap[mod.code] || {};
                await db.RolePermission.create({
                    role_id: role.id,
                    module_id: mod.id,
                    can_view: p.can_view || false,
                    can_create: p.can_create || false,
                    can_update: p.can_update || false,
                    can_delete: p.can_delete || false,
                    can_approve: p.can_approve || false,
                });
            }
        } else {
            // Default: no permissions
            for (const mod of modules) {
                await db.RolePermission.create({
                    role_id: role.id,
                    module_id: mod.id,
                    can_view: false, can_create: false,
                    can_update: false, can_delete: false, can_approve: false,
                });
            }
        }

        res.status(201).json(new ApiResponse(201, role, 'Role created successfully'));
    } catch (e) { next(e); }
};

const updateRole = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { name, description, is_active } = req.body;

        const role = await db.Role.findByPk(id);
        if (!role) throw new ApiError(404, 'Role not found');
        if (role.is_system) throw new ApiError(403, 'System roles cannot be renamed or deactivated');

        if (name !== undefined) role.name = name;
        if (description !== undefined) role.description = description;
        if (is_active !== undefined) role.is_active = is_active;

        await role.save();
        res.json(new ApiResponse(200, role, 'Role updated'));
    } catch (e) { next(e); }
};

const deleteRole = async (req, res, next) => {
    try {
        const { id } = req.params;
        const role = await db.Role.findByPk(id);
        if (!role) throw new ApiError(404, 'Role not found');
        if (role.is_system) throw new ApiError(403, 'System roles cannot be deleted');

        const usersWithRole = await db.User.count({ where: { role_id: id } });
        if (usersWithRole > 0) throw new ApiError(400, `Cannot delete: ${usersWithRole} user(s) assigned to this role`);

        await db.RolePermission.destroy({ where: { role_id: id } });
        await role.destroy();

        res.json(new ApiResponse(200, null, 'Role deleted'));
    } catch (e) { next(e); }
};

const getRolePermissions = async (req, res, next) => {
    try {
        const { id } = req.params;

        const role = await db.Role.findByPk(id);
        if (!role) throw new ApiError(404, 'Role not found');

        const modules = await db.Module.findAll({
            where: { is_active: true },
            order: [['sort_order', 'ASC']],
            include: [{
                model: db.RolePermission,
                as: 'permissions',
                where: { role_id: id },
                required: false
            }]
        });

        const result = modules.map(mod => {
            const perm = mod.permissions && mod.permissions[0];
            return {
                module_id: mod.id,
                module_code: mod.code,
                module_name: mod.name,
                sort_order: mod.sort_order,
                can_view: perm ? perm.can_view : false,
                can_create: perm ? perm.can_create : false,
                can_update: perm ? perm.can_update : false,
                can_delete: perm ? perm.can_delete : false,
                can_approve: perm ? perm.can_approve : false,
            };
        });

        res.json(new ApiResponse(200, { role, permissions: result }));
    } catch (e) { next(e); }
};

/**
 * Bulk update/replace permissions for a role.
 * Body: { permissions: [{ module_id, can_view, can_create, can_update, can_delete, can_approve }, ...] }
 */
const updateRolePermissions = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { permissions } = req.body;

        const role = await db.Role.findByPk(id);
        if (!role) throw new ApiError(404, 'Role not found');
        if (!Array.isArray(permissions)) throw new ApiError(400, 'permissions must be an array');

        for (const p of permissions) {
            await db.RolePermission.upsert({
                role_id: parseInt(id),
                module_id: p.module_id,
                can_view: p.can_view || false,
                can_create: p.can_create || false,
                can_update: p.can_update || false,
                can_delete: p.can_delete || false,
                can_approve: p.can_approve || false,
            });
        }

        res.json(new ApiResponse(200, null, 'Permissions updated successfully'));
    } catch (e) { next(e); }
};

/**
 * Returns the effective permission map for the currently logged-in user.
 * SUPER_ADMIN gets full access on every active module.
 * Shape: { permissions: [{ module_code, module_name, sort_order, can_view, can_create, can_update, can_delete, can_approve }, ...] }
 */
const getMyPermissions = async (req, res, next) => {
    try {
        if (!req.user || !req.user.role_id) throw new ApiError(401, 'Unauthorized');

        const superAdminRole = await db.Role.findOne({ where: { code: 'SUPER_ADMIN' } });
        const isSuperAdmin = superAdminRole && req.user.role_id === superAdminRole.id;

        const modules = await db.Module.findAll({
            where: { is_active: true },
            order: [['sort_order', 'ASC']],
        });

        let permByModuleId = {};
        if (!isSuperAdmin) {
            const perms = await db.RolePermission.findAll({
                where: { role_id: req.user.role_id },
            });
            perms.forEach(p => { permByModuleId[p.module_id] = p; });
        }

        const result = modules.map(mod => {
            if (isSuperAdmin) {
                return {
                    module_id: mod.id,
                    module_code: mod.code,
                    module_name: mod.name,
                    sort_order: mod.sort_order,
                    can_view: true, can_create: true, can_update: true,
                    can_delete: true, can_approve: true,
                };
            }
            const p = permByModuleId[mod.id];
            return {
                module_id: mod.id,
                module_code: mod.code,
                module_name: mod.name,
                sort_order: mod.sort_order,
                can_view: p ? p.can_view : false,
                can_create: p ? p.can_create : false,
                can_update: p ? p.can_update : false,
                can_delete: p ? p.can_delete : false,
                can_approve: p ? p.can_approve : false,
            };
        });

        res.json(new ApiResponse(200, { permissions: result }));
    } catch (e) { next(e); }
};

module.exports = {
    getAllRoles,
    getRolesEnum,
    getModules,
    createRole,
    updateRole,
    deleteRole,
    getRolePermissions,
    updateRolePermissions,
    getMyPermissions,
};
