class UserModel {
  final String id;
  final String fullName;
  final String mobile;
  final String? email;
  final String role;
  final String status;
  final String? societyId;
  final String? buildingId;
  final String? flatId;
  final String? relationType;
  final String? flatNumber;
  final String? societyName;
  final String? societyCity;
  final String? buildingName;

  /// Buildings a Society Admin manages — only sent by /auth/me.
  final List<String> managedBuildings;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.mobile,
    this.email,
    required this.role,
    required this.status,
    this.societyId,
    this.buildingId,
    this.flatId,
    this.relationType,
    this.flatNumber,
    this.societyName,
    this.societyCity,
    this.buildingName,
    this.managedBuildings = const [],
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle nested Role object if present
    String roleCode = '';
    if (json['Role'] != null && json['Role']['code'] != null) {
      roleCode = json['Role']['code'].toString();
    } else {
      roleCode = (json['role'] ?? json['role_code'] ?? '').toString();
    }

    // Current flat: /auth/me nests it as Houses (with the mapping's
    // relation_type inside); other endpoints send UserHouseMappings → House.
    dynamic house;
    dynamic mapping;
    final houses = json['Houses'] ?? json['houses'];
    if (houses is List && houses.isNotEmpty) {
      house = houses[0];
      mapping = house['UserHouseMapping'];
    } else {
      final mappings = json['UserHouseMappings'] ?? json['user_house_mappings'];
      if (mappings is List && mappings.isNotEmpty) {
        mapping = mappings[0];
        house = mapping['House'] ?? mapping['house'];
      }
    }

    final soc = json['Society'] ?? json['society'];

    return UserModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'],
      role: roleCode.trim().toUpperCase(),
      status: (json['status'] ?? '').toString().toUpperCase(),
      societyId: (json['societyId'] ?? json['society_id'])?.toString(),
      buildingId: (json['buildingId'] ?? json['building_id'])?.toString(),
      flatId: (json['flatId'] ?? json['flat_id'])?.toString(),
      relationType:
          json['relationType'] ??
          json['relation_type'] ??
          mapping?['relation_type'],
      flatNumber:
          json['flatNumber'] ??
          json['flat_number'] ??
          house?['house_no']?.toString(),
      societyName:
          json['societyName'] ??
          json['society_name'] ??
          soc?['name']?.toString(),
      societyCity: json['societyCity'] ?? soc?['city']?.toString(),
      buildingName:
          json['buildingName'] ?? house?['Building']?['name']?.toString(),
      managedBuildings: _buildingNames(
        json['assignedBuildings'] ?? json['managedBuildings'],
      ),
      createdAt: DateTime.tryParse(
        (json['createdAt'] ?? json['created_at'] ?? '').toString(),
      ),
    );
  }

  // /auth/me sends assignedBuildings as {id, name} objects; toJson() writes
  // plain names.
  static List<String> _buildingNames(dynamic list) => [
    if (list is List)
      for (final b in list)
        if (b is Map && b['name'] != null)
          b['name'].toString()
        else if (b is String)
          b,
  ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'mobile': mobile,
      'email': email,
      'role': role,
      'status': status,
      'societyId': societyId,
      'buildingId': buildingId,
      'flatId': flatId,
      'relationType': relationType,
      'flatNumber': flatNumber,
      'societyName': societyName,
      'societyCity': societyCity,
      'buildingName': buildingName,
      'managedBuildings': managedBuildings,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
