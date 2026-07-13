import '../config/api_endpoints.dart';
import '../models/location_model.dart';
import 'api_service.dart';

class LocationService {
  final ApiService _apiService = ApiService();

  Future<List<StateModel>> getStates() async {
    final response = await _apiService.get(ApiEndpoints.states);
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((s) => StateModel.fromJson(s as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<DistrictModel>> getDistricts(int stateId) async {
    final response = await _apiService.get(
      ApiEndpoints.stateDistricts(stateId),
    );
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((d) => DistrictModel.fromJson(d as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
