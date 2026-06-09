/// Module codes — must match backend `MODULES` in modulePermissionSeeder.js.
class ModuleCodes {
  static const String dashboard  = 'DASHBOARD';
  static const String notices    = 'NOTICES';
  static const String complaints = 'COMPLAINTS';
  static const String bills      = 'BILLS';
  static const String events     = 'EVENTS';
  static const String amenities  = 'AMENITIES';
  static const String visitors   = 'VISITORS';
  static const String staff      = 'STAFF';
  static const String polls      = 'POLLS';
  static const String documents  = 'DOCUMENTS';
  static const String vehicles   = 'VEHICLES';
  static const String users      = 'USERS';
  static const String buildings  = 'BUILDINGS';
  static const String reports    = 'REPORTS';
  static const String roles      = 'ROLES';
}

/// Actions — match the `can_<action>` boolean columns on RolePermission.
class PermAction {
  static const String view    = 'view';
  static const String create  = 'create';
  static const String update  = 'update';
  static const String delete  = 'delete';
  static const String approve = 'approve';
}
