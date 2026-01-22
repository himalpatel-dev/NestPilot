class ApiEndpoints {
  // Auth
  static const String requestOtp = '/api/auth/request-otp';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String register = '/api/auth/register';
  static const String me = '/api/auth/me';

  // Approvals
  static const String pendingUsers = '/api/admin/pending-users';
  static const String societyMembers = '/api/admin/members';
  static String approveUser(String id) => '/api/admin/users/$id/approve';
  static String rejectUser(String id) => '/api/admin/users/$id/reject';

  // Society Setup
  static const String societies = '/api/societies';
  static String societyBuildings(String id) => '/api/societies/$id/buildings';
  static String buildingFlats(String id) => '/api/buildings/$id/flats';
  static String societyFlats(String id) => '/api/societies/$id/flats';

  // Notices
  static const String notices = '/api/notices';
  static String noticeDetail(String id) => '/api/notices/$id';

  // Complaints
  static const String complaints = '/api/complaints';
  static String complaintStatus(String id) => '/api/complaints/$id/status';
  static String complaintComments(String id) => '/api/complaints/$id/comments';

  // Billing
  static const String bills = '/api/bills';
  static String publishBill(String id) => '/api/bills/$id/publish';
  static const String myBills = '/api/bills/my';
  static String userBills(String userId) => '/api/bills/user/$userId';

  // Payments
  static const String syncPayments = '/api/payments/offline-sync';
  static const String myPayments = '/api/payments/my';
  static String paymentReceipt(String id) => '/api/payments/receipts/$id';
}
