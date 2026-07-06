import '../models/user_model.dart';

/// Holds the logged-in user for synchronous access across screens.
/// Populated by [AuthService] on login / getMe, cleared on logout.
class SessionService {
  SessionService._();
  static final SessionService _instance = SessionService._();
  factory SessionService() => _instance;

  UserModel? currentUser;

  String? get societyName => currentUser?.societyName;

  /// Human-friendly role label, e.g. SOCIETY_ADMIN → 'Secretary'.
  String? get roleLabel {
    final role = currentUser?.role;
    if (role == null || role.isEmpty) return null;
    switch (role) {
      case 'SUPER_ADMIN':
        return 'Super Admin';
      case 'SOCIETY_ADMIN':
        return 'Secretary';
      case 'SECURITY_GUARD':
        return 'Security';
      case 'MEMBER':
        return 'Member';
      default:
        return role
            .split('_')
            .map((w) =>
                w.isEmpty ? w : '${w[0]}${w.substring(1).toLowerCase()}')
            .join(' ');
    }
  }

  /// Context line for page headers, e.g. "Palm Meadows · Secretary".
  /// Parts drop out when unknown; empty string when nothing is known.
  String get contextLine {
    final parts = <String>[
      if ((societyName ?? '').isNotEmpty) societyName!,
      if ((roleLabel ?? '').isNotEmpty) roleLabel!,
    ];
    return parts.join(' · ');
  }

  void clear() => currentUser = null;
}
