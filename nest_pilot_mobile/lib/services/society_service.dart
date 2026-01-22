import '../config/api_endpoints.dart';
import '../models/society_structure.dart';
import 'api_service.dart';

class SocietyService {
  final ApiService _apiService = ApiService();

  Future<List<Society>> getSocieties() async {
    final response = await _apiService.get(ApiEndpoints.societies);
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((s) => Society.fromJson(s))
          .toList();
    }
    return [];
  }

  Future<List<Building>> getBuildings(String societyId) async {
    final response = await _apiService.get(
      ApiEndpoints.societyBuildings(societyId),
    );
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((b) => Building.fromJson(b))
          .toList();
    }
    return [];
  }

  Future<List<Flat>> getFlats(String buildingId) async {
    final response = await _apiService.get(
      ApiEndpoints.buildingFlats(buildingId),
    );
    if (response['success'] == true) {
      return (response['data'] as List).map((f) => Flat.fromJson(f)).toList();
    }
    return [];
  }

  Future<bool> createSociety({
    required String name,
    required String address,
    required String city,
    required String state,
    required String pincode,
    String societyType = 'APARTMENT',
  }) async {
    final response = await _apiService.post(ApiEndpoints.societies, {
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'society_type': societyType,
    });
    return response['success'] ?? false;
  }

  Future<bool> createBuilding(String societyId, String name) async {
    final response = await _apiService.post(
      ApiEndpoints.societyBuildings(societyId),
      {'name': name},
    );
    return response['success'] ?? false;
  }

  Future<bool> createFlat(
    String buildingId,
    String number,
    String? floor,
  ) async {
    final response = await _apiService.post(
      ApiEndpoints.buildingFlats(buildingId),
      {'number': number, 'floor': floor},
    );
    return response['success'] ?? false;
  }
}
