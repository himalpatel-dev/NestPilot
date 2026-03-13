import '../models/notification_model.dart';
import '../config/api_endpoints.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _api = ApiService();

  Future<NotificationResponse> getNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _api.get(
      '${ApiEndpoints.notifications}?limit=$limit&offset=$offset',
    );
    return NotificationResponse.fromJson(response['data']);
  }

  Future<void> markAsRead(String id) async {
    final endpoint = id == 'all'
        ? '${ApiEndpoints.notifications}/all/read'
        : ApiEndpoints.readNotification(id);
    await _api.put(endpoint, {});
  }
}

class NotificationResponse {
  final List<NotificationModel> notifications;
  final int count;
  final int unreadCount;

  NotificationResponse({
    required this.notifications,
    required this.count,
    required this.unreadCount,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      notifications: (json['notifications'] as List)
          .map((e) => NotificationModel.fromJson(e))
          .toList(),
      count: json['count'],
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}
