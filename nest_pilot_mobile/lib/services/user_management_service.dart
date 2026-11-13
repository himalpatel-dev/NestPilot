import '../config/api_endpoints.dart';
import '../models/managed_user.dart';
import 'api_service.dart';

/// Super-Admin user directory — every user across every society. Search,
/// filters and paging run on the server so the screen stays quick however
/// many societies are onboarded.
class UserManagementService {
  final ApiService _api = ApiService();

  static const int pageSize = 20;

  Future<UserPage> getUsers({
    int page = 1,
    String? search,
    int? societyId,
    int? roleId,
    String? status,
    bool sortByName = false,
  }) async {
    final query = Uri(
      queryParameters: {
        'page': '$page',
        'limit': '$pageSize',
        if (search != null && search.isNotEmpty) 'search': search,
        if (societyId != null) 'society_id': '$societyId',
        if (roleId != null) 'role_id': '$roleId',
        'status': ?status,
        if (sortByName) 'sort': 'name',
      },
    ).query;
    final res = await _api.get('${ApiEndpoints.users}?$query');
    final data = res['data'] as Map<String, dynamic>? ?? const {};
    return UserPage(
      items: (data['items'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ManagedUser.fromJson)
          .toList(),
      total: (data['total'] as num?)?.toInt() ?? 0,
      hasMore: data['has_more'] == true,
    );
  }

  Future<UserStats> getStats({int? societyId}) async {
    final qs = societyId == null ? '' : '?society_id=$societyId';
    final res = await _api.get('${ApiEndpoints.userStats}$qs');
    return UserStats.fromJson(
      res['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  /// Full record, including a Society Admin's assigned buildings.
  Future<ManagedUser> getUser(int id) async {
    final res = await _api.get(ApiEndpoints.userById(id));
    return ManagedUser.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// Creates an active account that can sign in with OTP straight away.
  /// [houseId] + [relationType] place a member in their flat.
  Future<String> createUser({
    required String fullName,
    required String mobile,
    String? email,
    required int roleId,
    int? societyId,
    int? houseId,
    String? relationType,
  }) async {
    final res = await _api.post(ApiEndpoints.users, {
      'full_name': fullName,
      'mobile': mobile,
      'email': email ?? '',
      'role_id': roleId,
      'society_id': ?societyId,
      'house_id': ?houseId,
      'relation_type': ?relationType,
    });
    return (res['message'] as String?) ?? 'User created';
  }

  /// Saves the edit form. [societyId] is always sent — null clears it, which
  /// is what a Super Admin account needs.
  Future<ManagedUser> updateUser(
    int id, {
    required String fullName,
    required String mobile,
    String? email,
    required int roleId,
    int? societyId,
    int? houseId,
    String? relationType,
  }) async {
    final res = await _api.put(ApiEndpoints.userById(id), {
      'full_name': fullName,
      'mobile': mobile,
      'email': email ?? '',
      'role_id': roleId,
      'society_id': societyId,
      'house_id': ?houseId,
      'relation_type': ?relationType,
    });
    return ManagedUser.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// 'active' approves or unblocks; 'rejected' / 'blocked' lock the account
  /// out on its next request.
  Future<ManagedUser> setStatus(int id, String status) async {
    final res = await _api.patch(ApiEndpoints.userStatus(id), {
      'status': status,
    });
    return ManagedUser.fromJson(res['data'] as Map<String, dynamic>);
  }
}
