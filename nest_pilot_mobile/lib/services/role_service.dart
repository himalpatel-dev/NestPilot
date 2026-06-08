import '../config/api_endpoints.dart';
import '../models/role_permission_model.dart';
import 'api_service.dart';

class RoleService {
  final ApiService _api = ApiService();

  Future<List<RoleModel>> getRoles() async {
    final res = await _api.get(ApiEndpoints.roles);
    final data = res['data'] as List? ?? [];
    return data.map((e) => RoleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Returns { 'SUPER_ADMIN': 'SUPER_ADMIN', 'MEMBER': 'MEMBER', ... }
  Future<Map<String, String>> getRolesEnum() async {
    final res = await _api.get(ApiEndpoints.rolesEnum);
    final data = res['data'] as Map<String, dynamic>? ?? {};
    final enumData = data['enum'] as Map<String, dynamic>? ?? {};
    return enumData.map((k, v) => MapEntry(k, v as String));
  }

  Future<List<ModuleModel>> getModules() async {
    final res = await _api.get(ApiEndpoints.modules);
    final data = res['data'] as List? ?? [];
    return data.map((e) => ModuleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RoleModel> createRole({
    required String code,
    required String name,
    String? description,
    List<Map<String, dynamic>>? permissions,
  }) async {
    final body = <String, dynamic>{
      'code': code,
      'name': name,
      'description': (description?.isNotEmpty ?? false) ? description : null,
      'permissions': permissions,
    };
    final res = await _api.post(ApiEndpoints.roles, body);
    return RoleModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> updateRole(
    int id, {
    String? name,
    String? description,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'description': description,
      'is_active': isActive,
    };
    await _api.put(ApiEndpoints.roleById(id), body);
  }

  Future<void> deleteRole(int id) async {
    await _api.delete(ApiEndpoints.roleById(id));
  }

  Future<List<ModulePermission>> getRolePermissions(int roleId) async {
    final res = await _api.get(ApiEndpoints.rolePermissions(roleId));
    final data = res['data'] as Map<String, dynamic>? ?? {};
    final perms = data['permissions'] as List? ?? [];
    return perms
        .map((e) => ModulePermission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateRolePermissions(
    int roleId,
    List<ModulePermission> permissions,
  ) async {
    await _api.put(
      ApiEndpoints.rolePermissions(roleId),
      {'permissions': permissions.map((p) => p.toJson()).toList()},
    );
  }
}
