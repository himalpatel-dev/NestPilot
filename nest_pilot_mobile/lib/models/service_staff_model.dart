class ServiceStaffModel {
  final int id;
  final String name;
  final String role;
  final String mobile;
  final String? aadhaarNumber;
  final String? profileImage;
  final bool isActive;

  ServiceStaffModel({
    required this.id,
    required this.name,
    required this.role,
    required this.mobile,
    this.aadhaarNumber,
    this.profileImage,
    required this.isActive,
  });

  factory ServiceStaffModel.fromJson(Map<String, dynamic> json) {
    return ServiceStaffModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] ?? '',
      role: json['role'] ?? 'OTHER',
      mobile: json['mobile'] ?? '',
      aadhaarNumber: json['aadhaar_number'],
      profileImage: json['profile_image'],
      isActive: json['is_active'] ?? true,
    );
  }
}
