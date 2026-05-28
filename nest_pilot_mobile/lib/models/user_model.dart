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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle nested Role object if present
    String roleCode = '';
    if (json['Role'] != null && json['Role']['code'] != null) {
      roleCode = json['Role']['code'].toString();
    } else {
      roleCode = (json['role'] ?? json['role_code'] ?? '').toString();
    }

    String? flatNum = json['flatNumber'] ?? json['flat_number'];
    if (flatNum == null) {
      final houses = json['Houses'] ?? json['houses'];
      if (houses != null && (houses as List).isNotEmpty) {
        flatNum = houses[0]['house_no']?.toString();
      }
    }
    if (flatNum == null) {
      final mappings = json['UserHouseMappings'] ?? json['user_house_mappings'];
      if (mappings != null && (mappings as List).isNotEmpty) {
        final house = mappings[0]['House'] ?? mappings[0]['house'];
        if (house != null) {
          flatNum = house['house_no']?.toString();
        }
      }
    }

    String? socName = json['societyName'] ?? json['society_name'];
    if (socName == null) {
      final soc = json['Society'] ?? json['society'];
      if (soc != null) {
        socName = soc['name']?.toString();
      }
    }

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
      relationType: json['relationType'] ?? json['relation_type'],
      flatNumber: flatNum,
      societyName: socName,
    );
  }

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
    };
  }
}
