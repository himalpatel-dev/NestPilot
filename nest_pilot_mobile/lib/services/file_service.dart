import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/app_config.dart';
import 'api_service.dart';

class FileService {
  Future<void> downloadAndOpenReceipt(String paymentId) async {
    final status = await Permission.storage.request();
    if (!status.isGranted && !status.isLimited) {
      // On Android 13+, storage permission might not be needed for app-specific dirs,
      // but we'll try to request it anyway.
    }

    final url = Uri.parse(
      '${AppConfig.baseUrl}/api/payments/receipts/$paymentId',
    );
    final apiService = ApiService();
    final headers = await apiService.getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/receipt_$paymentId.pdf';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      await OpenFilex.open(filePath);
    } else {
      throw Exception('Failed to download receipt');
    }
  }
}
