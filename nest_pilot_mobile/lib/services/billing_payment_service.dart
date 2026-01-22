import '../config/api_endpoints.dart';
import '../models/billing_payment.dart';
import 'api_service.dart';

class BillService {
  final ApiService _apiService = ApiService();

  Future<List<MemberBill>> getMyBills() async {
    final response = await _apiService.get(ApiEndpoints.myBills);
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((b) => MemberBill.fromJson(b))
          .toList();
    }
    return [];
  }

  Future<List<Bill>> getBills() async {
    final response = await _apiService.get(ApiEndpoints.bills);
    if (response['success'] == true) {
      return (response['data'] as List).map((b) => Bill.fromJson(b)).toList();
    }
    return [];
  }

  Future<List<MemberBill>> getUserBills(String userId) async {
    final response = await _apiService.get(ApiEndpoints.userBills(userId));
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((b) => MemberBill.fromJson(b))
          .toList();
    }
    return [];
  }

  Future<bool> createBill(Map<String, dynamic> data) async {
    // Backend expects: bill_type, title, description, amount_total, due_date, apply_to
    final response = await _apiService.post(ApiEndpoints.bills, {
      'bill_type': data['billType'],
      'title': data['title'],
      'description': data['description'],
      'amount_total': data['amountTotal'],
      'due_date': data['dueDate'],
      'apply_to': data['applyTo'] ?? 'ALL',
    });
    return response['success'] ?? false;
  }

  Future<bool> publishBill(String id) async {
    final response = await _apiService.post(ApiEndpoints.publishBill(id), {});
    return response['success'] ?? false;
  }
}

class PaymentService {
  final ApiService _apiService = ApiService();

  Future<bool> markPaymentReceived(Map<String, dynamic> data) async {
    // Backend uses offline-sync which expects an array of payments
    final response = await _apiService.post(ApiEndpoints.syncPayments, {
      'payments': [
        {
          'memberBillId': data['memberBillId'],
          'amount': data['amount'],
          'paymentMode': data['paymentMode'],
          'paymentDate': data['paymentDate'],
          'referenceNo': data['referenceNo'],
          'note': data['note'],
          'clientRefId': DateTime.now()
              .millisecondsSinceEpoch, // Unique ref for idempotency
        },
      ],
    });
    return response['success'] ?? false;
  }

  Future<List<Payment>> getMyPayments() async {
    final response = await _apiService.get(ApiEndpoints.myPayments);
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((p) => Payment.fromJson(p))
          .toList();
    }
    return [];
  }
}
