import '../config/api_endpoints.dart';
import '../config/modules.dart';
import '../models/role_permission_model.dart';
import 'api_service.dart';

/// Singleton holding the logged-in user's effective module permissions.
/// Loaded once after login / on splash, then queried synchronously via [can].
class PermissionService {
  PermissionService._();
  static final PermissionService _instance = PermissionService._();
  factory PermissionService() => _instance;

  final ApiService _api = ApiService();

  final Map<String, ModulePermission> _byModule = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Fetches the current user's permissions and populates the cache.
  /// Safe to call multiple times — set [force] to refresh.
  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    final res = await _api.get(ApiEndpoints.myPermissions);
    final data = res['data'] as Map<String, dynamic>? ?? {};
    final perms = data['permissions'] as List? ?? [];
    _byModule
      ..clear()
      ..addEntries(perms.map((e) {
        final mp = ModulePermission.fromJson(e as Map<String, dynamic>);
        return MapEntry(mp.moduleCode, mp);
      }));
    _loaded = true;
  }

  /// Clear cached permissions (call on logout).
  void clear() {
    _byModule.clear();
    _loaded = false;
  }

  /// Check a permission. If the cache is empty (e.g. perms failed to load)
  /// this conservatively returns `false`.
  ///
  /// Example: `PermissionService().can(ModuleCodes.notices, PermAction.create)`
  bool can(String moduleCode, String action) {
    final p = _byModule[moduleCode];
    if (p == null) return false;
    switch (action) {
      case PermAction.view:    return p.canView;
      case PermAction.create:  return p.canCreate;
      case PermAction.update:  return p.canUpdate;
      case PermAction.delete:  return p.canDelete;
      case PermAction.approve: return p.canApprove;
      default: return false;
    }
  }

  bool canView(String moduleCode)    => can(moduleCode, PermAction.view);
  bool canCreate(String moduleCode)  => can(moduleCode, PermAction.create);
  bool canUpdate(String moduleCode)  => can(moduleCode, PermAction.update);
  bool canDelete(String moduleCode)  => can(moduleCode, PermAction.delete);
  bool canApprove(String moduleCode) => can(moduleCode, PermAction.approve);

  /// Has at least one of view/create/update/delete/approve on this module —
  /// useful for deciding whether to show a module entry in a menu at all.
  bool canAny(String moduleCode) {
    final p = _byModule[moduleCode];
    return p?.hasAny ?? false;
  }
}
