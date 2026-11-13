import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/roles.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_field_card.dart';
import '../../widgets/app_form_sheet.dart';
import '../../widgets/app_sheet_action.dart';
import '../../widgets/glare_button.dart';
import '../../widgets/module_page_header.dart';
import '../auth/login_screen.dart';
import '../notifications/notification_list_screen.dart';

/// The signed-in user's own profile, for every role: who they are, how to
/// reach them, their society and flat (or the buildings a secretary runs),
/// plus edit and logout. Opens on the session copy and refreshes from
/// /auth/me.
class ProfileScreen extends StatefulWidget {
  /// Shown until the fresh copy arrives from the server.
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserModel _user = SessionService().currentUser ?? widget.user;

  // True until the first /auth/me reply — the login-time session copy has no
  // secretary buildings, so "none assigned" must wait for it.
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final fresh = await AuthService().getMe();
    if (!mounted) return;
    setState(() {
      if (fresh != null) _user = fresh;
      _loading = false;
    });
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> _editProfile() async {
    final updated = await showAppFormSheet<UserModel>(
      context: context,
      builder: (_) => _EditProfileSheet(user: _user),
    );
    if (updated == null || !mounted) return;
    setState(() => _user = updated);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationListScreen()),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final hasFlat = (user.flatNumber ?? '').isNotEmpty;
    final hasSociety = (user.societyName ?? '').isNotEmpty;
    final hasBuilding = (user.buildingName ?? '').isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      // Header stays pinned; only the profile below it scrolls.
      body: Column(
        children: [
          const ModulePageHeader(
            title: 'My Profile',
            description: 'Your account, contact and home details',
            icon: Icons.person_rounded,
            iconColor: AppColors.accentPurple,
            showSearch: false,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.white,
              backgroundColor: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 28),
                children: [
                  _identityCard(user),
                  const SizedBox(height: 24),
                  const AppSectionHeader('Contact'),
                  const SizedBox(height: 12),
                  _infoCard([
                    _infoRow(
                      icon: Icons.phone_outlined,
                      color: AppColors.accentBlue,
                      label: 'Mobile',
                      value: user.mobile,
                      hint: 'Used to sign in with OTP',
                    ),
                    _infoRow(
                      icon: Icons.email_outlined,
                      color: AppColors.accentPurple,
                      label: 'Email',
                      value: user.email,
                    ),
                  ]),
                  if (hasSociety || hasFlat) ...[
                    const SizedBox(height: 24),
                    AppSectionHeader(hasFlat ? 'Your Home' : 'Your Society'),
                    const SizedBox(height: 12),
                    _infoCard([
                      if (hasSociety)
                        _infoRow(
                          icon: Icons.location_city_outlined,
                          color: AppColors.accentOrange,
                          label: 'Society',
                          value: user.societyName,
                          hint: user.societyCity,
                        ),
                      if (hasBuilding)
                        _infoRow(
                          icon: Icons.apartment_rounded,
                          color: AppColors.accentTeal,
                          label: 'Building',
                          value: user.buildingName,
                        ),
                      if (hasFlat)
                        _infoRow(
                          icon: Icons.door_front_door_outlined,
                          color: AppColors.accentGreen,
                          label: 'Flat',
                          value: user.flatNumber,
                          hint: _relationLabel(user.relationType),
                        ),
                    ]),
                  ],
                  if (user.role == UserRoles.societyAdmin) ...[
                    const SizedBox(height: 24),
                    const AppSectionHeader('Buildings You Manage'),
                    const SizedBox(height: 12),
                    _buildingsCard(user.managedBuildings),
                  ],
                  const SizedBox(height: 24),
                  const AppSectionHeader('Account'),
                  // AppSheetAction brings its own 10px top margin.
                  const SizedBox(height: 2),
                  AppSheetAction(
                    icon: Icons.edit_outlined,
                    label: 'Edit profile',
                    subtitle: 'Update your name and email',
                    color: AppColors.accentBlue,
                    onTap: _editProfile,
                  ),
                  AppSheetAction(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    subtitle: 'Your alerts and society updates',
                    color: AppColors.accentPurple,
                    onTap: _openNotifications,
                  ),
                  const SizedBox(height: 24),
                  _logoutButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  Widget _identityCard(UserModel user) {
    final since = user.createdAt;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _avatar(user),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isEmpty ? 'Your name' : user.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _pill(
                      SessionService().roleLabel ?? 'User',
                      _roleColor(user.role),
                    ),
                    _pill(_statusLabel(user.status), _statusColor(user.status)),
                  ],
                ),
                if (since != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Member since ${DateFormat('MMM yyyy').format(since.toLocal())}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(UserModel user) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(user.fullName),
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            rows[i],
          ],
        ],
      ),
    );
  }

  // Tinted icon tile over an uppercase label and value — the same detail row
  // as the Gate Control visitor cards.
  Widget _infoRow({
    required IconData icon,
    required Color color,
    required String label,
    required String? value,
    String? hint,
  }) {
    final text = (value ?? '').trim();
    final hasValue = text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasValue ? text : 'Not added',
                  style: TextStyle(
                    color: hasValue
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                    fontSize: 15,
                    fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (hint != null && hint.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildingsCard(List<String> buildings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: buildings.isNotEmpty
          ? Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final name in buildings) _buildingChip(name)],
            )
          : Text(
              _loading ? 'Loading…' : 'No buildings assigned yet',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
    );
  }

  Widget _buildingChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.accentIndigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentIndigo.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.domain_outlined,
            size: 14,
            color: AppColors.accentIndigo,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.accentIndigo,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Same button as the Super Admin dashboard's logout.
  Widget _logoutButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.accentRed.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentRed.withValues(alpha: 0.55),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () => confirmLogout(context),
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.white.withValues(alpha: 0.15),
          highlightColor: AppColors.white.withValues(alpha: 0.08),
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout_rounded, size: 18, color: AppColors.white),
                SizedBox(width: 8),
                Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Edit sheet ──────────────────────────────────────────────────────────────

/// Name and email editor. Pops the saved [UserModel]; API errors stay inside
/// the sheet, since a snackbar would sit underneath it.
class _EditProfileSheet extends StatefulWidget {
  final UserModel user;

  const _EditProfileSheet({required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  static final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.user.fullName);
  late final _emailCtrl = TextEditingController(text: widget.user.email ?? '');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await AuthService().updateMe(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      accentColor: AppColors.accentPurple,
      icon: Icons.edit_outlined,
      title: 'Edit Profile',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              AppSheetErrorBanner(_error!),
              const SizedBox(height: 14),
            ],
            AppFieldCard(
              icon: Icons.person_outline_rounded,
              label: 'Full Name',
              field: AppBorderlessField(
                controller: _nameCtrl,
                hint: 'Your full name',
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter your name' : null,
              ),
            ),
            const SizedBox(height: 14),
            AppFieldCard(
              icon: Icons.email_outlined,
              label: 'Email (optional)',
              field: AppBorderlessField(
                controller: _emailCtrl,
                hint: 'name@example.com',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final email = (v ?? '').trim();
                  if (email.isEmpty || _emailRe.hasMatch(email)) return null;
                  return 'Enter a valid email address';
                },
              ),
            ),
            const SizedBox(height: 14),
            _mobileNote(),
            const SizedBox(height: 24),
            GlarePrimaryButton(
              text: 'Save Changes',
              isLoading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  // Same info note as the User Management detail sheet.
  Widget _mobileNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentIndigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentIndigo.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.accentIndigo,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Your mobile ${widget.user.mobile} is how you sign in, so it "
              "can't be changed here. Ask your administrator if it needs "
              'updating.',
              style: const TextStyle(
                color: AppColors.accentIndigo,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared bits ─────────────────────────────────────────────────────────────

/// Asks for confirmation, then signs out and returns to the login screen.
/// Used by the profile page and the dashboard header.
Future<void> confirmLogout(BuildContext context) async {
  final user = SessionService().currentUser;
  // Same confirm dialog as Gate Control's "Mark Exit?".
  final ok = await showDialog<bool>(
    context: context,
    barrierColor: AppColors.black.withValues(alpha: 0.55),
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.15),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: const BoxDecoration(
                color: AppColors.accentRed,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.40),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Logout?',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (user != null && user.fullName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.fullName,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.80),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                children: [
                  Text(
                    "You'll need an OTP on ${user?.mobile ?? 'your mobile'} "
                    'to sign back in.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, false),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, true),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.accentRed,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentRed.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Logout',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (ok != true || !context.mounted) return;
  await AuthService().logout();
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'U';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

String _statusLabel(String status) {
  switch (status) {
    case 'ACTIVE':
      return 'Active';
    case 'PENDING':
      return 'Pending';
    case 'BLOCKED':
      return 'Blocked';
    case 'REJECTED':
      return 'Rejected';
    default:
      return status.isEmpty ? 'Unknown' : status;
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'ACTIVE':
      return AppColors.accentGreen;
    case 'PENDING':
      return AppColors.accentAmber;
    case 'BLOCKED':
      return AppColors.accentRed;
    default:
      return AppColors.textMuted;
  }
}

// Same role colours as the Roles & Permissions and User Management screens.
Color _roleColor(String code) {
  switch (code) {
    case UserRoles.superAdmin:
      return AppColors.accentRed;
    case UserRoles.societyAdmin:
      return AppColors.accentIndigo;
    case UserRoles.member:
      return AppColors.accentGreen;
    case UserRoles.securityGuard:
      return AppColors.accentOrange;
    default:
      return AppColors.accentPurple;
  }
}

String? _relationLabel(String? relation) {
  switch ((relation ?? '').toUpperCase()) {
    case '':
      return null;
    case 'OWNER':
      return 'Owner';
    case 'TENANT':
      return 'Tenant';
    case 'FAMILY':
    case 'FAMILY_MEMBER':
      return 'Family member';
    default:
      return relation;
  }
}

Widget _pill(String label, Color color) {
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 150),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    ),
  );
}
