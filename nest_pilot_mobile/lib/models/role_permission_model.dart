class RoleModel {
  final int id;
  final String code;
  final String name;
  final String? description;
  final bool isSystem;
  final bool isActive;

  const RoleModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.isSystem,
    required this.isActive,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isSystem: json['is_system'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'description': description,
        'is_system': isSystem,
        'is_active': isActive,
      };
}

class ModuleModel {
  final int id;
  final String code;
  final String name;
  final String? description;
  final int sortOrder;
  final bool isActive;

  const ModuleModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.sortOrder,
    required this.isActive,
  });

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    return ModuleModel(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class ModulePermission {
  final int moduleId;
  final String moduleCode;
  final String moduleName;
  final int sortOrder;
  bool canView;

  /// Single flag covering add / edit / delete / approve.
  bool canManage;

  ModulePermission({
    required this.moduleId,
    required this.moduleCode,
    required this.moduleName,
    required this.sortOrder,
    required this.canView,
    required this.canManage,
  });

  factory ModulePermission.fromJson(Map<String, dynamic> json) {
    return ModulePermission(
      moduleId: json['module_id'] as int,
      moduleCode: json['module_code'] as String,
      moduleName: json['module_name'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
      canView: json['can_view'] as bool? ?? false,
      canManage: json['can_manage'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'module_id': moduleId,
        'can_view': canView,
        'can_manage': canManage,
      };

  bool get hasAny => canView || canManage;
  bool get hasAll => canView && canManage;
}
