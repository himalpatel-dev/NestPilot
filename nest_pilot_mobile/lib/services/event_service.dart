import '../config/api_endpoints.dart';
import '../models/event_model.dart';
import 'api_service.dart';

class EventService {
  final ApiService _api = ApiService();

  Future<List<EventModel>> getEvents() async {
    final res = await _api.get(ApiEndpoints.events);
    if (res['success'] == true) {
      return (res['data'] as List)
          .map((e) => EventModel.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<EventModel> getEventDetail(String id) async {
    final res = await _api.get(ApiEndpoints.eventDetail(id));
    if (res['success'] == true) return EventModel.fromJson(res['data']);
    throw Exception(res['message'] ?? 'Failed to load event');
  }

  Future<EventModel> createEvent({
    required String title,
    required String description,
    required String eventDate,
    required String startTime,
    String? endTime,
    required String location,
    required String eventType,
    int? maxAttendees,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'description': description,
      'event_date': eventDate,
      'start_time': startTime,
      'location': location,
      'event_type': eventType,
    };
    if (endTime != null) body['end_time'] = endTime;
    if (maxAttendees != null) body['max_attendees'] = maxAttendees;
    final res = await _api.post(ApiEndpoints.events, body);
    if (res['success'] == true) return EventModel.fromJson(res['data']);
    throw Exception(res['message'] ?? 'Failed to create event');
  }

  Future<EventModel> updateEvent(String id, Map<String, dynamic> data) async {
    final res = await _api.patch(ApiEndpoints.eventDetail(id), data);
    if (res['success'] == true) return EventModel.fromJson(res['data']);
    throw Exception(res['message'] ?? 'Failed to update event');
  }

  Future<void> deleteEvent(String id) async {
    final res = await _api.delete(ApiEndpoints.eventDetail(id));
    if (res['success'] != true) {
      throw Exception(res['message'] ?? 'Failed to cancel event');
    }
  }

  Future<void> registerForEvent(String id) async {
    final res = await _api.post(ApiEndpoints.registerEvent(id), {});
    if (res['success'] != true) {
      throw Exception(res['message'] ?? 'Failed to register');
    }
  }

  Future<void> cancelRegistration(String id) async {
    final res = await _api.delete(ApiEndpoints.registerEvent(id));
    if (res['success'] != true) {
      throw Exception(res['message'] ?? 'Failed to cancel registration');
    }
  }
}
