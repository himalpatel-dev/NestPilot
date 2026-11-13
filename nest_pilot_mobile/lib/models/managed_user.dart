import '../config/roles.dart';
import '../services/secretary_building_service.dart' show AssignedBuilding;

/// Any user as seen by the Super Admin's User Management screen — every role,
/// every society — with the role, society and flat context needed to manage
/// them. [status] stays lower-case, exactly as the API sends and expects it.
class ManagedUser {
  final int id;
  final String fullName;
  final String mobile;
  final String? email;
  final String status;
  final int? roleId;
  final String roleCode;
  final String roleName;
  final int? societyId;
  final String? societyName;
  final int? houseId;
  final String? houseNo;
  final String? wing;
  final int? buildingId;
  final String? buildingName;
  final String? relationType;

  /// Only filled by the single-user endpoint (Society Admins' buildings).
  final List<AssignedBuilding> assignedBuildings;
  final DateTime? createdAt;

  const ManagedUser({
    required this.id,
    required this.fullName,
    required this.mobile,
    this.email,
    required this.status,
    this.roleId,
    required this.roleCode,
    required this.roleName,
    this.societyId,
    this.societyName,
    this.houseId,
    this.houseNo,
    this.wing,
    this.buildingId,
    this.buildingName,
    this.relationType,
    this.assignedBuildings = const [],
    this.createdAt,
  });

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    final role = json['Role'] as Map<String, dynamic>?;
    final society = json['Society'] as Map<String, dynamic>?;
    // The API sends the current flat first (primary, then most recent).
    final mappings = (json['UserHouseMappings'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final mapping = mappings.isEmpty ? null : mappings.first;
    final house = mapping?['House'] as Map<String, dynamic>?;
    final building = house?['Building'] as Map<String, dynamic>?;
    final email = json['email']?.toString().trim();

    return ManagedUser(
      id: _toInt(json['id']) ?? 0,
      fullName: (json['full_name'] ?? '').toString(),
      mobile: (json['mobile'] ?? '').toString(),
      email: (email == null || email.isEmpty) ? null : email,
      status: (json['status'] ?? 'pending').toString().toLowerCase(),
      roleId: _toInt(role?['id'] ?? json['role_id']),
      roleCode: (role?['code'] ?? '').toString().toUpperCase(),
      roleName: (role?['name'] ?? '').toString(),
      societyId: _toInt(society?['id'] ?? json['society_id']),
      societyName: society?['name']?.toString(),
      houseId: _toInt(house?['id'] ?? mapping?['house_id']),
      houseNo: house?['house_no']?.toString(),
      wing: house?['wing']?.toString(),
      buildingId: _toInt(building?['id'] ?? house?['building_id']),
      buildingName: building?['name']?.toString(),
      relationType: mapping?['relation_type']?.toString(),
      assignedBuildings: (json['assignedBuildings'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AssignedBuilding.fromJson)
          .toList(),
      createdAt: DateTime.tryParse(
        (json['createdAt'] ?? json['created_at'] ?? '').toString(),
      ),
    );
  }

  static int? _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '');

  bool get isSuperAdmin => roleCode == UserRoles.superAdmin;
  bool get isSocietyAdmin => roleCode == UserRoles.societyAdmin;
  bool get isMember => roleCode == UserRoles.member;

  /// Role name for display, falling back to the code for unnamed roles.
  String get roleLabel => roleName.isNotEmpty ? roleName : roleCode;

  /// "A-101" style label, or null when the user has no current flat.
  String? get flatLabel {
    if (houseNo == null || houseNo!.isEmpty) return null;
    return (wing ?? '').isNotEmpty ? '$wing-$houseNo' : houseNo;
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

/// One page of the user directory.
class UserPage {
  final List<ManagedUser> items;
  final int total;
  final bool hasMore;

  const UserPage({
    required this.items,
    required this.total,
    required this.hasMore,
  });
}

/// Account counts by status for the User Management header.
class UserStats {
  final int total;
  final int active;
  final int pending;
  final int blocked;
  final int rejected;

  const UserStats({
    this.total = 0,
    this.active = 0,
    this.pending = 0,
    this.blocked = 0,
    this.rejected = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) =>
        v is int ? v : (int.tryParse(v?.toString() ?? '0') ?? 0);
    return UserStats(
      total: toInt(json['total']),
      active: toInt(json['active']),
      pending: toInt(json['pending']),
      blocked: toInt(json['blocked']),
      rejected: toInt(json['rejected']),
    );
  }

  int countFor(String status) {
    switch (status) {
      case 'active':
        return active;
      case 'pending':
        return pending;
      case 'blocked':
        return blocked;
      case 'rejected':
        return rejected;
      default:
        return total;
    }
  }
}
