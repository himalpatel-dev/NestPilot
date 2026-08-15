import '../config/api_endpoints.dart';
import '../models/notice_complaint.dart';
import 'api_service.dart';

class NoticeService {
  final ApiService _apiService = ApiService();

  Future<List<Notice>> getNotices() async {
    final response = await _apiService.get(ApiEndpoints.notices);
    if (response['success'] == true) {
      return (response['data'] as List).map((n) => Notice.fromJson(n)).toList();
    }
    return [];
  }

  Future<Notice?> getNoticeDetail(String id) async {
    final response = await _apiService.get(ApiEndpoints.noticeDetail(id));
    if (response['success'] == true) {
      return Notice.fromJson(response['data']);
    }
    return null;
  }

  Future<bool> createNotice(
    String title,
    String description, {
    String? filePath,
  }) async {
    final response = await _apiService.multipartPost(
      ApiEndpoints.notices,
      {'title': title, 'description': description},
      filePath: filePath,
      fileKey: 'attachments', // Backend uses req.files for Notice
    );
    return response['success'] ?? false;
  }

  Future<bool> updateNotice(
    String id,
    String title,
    String description, {
    String? filePath,
  }) async {
    final response = await _apiService.multipartPut(
      ApiEndpoints.noticeDetail(id),
      {'title': title, 'description': description},
      filePath: filePath,
      fileKey: 'attachments',
    );
    return response['success'] ?? false;
  }

  Future<bool> deleteNotice(String id) async {
    final response = await _apiService.delete(ApiEndpoints.noticeDetail(id));
    return response['success'] ?? false;
  }
}

class ComplaintService {
  final ApiService _apiService = ApiService();

  Future<List<Complaint>> getComplaints() async {
    final response = await _apiService.get(ApiEndpoints.complaints);
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((c) => Complaint.fromJson(c))
          .toList();
    }
    return [];
  }

  Future<bool> createComplaint(
    String category,
    String description, {
    String? filePath,
  }) async {
    final response = await _apiService.multipartPost(
      ApiEndpoints.complaints,
      {'category': category, 'description': description},
      filePath: filePath,
      fileKey: 'image',
    );
    return response['success'] ?? false;
  }

  /// Category / description / photo only — status has its own endpoint, and
  /// priority is not editable server-side. Leaving [filePath] null keeps the
  /// existing photo: the API only overwrites it when a file is uploaded.
  Future<Complaint?> updateComplaint(
    String id,
    String category,
    String description, {
    String? filePath,
  }) async {
    final response = await _apiService.multipartPut(
      ApiEndpoints.complaint(id),
      {'category': category, 'description': description},
      filePath: filePath,
      fileKey: 'image',
    );
    if (response['success'] == true && response['data'] != null) {
      return Complaint.fromJson(response['data']);
    }
    return null;
  }

  Future<bool> updateStatus(String id, String status) async {
    final response = await _apiService.patch(ApiEndpoints.complaintStatus(id), {
      'status': status,
    });
    return response['success'] ?? false;
  }

  Future<ComplaintComment?> addComment(String id, String message) async {
    final response = await _apiService.post(
      ApiEndpoints.complaintComments(id),
      {'message': message},
    );
    if (response['success'] == true) {
      return ComplaintComment.fromJson(response['data']);
    }
    return null;
  }
}
