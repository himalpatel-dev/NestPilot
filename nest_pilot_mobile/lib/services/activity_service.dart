import 'package:flutter/foundation.dart';
import '../config/api_endpoints.dart';
import '../models/activity_model.dart';
import 'api_service.dart';

class ActivityService {
  final ApiService _api = ApiService();

  Future<List<ActivityModel>> getRecent({int limit = 10}) async {
    final response = await _api.get(
      '${ApiEndpoints.recentActivity}?limit=$limit',
    );
    debugPrint('Activity raw response: $response');
    final list = (response['data'] as List?) ?? const [];
    final parsed = <ActivityModel>[];
    for (final e in list) {
      try {
        parsed.add(ActivityModel.fromJson(e as Map<String, dynamic>));
      } catch (err) {
        debugPrint('Activity parse error for $e :: $err');
      }
    }
    debugPrint('Activity parsed count: ${parsed.length}');
    return parsed;
  }
}
