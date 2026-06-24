import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../config/roles.dart';
import '../../config/modules.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dashboard_header.dart';
import '../../theme/dashboard_cards.dart';
import '../../models/society_structure.dart';
import '../../services/admin_service.dart';
import '../dashboard_screen.dart';
import '../login_screen.dart';
import '../security/security_guard_dashboard_screen.dart';
import '../notification_list_screen.dart';
import 'society_create_screen.dart';
import 'societies_list_screen.dart';
import 'building_create_screen.dart';
import 'buildings_list_screen.dart';
import 'flat_create_screen.dart';
import 'flats_list_screen.dart';
import 'role_management_screen.dart';
import 'secretary_buildings_screen.dart';

/// Picks the home screen for [user] after login based on role:
/// - Super Admin  → SuperAdminDashboardScreen  (no tabs)
/// - Security Guard → SecurityGuardDashboardScreen (no tabs)
/// - Everyone else → DashboardScreen (tabbed)
Widget homeScreenFor(UserModel user) {
  switch (user.role) {
    case UserRoles.superAdmin:
      return SuperAdminDashboardScreen(user: user);
    case UserRoles.securityGuard:
      return SecurityGuardDashboardScreen(user: user);
    default:
      return DashboardScreen(user: user);
  }
}

/// Dedicated dashboard for SUPER_ADMIN. Single page: a hero header with
/// stats, a quick-action row for the create flows, then descriptive list
/// tiles for directories, system management and settings.
class SuperAdminDashboardScreen extends StatefulWidget {
  final UserModel user;
  const SuperAdminDashboardScreen({super.key, required this.user});

  @override
  State<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  int _unreadCount = 0;
  SuperAdminStats? _stats;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    await Future.wait([_fetchNotifications(), _fetchStats()]);
  }

  Future<void> _fetchNotifications() async {
    try {
      final res = await NotificationService().getNotifications(limit: 1);
      if (mounted) setState(() => _unreadCount = res.unreadCount);
    } catch (e) {
      debugPrint('Notifications error: $e');
    }
  }

  Future<void> _fetchStats() async {
    try {
      final stats = await AdminService().getSuperAdminStats();
      if (mounted) setState(() => _stats = stats);
    } catch (e) {
      debugPrint('Stats error: $e');
    }
  }

  void _showNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationListScreen()),
    ).then((_) => _fetchNotifications());
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final quickActions = _quickActions();
    final groups = _tileGroups();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cardBackground,
        body: RefreshIndicator(
          onRefresh: _fetchAll,
          color: AppColors.white,
          backgroundColor: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: AppDashboardHeader(
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
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad + 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (quickActions.isNotEmpty) ...[
                      _buildSectionHeader('Quick Actions'),
                      const SizedBox(height: 14),
                      _buildQuickActions(quickActions),
                      const SizedBox(height: 24),
                    ],
                    for (final group in groups) ...[
                      _buildSectionHeader(group.title),
                      const SizedBox(height: 14),
                      _buildTileCard(group.tiles),
                      const SizedBox(height: 24),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Quick Actions ───────────────────────────────────────────────────────────

  List<_QuickAction> _quickActions() {
    final perms = PermissionService();
    return [
      _QuickAction(
        Icons.business_outlined,
        'Create\nSociety',
        AppColors.accentPink,
        () => _go(const SocietyCreateScreen()),
      ),
      _QuickAction(
        Icons.apartment_outlined,
        'Add\nBuilding',
        AppColors.accentBlue,
        () => _go(const BuildingCreateScreen()),
      ),
      _QuickAction(
        Icons.door_front_door_outlined,
        'Add\nFlat',
        AppColors.accentOrange,
        () => _go(const FlatCreateScreen()),
      ),
    ].where((_) => perms.canCreate(ModuleCodes.buildings)).toList();
  }

  Widget _buildQuickActions(List<_QuickAction> actions) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: DashActionCard(
                icon: actions[i].icon,
                color: actions[i].color,
                label: actions[i].label,
                onTap: actions[i].onTap,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Tile groups ─────────────────────────────────────────────────────────────

  List<_TileGroup> _tileGroups() {
    final perms = PermissionService();
    final groups = [
      _TileGroup('Directory', [
        _AdminTile(
          icon: Icons.location_city_outlined,
          color: AppColors.accentOrange,
          title: 'All Societies',
          subtitle: 'View and edit every society',
          onTap: () => _go(const SocietiesListScreen()),
          module: ModuleCodes.buildings,
        ),
        _AdminTile(
          icon: Icons.domain_outlined,
          color: AppColors.accentBlue,
          title: 'All Buildings',
          subtitle: 'Browse and edit buildings, blocks & sectors',
          onTap: () => _go(const BuildingsListScreen()),
          module: ModuleCodes.buildings,
        ),
        _AdminTile(
          icon: Icons.list_alt_outlined,
          color: AppColors.accentTeal,
          title: 'Flats Directory',
          subtitle: 'All flats and units by society & building',
          onTap: () => _go(const FlatsListScreen()),
          module: ModuleCodes.buildings,
        ),
      ]),
      _TileGroup('System Management', [
        _AdminTile(
          icon: Icons.shield_outlined,
          color: AppColors.accentIndigo,
          title: 'Roles & Permissions',
          subtitle: 'Create roles and configure module access',
          onTap: () => _go(const RoleManagementScreen()),
          module: ModuleCodes.roles,
        ),
        _AdminTile(
          icon: Icons.assignment_ind_outlined,
          color: AppColors.accentGreen,
          title: 'Secretary Buildings',
          subtitle: 'Add secretaries and assign their buildings',
          onTap: () => _go(const SecretaryBuildingsScreen()),
          module: ModuleCodes.buildings,
        ),
      ]),
      _TileGroup('Settings', [
        _AdminTile(
          icon: Icons.notifications_outlined,
          color: AppColors.accentAmber,
          title: 'Notifications',
          subtitle: 'View all your notifications',
          onTap: _showNotifications,
        ),
        _AdminTile(
          icon: Icons.logout_rounded,
          color: AppColors.accentRed,
          title: 'Logout',
          subtitle: 'Sign out of this device',
          onTap: _logout,
        ),
      ]),
    ];

    return groups
        .map(
          (g) => _TileGroup(
            g.title,
            g.tiles
                .where(
                  (t) =>
                      t.module == null || perms.can(t.module!, PermAction.view),
                )
                .toList(),
          ),
        )
        .where((g) => g.tiles.isNotEmpty)
        .toList();
  }

  Widget _buildTileCard(List<_AdminTile> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 60, color: AppColors.border),
            _buildAdminTile(tiles[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminTile(_AdminTile tile) {
    return InkWell(
      onTap: tile.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tile.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Icon(tile.icon, color: tile.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tile.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tile.subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section header ──────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.50),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ─── Navigation helpers ──────────────────────────────────────────────────────

  void _go(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _fetchAll());
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

// ─── Data classes ────────────────────────────────────────────────────────────

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.icon, this.label, this.color, this.onTap);
}

class _TileGroup {
  final String title;
  final List<_AdminTile> tiles;
  const _TileGroup(this.title, this.tiles);
}

class _AdminTile {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Module this tile belongs to. null = always shown (e.g. Logout).
  /// Gated tiles are shown when the user can view the module.
  final String? module;
  const _AdminTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.module,
  });
}
