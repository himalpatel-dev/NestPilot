import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final headers = await getHeaders();
    final response = await http.get(url, headers: headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final headers = await getHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final headers = await getHeaders();
    final response = await http.patch(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final headers = await getHeaders();
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final headers = await getHeaders();
    final response = await http.delete(url, headers: headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> multipartPost(
    String endpoint,
    Map<String, String> fields, {
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
    String? fileKey,
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    var request = http.MultipartRequest('POST', url);
    request.headers.addAll({
      if (token != null) 'Authorization': 'Bearer $token',
    });

    request.fields.addAll(fields);

    if (fileKey != null) {
      if (fileBytes != null && fileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(fileKey, fileBytes, filename: fileName),
        );
      } else if (filePath != null) {
        request.files.add(await http.MultipartFile.fromPath(fileKey, filePath));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      String errorMessage = body['message'] ?? 'Something went wrong';
      if (body['errors'] != null && body['errors'] is List) {
        final errors = (body['errors'] as List).join('\n');
        errorMessage += '\n$errors';
      }
      throw Exception(errorMessage);
    }
  }
}
