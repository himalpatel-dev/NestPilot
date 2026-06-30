import '../config/api_endpoints.dart';
import '../models/service_staff_model.dart';
import 'api_service.dart';

class StaffService {
  final ApiService _api = ApiService();

  Future<List<ServiceStaffModel>> getAll() async {
    final res = await _api.get(ApiEndpoints.staff);
    if (res['success'] == true) {
      return (res['data'] as List).map((e) => ServiceStaffModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<ServiceStaffModel> add({
    required String name,
    required String role,
    required String mobile,
    String? aadhaarNumber,
  }) async {
    final body = <String, dynamic>{'name': name, 'role': role, 'mobile': mobile};
    if (aadhaarNumber != null && aadhaarNumber.isNotEmpty) body['aadhaar_number'] = aadhaarNumber;
    final res = await _api.post(ApiEndpoints.staff, body);
    if (res['success'] == true) return ServiceStaffModel.fromJson(res['data']);
    throw Exception(res['message'] ?? 'Failed to add staff');
  }

  Future<ServiceStaffModel> update(int id, {
    required String name,
    required String role,
    required String mobile,
    String? aadhaarNumber,
  }) async {
    final body = <String, dynamic>{'name': name, 'role': role, 'mobile': mobile};
    if (aadhaarNumber != null && aadhaarNumber.isNotEmpty) body['aadhaar_number'] = aadhaarNumber;
    final res = await _api.patch(ApiEndpoints.staffById(id), body);
    if (res['success'] == true) return ServiceStaffModel.fromJson(res['data']);
    throw Exception(res['message'] ?? 'Failed to update staff');
  }
}
