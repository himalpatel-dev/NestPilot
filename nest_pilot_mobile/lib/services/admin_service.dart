import '../config/api_endpoints.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AdminService {
  final ApiService _apiService = ApiService();

  Future<List<UserModel>> getPendingUsers() async {
    final response = await _apiService.get(ApiEndpoints.pendingUsers);
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((u) => UserModel.fromJson(u))
          .toList();
    }
    return [];
  }

  Future<List<UserModel>> getSocietyMembers() async {
    final response = await _apiService.get(ApiEndpoints.societyMembers);
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((u) => UserModel.fromJson(u))
          .toList();
    }
    return [];
  }

  Future<bool> approveUser(String id) async {
    final response = await _apiService.post(ApiEndpoints.approveUser(id), {});
    return response['success'] ?? false;
  }

  Future<bool> rejectUser(String id) async {
    final response = await _apiService.post(ApiEndpoints.rejectUser(id), {});
    return response['success'] ?? false;
  }
}
