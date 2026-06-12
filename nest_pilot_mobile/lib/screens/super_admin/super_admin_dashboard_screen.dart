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
import '../../theme/app_icons.dart';
import '../dashboard_screen.dart';
import '../login_screen.dart';
import '../notification_list_screen.dart';
import 'society_create_screen.dart';
import 'societies_list_screen.dart';
import 'building_create_screen.dart';
import 'buildings_list_screen.dart';
import 'flat_create_screen.dart';
import 'flats_list_screen.dart';
import 'role_management_screen.dart';
import 'secretary_buildings_screen.dart';

/// Picks the home screen for [user] after login: super admins get their own
/// focused dashboard, everyone else gets the regular tabbed dashboard.
Widget homeScreenFor(UserModel user) => user.role == UserRoles.superAdmin
    ? SuperAdminDashboardScreen(user: user)
    : DashboardScreen(user: user);

/// Dedicated dashboard for SUPER_ADMIN. Single page styled like the Services
/// tab: a hero header with stats, then sections of icon tiles covering only
/// what a super admin actually does (societies, buildings, flats, roles).
class SuperAdminDashboardScreen extends StatefulWidget {
  final UserModel user;
  const SuperAdminDashboardScreen({super.key, required this.user});

  @override
  State<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final res = await NotificationService().getNotifications(limit: 1);
      if (mounted) setState(() => _unreadCount = res.unreadCount);
    } catch (e) {
      debugPrint('Notifications error: $e');
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
    final sections = _applyPermissionFilter(_sections());
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cardBackground,
        body: RefreshIndicator(
          onRefresh: _fetchNotifications,
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
                  stats: const [
                    AppHeaderStat(
                        value: '0',
                        label: 'Societies',
                        color: AppColors.accentOrange,
                        icon: Icons.business_outlined),
                    AppHeaderStat(
                        value: '0',
                        label: 'Buildings',
                        color: AppColors.accentBlue,
                        icon: Icons.apartment_outlined),
                    AppHeaderStat(
                        value: '0',
                        label: 'Flats',
                        color: AppColors.accentPurple,
                        icon: Icons.door_front_door_outlined),
                    AppHeaderStat(
                        value: '0',
                        label: 'Members',
                        color: AppColors.accentGreen,
                        icon: Icons.people_outlined),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad + 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((ctx, i) {
                    final s = sections[i];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: i == sections.length - 1 ? 0 : 24,
                      ),
                      child: _Section(title: s.title, tiles: s.tiles),
                    );
                  }, childCount: sections.length),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Drop tiles whose module the user can't access. Drop sections that end up empty.
  List<_HubSection> _applyPermissionFilter(List<_HubSection> sections) {
    final perms = PermissionService();
    final out = <_HubSection>[];
    for (final s in sections) {
      final allowed = s.tiles
          .where((t) => t.module == null || perms.can(t.module!, t.requiredAction))
          .toList();
      if (allowed.isNotEmpty) {
        out.add(_HubSection(s.title, allowed));
      }
    }
    return out;
  }

  List<_HubSection> _sections() => [
    _HubSection('Society Setup', [
      _Tile.gated(
        Icons.business_outlined, 'Create Society', AppColors.accentOrange,
        (c) => _go(c, const SocietyCreateScreen()),
        ModuleCodes.buildings,
        requiredAction: PermAction.create,
      ),
      _Tile.gated(
        Icons.apartment_outlined, 'Add Building', AppColors.accentBlue,
        (c) => _go(c, const BuildingCreateScreen()),
        ModuleCodes.buildings,
        requiredAction: PermAction.create,
      ),
      _Tile.gated(
        Icons.door_front_door_outlined, 'Add Flat', AppColors.accentPurple,
        (c) => _go(c, const FlatCreateScreen()),
        ModuleCodes.buildings,
        requiredAction: PermAction.create,
      ),
    ]),
    _HubSection('Directory', [
      _Tile.gated(
        Icons.location_city_outlined, 'All Societies', AppColors.accentPink,
        (c) => _go(c, const SocietiesListScreen()),
        ModuleCodes.buildings,
      ),
      _Tile.gated(
        Icons.domain_outlined, 'All Buildings', AppColors.accentAmber,
        (c) => _go(c, const BuildingsListScreen()),
        ModuleCodes.buildings,
      ),
      _Tile.gated(
        Icons.list_alt_outlined, 'Flats List', AppColors.accentTeal,
        (c) => _go(c, const FlatsListScreen()),
        ModuleCodes.buildings,
      ),
    ]),
    _HubSection('Roles & Access', [
      _Tile.gated(
        Icons.shield_outlined, 'Roles & Permissions', AppColors.accentIndigo,
        (c) => _go(c, const RoleManagementScreen()),
        ModuleCodes.roles,
      ),
      _Tile.gated(
        Icons.assignment_ind_outlined, 'Secretary Buildings', AppColors.accentGreen,
        (c) => _go(c, const SecretaryBuildingsScreen()),
        ModuleCodes.buildings,
      ),
    ]),
    _HubSection('Settings', [
      _Tile(
        Icons.notifications_outlined, 'Notifications', AppColors.accentOrange,
        (c) => _go(c, const NotificationListScreen()),
      ),
      _Tile(
        Icons.logout_rounded, 'Logout', AppColors.accentRed,
        (c) => _logout(c),
      ),
    ]),
  ];

  void _go(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _fetchNotifications());
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

// ─── Section block ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<_Tile> tiles;
  const _Section({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
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
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        _Grid(tiles: tiles),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  final List<_Tile> tiles;
  const _Grid({required this.tiles});

  @override
  Widget build(BuildContext context) {
    const columns = 4;
    const gap = 10.0;
    final rowCount = (tiles.length / columns).ceil();
    return Column(
      children: List.generate(rowCount, (rowIdx) {
        final start = rowIdx * columns;
        final end = (start + columns).clamp(0, tiles.length);
        final rowTiles = tiles.sublist(start, end);
        return Padding(
          padding: EdgeInsets.only(top: rowIdx == 0 ? 0 : gap),
          child: Row(
            children: [
              for (int i = 0; i < columns; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(
                  child: i < rowTiles.length
                      ? _TileView(tile: rowTiles[i])
                      : const SizedBox(height: 90),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _TileView extends StatelessWidget {
  final _Tile tile;
  const _TileView({required this.tile});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => tile.onTap(context),
      behavior: HitTestBehavior.opaque,
      child: AppIconTile(
        icon: tile.icon,
        color: tile.color,
        label: tile.label,
        iconSize: 22,
      ),
    );
  }
}

// ─── Data ─────────────────────────────────────────────────────────────────────

class _HubSection {
  final String title;
  final List<_Tile> tiles;
  const _HubSection(this.title, this.tiles);
}

class _Tile {
  final IconData icon;
  final String label;
  final Color color;
  final void Function(BuildContext context) onTap;
  /// Module this tile belongs to. null = always shown (e.g. Logout, Notifications).
  final String? module;
  /// Action required on [module] for this tile to be shown. Defaults to view.
  final String requiredAction;
  const _Tile(
    this.icon,
    this.label,
    this.color,
    this.onTap,
  ) : module = null, requiredAction = PermAction.view;

  const _Tile.gated(
    this.icon,
    this.label,
    this.color,
    this.onTap,
    this.module, {
    this.requiredAction = PermAction.view,
  });
}
