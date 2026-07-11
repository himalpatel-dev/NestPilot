import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/society_structure.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dashboard_header.dart';
import '../login_screen.dart';
import '../notification_list_screen.dart';
import 'building_create_screen.dart';
import 'buildings_list_screen.dart';
import 'flat_create_screen.dart';
import 'flats_list_screen.dart';
import 'role_management_screen.dart';
import 'secretary_buildings_screen.dart';
import 'societies_list_screen.dart';
import 'society_create_screen.dart';

/// Dedicated home for the Super Admin — same hero header design as the unified
/// dashboard, with super-admin-focused management sections underneath.
class SuperAdminDashboardScreen extends StatefulWidget {
  final UserModel user;
  const SuperAdminDashboardScreen({super.key, required this.user});

  @override
  State<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  SuperAdminStats? _stats;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchNotifications();
  }

  Future<void> _fetchStats() async {
    try {
      final stats = await AdminService().getSuperAdminStats();
      if (mounted) setState(() => _stats = stats);
    } catch (e) {
      debugPrint('Super admin stats error: $e');
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      final res = await NotificationService().getNotifications(limit: 1);
      if (mounted) setState(() => _unreadCount = res.unreadCount);
    } catch (e) {
      debugPrint('Notifications error: $e');
    }
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _go(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _fetchStats());
  }

  void _showNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationListScreen()),
    ).then((_) => _fetchNotifications());
  }

  // ─── Management sections ────────────────────────────────────────────────────

  List<_SaSection> _sections() => [
        _SaSection('Societies & Structure', [
          _SaTile(Icons.add_business_rounded, 'Add Society',
              'Onboard a new society', AppColors.accentOrange,
              () => _go(const SocietyCreateScreen())),
          _SaTile(Icons.location_city_outlined, 'All Societies',
              'Browse & edit societies', AppColors.accentOrange,
              () => _go(const SocietiesListScreen())),
          _SaTile(Icons.apartment_rounded, 'Add Building',
              'Add a building or sector', AppColors.accentBlue,
              () => _go(const BuildingCreateScreen())),
          _SaTile(Icons.domain_outlined, 'All Buildings',
              'Browse all buildings', AppColors.accentBlue,
              () => _go(const BuildingsListScreen())),
          _SaTile(Icons.door_front_door_rounded, 'Add Flat',
              'Add a flat, shop or unit', AppColors.accentPurple,
              () => _go(const FlatCreateScreen())),
          _SaTile(Icons.list_alt_outlined, 'All Flats', 'Browse all units',
              AppColors.accentTeal, () => _go(const FlatsListScreen())),
        ]),
        _SaSection('People & Access', [
          _SaTile(Icons.shield_outlined, 'Roles',
              'Configure role permissions', AppColors.accentIndigo,
              () => _go(const RoleManagementScreen())),
          _SaTile(Icons.assignment_ind_outlined, 'Secretaries',
              'Assign society admins', AppColors.accentGreen,
              () => _go(const SecretaryBuildingsScreen())),
        ]),
        _SaSection('Account', [
          _SaTile(Icons.notifications_outlined, 'Alerts',
              'View your notifications', AppColors.accentRed,
              _showNotifications),
          _SaTile(Icons.person_outline, 'Profile', 'Account & logout',
              AppColors.accentPurple, _showProfileSheet),
        ]),
      ];

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cardBackground,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              // Fixed hero header — same design as the main dashboard.
              _buildHero(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _fetchStats();
                    await _fetchNotifications();
                  },
                  color: AppColors.white,
                  backgroundColor: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad + 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final section in _sections()) ...[
                          _sectionHeader(section.title),
                          const SizedBox(height: 14),
                          _grid(section.tiles),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return AppDashboardHeader(
      leftAction: Text(
        '${_getGreeting()} 👋',
        style: TextStyle(
          color: AppColors.white.withValues(alpha: 0.75),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      title: widget.user.fullName,
      subtitle: 'Super Administrator',
      unreadCount: _unreadCount,
      onNotificationTap: _showNotifications,
      stats: [
        AppHeaderStat(
          value: '${_stats?.totalSocieties ?? 0}',
          label: 'Societies',
          color: AppColors.accentOrange,
          icon: Icons.business_outlined,
        ),
        AppHeaderStat(
          value: '${_stats?.totalBuildings ?? 0}',
          label: 'Buildings',
          color: AppColors.accentBlue,
          icon: Icons.apartment_outlined,
        ),
        AppHeaderStat(
          value: '${_stats?.totalFlats ?? 0}',
          label: 'Flats',
          color: AppColors.accentPurple,
          icon: Icons.door_front_door_outlined,
        ),
        AppHeaderStat(
          value: '${_stats?.totalMembers ?? 0}',
          label: 'Members',
          color: AppColors.accentGreen,
          icon: Icons.people_outlined,
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(List<_SaTile> tiles) {
    return Column(
      children: [for (final t in tiles) _horizontalCard(t)],
    );
  }

  Widget _horizontalCard(_SaTile tile) {
    final iconColor = Color.lerp(tile.color, AppColors.black, 0.12)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: tile.onTap,
          splashColor: tile.color.withValues(alpha: 0.08),
          highlightColor: tile.color.withValues(alpha: 0.04),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Full-height tinted left panel with the icon
                Container(
                  width: 76,
                  color: tile.color.withValues(alpha: 0.13),
                  alignment: Alignment.center,
                  child: Icon(tile.icon, color: iconColor, size: 27),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                tile.label,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                tile.subtitle,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textHint,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Profile sheet ──────────────────────────────────────────────────────────

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.user.fullName.isNotEmpty
                      ? widget.user.fullName[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.user.fullName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Super Administrator',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                widget.user.mobile,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: AppColors.white,
                  ),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await AuthService().logout();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Data classes ────────────────────────────────────────────────────────────

class _SaSection {
  final String title;
  final List<_SaTile> tiles;
  const _SaSection(this.title, this.tiles);
}

class _SaTile {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _SaTile(
    this.icon,
    this.label,
    this.subtitle,
    this.color,
    this.onTap,
  );
}
