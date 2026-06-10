import '../config/api_endpoints.dart';
import 'api_service.dart';

class SecretaryAdmin {
  final int id;
  final String fullName;
  final String? mobile;
  final int? societyId;
  final String? societyName;
  final List<AssignedBuilding> buildings;

  SecretaryAdmin({
    required this.id,
    required this.fullName,
    this.mobile,
    this.societyId,
    this.societyName,
    required this.buildings,
  });

  factory SecretaryAdmin.fromJson(Map<String, dynamic> json) {
    final society = json['Society'] as Map<String, dynamic>?;
    final buildings = (json['assignedBuildings'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AssignedBuilding.fromJson)
        .toList();
    return SecretaryAdmin(
      id: json['id'] as int,
      fullName: (json['full_name'] ?? '') as String,
      mobile: json['mobile'] as String?,
      societyId: json['society_id'] as int?,
      societyName: society?['name'] as String?,
      buildings: buildings,
    );
  }
}

class AssignedBuilding {
  final int id;
  final String name;
  final int? societyId;

  AssignedBuilding({required this.id, required this.name, this.societyId});

  factory AssignedBuilding.fromJson(Map<String, dynamic> json) =>
      AssignedBuilding(
        id: json['id'] as int,
        name: (json['name'] ?? '') as String,
        societyId: json['society_id'] as int?,
      );
}

class SecretaryBuildingService {
  final ApiService _api = ApiService();

  Future<List<SecretaryAdmin>> listSocietyAdmins({int? societyId}) async {
    final qs = societyId == null ? '' : '?society_id=$societyId';
    final res = await _api.get('${ApiEndpoints.societyAdmins}$qs');
    if (res['success'] != true) return [];
    return (res['data'] as List)
        .whereType<Map<String, dynamic>>()
        .map(SecretaryAdmin.fromJson)
        .toList();
  }

  Future<List<AssignedBuilding>> getAssignments(int userId) async {
    final res = await _api.get(ApiEndpoints.societyAdminBuildings(userId));
    if (res['success'] != true) return [];
    final data = res['data'] as Map<String, dynamic>?;
    final list = (data?['buildings'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AssignedBuilding.fromJson)
        .toList();
    return list;
  }

  Future<bool> setAssignments(int userId, List<int> buildingIds) async {
    final res = await _api.put(
      ApiEndpoints.societyAdminBuildings(userId),
      {'building_ids': buildingIds},
    );
    return res['success'] == true;
  }
}
