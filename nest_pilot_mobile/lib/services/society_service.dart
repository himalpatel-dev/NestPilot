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

  Future<bool> createBuilding({
    required String societyId,
    required String name,
    String? blocks,
    String? wings,
    int floorsCount = 0,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.societyBuildings(societyId),
      {
        'name': name,
        'blocks': blocks,
        'wings': wings,
        'floors_count': floorsCount,
      },
    );
    return response['success'] ?? false;
  }

  Future<bool> updateSociety({
    required String id,
    required String name,
    required String address,
    required String city,
    required String state,
    required String pincode,
    String societyType = 'APARTMENT',
  }) async {
    final response = await _apiService.put(ApiEndpoints.societyById(id), {
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'society_type': societyType,
    });
    return response['success'] ?? false;
  }

  Future<bool> updateBuilding({
    required String id,
    required String name,
    String? blocks,
    String? wings,
    int floorsCount = 0,
  }) async {
    final response = await _apiService.put(ApiEndpoints.buildingById(id), {
      'name': name,
      'blocks': blocks,
      'wings': wings,
      'floors_count': floorsCount,
    });
    return response['success'] ?? false;
  }

  Future<HouseStats?> getHouseStats() async {
    final response = await _apiService.get(ApiEndpoints.houseStats);
    if (response['success'] == true && response['data'] != null) {
      return HouseStats.fromJson(response['data'] as Map<String, dynamic>);
    }
    return null;
  }

  Future<bool> createFlat({
    required String buildingId,
    required String number,
    int? floor,
    String? wing,
    String unitType = 'FLAT',
    double? areaSqft,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.buildingFlats(buildingId),
      {
        'house_no': number,
        'floor_no': floor ?? 0,
        'wing': wing,
        'unit_type': unitType,
        'area_sqft': areaSqft,
      },
    );
    return response['success'] ?? false;
  }

  Future<bool> updateFlat({
    required String id,
    required String buildingId,
    required String number,
    int? floor,
    String? wing,
    String unitType = 'FLAT',
    double? areaSqft,
  }) async {
    final response = await _apiService.put(
      ApiEndpoints.flatById(buildingId, id),
      {
        'house_no': number,
        'floor_no': floor ?? 0,
        'wing': wing,
        'unit_type': unitType,
        'area_sqft': areaSqft,
      },
    );
    return response['success'] ?? false;
  }
}
