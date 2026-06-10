class ApiEndpoints {
  // Auth
  static const String requestOtp = '/api/auth/request-otp';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String register = '/api/auth/register';
  static const String me = '/api/auth/me';

  // Approvals
  static const String dashboardStats = '/api/admin/dashboard-stats';
  static const String pendingUsers = '/api/admin/pending-users';
  static const String societyMembers = '/api/admin/members';
  static String approveUser(String id) => '/api/admin/users/$id/approve';
  static String rejectUser(String id) => '/api/admin/users/$id/reject';

  // Society Setup
  static const String societies = '/api/society';
  static const String houseStats = '/api/society/house-stats';
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

  static const String billsDashboard = '/api/bills/dashboard';

  // Payments
  static const String syncPayments = '/api/payments/offline-sync';
  static const String myPayments = '/api/payments/my';
  static String paymentReceipt(String id) => '/api/payments/receipts/$id';

  static const String visitorsDashboard = '/api/visitors/dashboard';

  // Vehicles
  static const String vehicles = '/api/vehicles';
  static const String allVehicles = '/api/vehicles/all';
  static String deleteVehicle(int id) => '/api/vehicles/$id';

  // Visitors
  static const String visitors = '/api/visitors';
  static const String myVisitors = '/api/visitors/my';
  static const String inviteVisitor = '/api/visitors/invite';

  // Amenities
  static const String amenities = '/api/amenities';
  static const String myAmenityBookings = '/api/amenities/my-bookings';
  static const String bookAmenity = '/api/amenities/book';
  static const String allBookings = '/api/amenities/bookings';
  static String updateBookingStatus(int id) => '/api/amenities/bookings/$id';

  // Staff
  static const String staff = '/api/staff';
  static String staffAttendance(int id) => '/api/staff/$id/attendance';

  // Polls
  static const String polls = '/api/polls';
  static const String votePoll = '/api/polls/vote';

  // Documents
  static const String documents = '/api/documents';

  // Notifications
  static const String notifications = '/api/notifications';
  static String readNotification(String id) => '/api/notifications/$id/read';

  // Activity
  static const String recentActivity = '/api/activity/recent';

  // Events
  static const String events = '/api/events';
  static String eventDetail(String id) => '/api/events/$id';
  static String registerEvent(String id) => '/api/events/$id/register';

  // Society Admin → Building assignments (Super Admin only)
  static const String societyAdmins = '/api/society-admins';
  static String societyAdminBuildings(int userId) =>
      '/api/society-admins/$userId/buildings';

  // Roles & Permissions
  static const String roles = '/api/roles';
  static const String rolesEnum = '/api/roles/enum';
  static const String modules = '/api/roles/modules';
  static const String myPermissions = '/api/roles/my-permissions';
  static String roleById(int id) => '/api/roles/$id';
  static String rolePermissions(int id) => '/api/roles/$id/permissions';
}
