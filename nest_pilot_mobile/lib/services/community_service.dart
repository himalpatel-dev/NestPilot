// import 'dart:convert';
import 'package:nest_pilot_mobile/models/community_models.dart';
import 'package:nest_pilot_mobile/services/api_service.dart';
import '../config/api_endpoints.dart';

class CommunityService {
  final ApiService _apiService = ApiService();

  // --- Vehicles ---
  Future<List<Vehicle>> getMyVehicles() async {
    final response = await _apiService.get(ApiEndpoints.vehicles);
    if (response['success']) {
      return (response['data'] as List)
          .map((i) => Vehicle.fromJson(i))
          .toList();
    }
    throw Exception(response['message']);
  }

  Future<void> addVehicle(Map<String, dynamic> data) async {
    final response = await _apiService.post(ApiEndpoints.vehicles, data);
    if (!response['success']) {
      throw Exception(response['message']);
    }
  }

  Future<void> deleteVehicle(int id) async {
    final response = await _apiService.delete(ApiEndpoints.deleteVehicle(id));
    if (!response['success']) {
      throw Exception(response['message']);
    }
  }

  Future<List<Vehicle>> getAllVehicles() async {
    final response = await _apiService.get(ApiEndpoints.allVehicles);
    if (response['success']) {
      return (response['data'] as List)
          .map((i) => Vehicle.fromJson(i))
          .toList();
    }
    throw Exception(response['message']);
  }

  // --- Visitors ---
  Future<List<VisitorLog>> getMyVisitors() async {
    final response = await _apiService.get(ApiEndpoints.myVisitors);
    if (response['success']) {
      return (response['data'] as List)
          .map((i) => VisitorLog.fromJson(i))
          .toList();
    }
    throw Exception(response['message']);
  }

  Future<Map<String, dynamic>> inviteGuest(Map<String, dynamic> data) async {
    final response = await _apiService.post(ApiEndpoints.inviteVisitor, data);
    if (response['success']) {
      return response['data'];
    }
    throw Exception(response['message']);
  }

  // --- Amenities ---
  Future<List<Amenity>> getAllAmenities() async {
    final response = await _apiService.get(ApiEndpoints.amenities);
    if (response['success']) {
      return (response['data'] as List)
          .map((i) => Amenity.fromJson(i))
          .toList();
    }
    throw Exception(response['message']);
  }

  Future<void> createAmenity(Map<String, dynamic> data) async {
    final response = await _apiService.post(ApiEndpoints.amenities, data);
    if (!response['success']) {
      throw Exception(response['message']);
    }
  }

  Future<List<Booking>> getAllBookings() async {
    final response = await _apiService.get(ApiEndpoints.allBookings);
    if (response['success']) {
      return (response['data'] as List)
          .map((i) => Booking.fromJson(i))
          .toList();
    }
    throw Exception(response['message']);
  }

  Future<void> updateBookingStatus(int id, String status) async {
    final response = await _apiService.put(
      ApiEndpoints.updateBookingStatus(id),
      {'status': status},
    );
    if (!response['success']) {
      throw Exception(response['message']);
    }
  }

  Future<List<Booking>> getMyBookings() async {
    final response = await _apiService.get(ApiEndpoints.myAmenityBookings);
    if (response['success']) {
      return (response['data'] as List)
          .map((i) => Booking.fromJson(i))
          .toList();
    }
    throw Exception(response['message']);
  }

  Future<void> bookAmenity(Map<String, dynamic> data) async {
    final response = await _apiService.post(ApiEndpoints.bookAmenity, data);
    if (!response['success']) {
      throw Exception(response['message']);
    }
  }

  // --- Staff ---
  Future<List<ServiceStaff>> getAllStaff() async {
    final response = await _apiService.get(ApiEndpoints.staff);
    if (response['success']) {
      return (response['data'] as List)
          .map((i) => ServiceStaff.fromJson(i))
          .toList();
    }
    throw Exception(response['message']);
  }

  Future<List<StaffAttendance>> getStaffAttendance(int staffId) async {
    final response = await _apiService.get(
      ApiEndpoints.staffAttendance(staffId),
    );
    if (response['success']) {
      return (response['data'] as List)
          .map((i) => StaffAttendance.fromJson(i))
          .toList();
    }
    throw Exception(response['message']);
  }

  Future<void> addStaff(Map<String, dynamic> data) async {
    final response = await _apiService.post(ApiEndpoints.staff, data);
    if (!response['success']) {
      throw Exception(response['message']);
    }
  }

  // --- Polls ---
  Future<List<Poll>> getActivePolls() async {
    final response = await _apiService.get(ApiEndpoints.polls);
    if (response['success']) {
      return (response['data'] as List).map((i) => Poll.fromJson(i)).toList();
    }
    throw Exception(response['message']);
  }

  Future<Map<String, dynamic>> getPollResults(int pollId) async {
    final response = await _apiService.get('/api/polls/$pollId/results');
    if (response['success']) {
      return response['data'];
    }
    throw Exception(response['message']);
  }

  Future<void> createPoll(Map<String, dynamic> data) async {
    final response = await _apiService.post(ApiEndpoints.polls, data);
    if (!response['success']) {
      throw Exception(response['message']);
    }
  }

  Future<void> votePoll(int pollId, int optionId) async {
    final response = await _apiService.post(ApiEndpoints.votePoll, {
      'poll_id': pollId,
      'option_id': optionId,
    });
    if (!response['success']) {
      throw Exception(response['message']);
    }
  }

  // --- Documents ---
  Future<List<Document>> getDocuments() async {
    final response = await _apiService.get(ApiEndpoints.documents);
    if (response['success']) {
      return (response['data'] as List)
          .map((i) => Document.fromJson(i))
          .toList();
    }
    throw Exception(response['message']);
  }

  Future<void> uploadDocument(
    Map<String, String> fields, {
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final response = await _apiService.multipartPost(
      ApiEndpoints.documents,
      fields,
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: fileName,
      fileKey: 'file',
    );
    if (!response['success']) {
      throw Exception(response['message']);
    }
  }

  Future<void> markStaffAttendance(int staffId, String type) async {
    final response = await _apiService.post(
      '${ApiEndpoints.staff}/attendance',
      {'staff_id': staffId, 'type': type},
    );
    if (!response['success']) {
      throw Exception(response['message']);
    }
  }

  Future<void> deleteDocument(int id) async {
    final response = await _apiService.delete('${ApiEndpoints.documents}/$id');
    if (!response['success']) {
      throw Exception(response['message']);
    }
  }

  Future<void> logVisitorEntry(Map<String, dynamic> data) async {
    // Note: Assuming /invite exists on /visitors route prefix, check endpoint
    // ApiEndpoints.visitors is '/api/visitors'.
    // The endpoint is /api/visitors/entry
    final response = await _apiService.post(
      '${ApiEndpoints.visitors}/entry',
      data,
    );
    if (!response['success']) {
      throw Exception(response['message']);
    }
  }

  Future<void> respondToVisitor(int logId, String status) async {
    final response = await _apiService.post(
      '${ApiEndpoints.visitors}/respond',
      {'log_id': logId, 'status': status},
    );
    if (!response['success']) {
      throw Exception(response['message']);
    }
  }

  Future<List<dynamic>> getInsideVisitors() async {
    final response = await _apiService.get('${ApiEndpoints.visitors}/inside');
    if (response['success']) {
      return response['data'] as List;
    }
    throw Exception(response['message']);
  }

  Future<void> logVisitorExit(Map<String, dynamic> data) async {
    final response = await _apiService.post(
      '${ApiEndpoints.visitors}/exit',
      data,
    );
    if (!response['success']) {
      throw Exception(response['message']);
    }
  }

  Future<Map<String, dynamic>> verifyPassCode(String code) async {
    final response = await _apiService.get(
      '${ApiEndpoints.visitors}/verify/$code',
    );
    if (response['success']) {
      return response['data'] as Map<String, dynamic>;
    }
    throw Exception(response['message']);
  }

  Future<List<dynamic>> getAllSocietyVisitors() async {
    final response = await _apiService.get('${ApiEndpoints.visitors}/all');
    if (response['success']) {
      return response['data'] as List;
    }
    throw Exception(response['message']);
  }
}
