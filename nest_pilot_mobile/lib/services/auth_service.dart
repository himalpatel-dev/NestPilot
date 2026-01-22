import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_endpoints.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<bool> requestOtp(String mobile, String purpose) async {
    final response = await _apiService.post(ApiEndpoints.requestOtp, {
      'mobile': mobile,
      'purpose': purpose,
    });
    return response['success'] ?? false;
  }

  Future<UserModel?> verifyOtp(String mobile, String otp) async {
    final response = await _apiService.post(ApiEndpoints.verifyOtp, {
      'mobile': mobile,
      'otp': otp,
    });

    if (response['success'] == true) {
      final token = response['data']['token'];
      final userJson = response['data']['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);

      return UserModel.fromJson(userJson);
    }
    return null;
  }

  Future<bool> register({
    required String fullName,
    required String mobile,
    required String societyId,
    required String buildingId,
    required String flatId,
    required String relationType,
    String? email,
  }) async {
    final response = await _apiService.post(ApiEndpoints.register, {
      'fullName': fullName,
      'mobile': mobile,
      'societyId': societyId,
      'buildingId': buildingId,
      'flatId': flatId,
      'relationType': relationType,
      'email': email,
    });
    return response['success'] ?? false;
  }

  Future<UserModel?> getMe() async {
    try {
      final response = await _apiService.get(ApiEndpoints.me);
      if (response['success'] == true) {
        final userData = response['data']['user'] ?? response['data'];
        return UserModel.fromJson(userData);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }
}
