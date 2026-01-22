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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle nested Role object if present
    String roleCode = '';
    if (json['Role'] != null && json['Role']['code'] != null) {
      roleCode = json['Role']['code'].toString();
    } else {
      roleCode = (json['role'] ?? json['role_code'] ?? '').toString();
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
      flatNumber: json['flatNumber'] ?? json['flat_number'],
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
    };
  }
}
