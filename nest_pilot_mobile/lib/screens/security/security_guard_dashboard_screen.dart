import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/community_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dashboard_header.dart';
import '../login_screen.dart';
import '../notification_list_screen.dart';
import 'verify_passcode_screen.dart';
import 'walk_in_entry_screen.dart';
import 'current_visitors_screen.dart';
import '../common/visitor_report_screen.dart';
import '../member/community/vehicle_list_screen.dart';
import '../member/notice_list_screen.dart';
import '../secretary/event_manage_screen.dart';
import 'service_staff_screen.dart';

class SecurityGuardDashboardScreen extends StatefulWidget {
  final UserModel user;
  const SecurityGuardDashboardScreen({super.key, required this.user});

  @override
  State<SecurityGuardDashboardScreen> createState() =>
      _SecurityGuardDashboardScreenState();
}

class _SecurityGuardDashboardScreenState
    extends State<SecurityGuardDashboardScreen> {
  final CommunityService _community = CommunityService();

  int _unreadCount = 0;
  int _todayCount = 0;
  int _insideCount = 0;
  int _exitedCount = 0;
  int _totalCount = 0;

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
    } catch (_) {}
  }

  Future<void> _fetchStats() async {
    try {
      final results = await Future.wait([
        _community.getInsideVisitors(),
        _community.getAllSocietyVisitors(),
      ]);

      if (!mounted) return;

      final inside = results[0];
      final all = results[1];
      final today = DateTime.now();

      bool isToday(dynamic v) {
        try {
          final t = DateTime.parse(v['entry_time'] as String);
          return t.year == today.year &&
              t.month == today.month &&
              t.day == today.day;
        } catch (_) {
          return false;
        }
      }

      final todayLogs = all.where(isToday).toList();

      setState(() {
        _insideCount = inside.length;
        _totalCount = all.length;
        _todayCount = todayLogs.length;
        _exitedCount = todayLogs
            .where((v) => v['status'] == 'EXITED')
            .length;
      });
    } catch (_) {}
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
    ).then((_) => _fetchAll());
  }

  void _showNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationListScreen()),
    ).then((_) => _fetchNotifications());
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

  @override
  Widget build(BuildContext context) {
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
                  subtitle: 'Security Officer',
                  unreadCount: _unreadCount,
                  onNotificationTap: _showNotifications,
                  stats: [
                    AppHeaderStat(
                      value: '$_todayCount',
                      label: "Today's Entry",
                      color: AppColors.accentBlue,
                      icon: Icons.login_outlined,
                    ),
                    AppHeaderStat(
                      value: '$_insideCount',
                      label: 'Inside',
                      color: AppColors.accentGreen,
                      icon: Icons.group_outlined,
                    ),
                    AppHeaderStat(
                      value: '$_exitedCount',
                      label: 'Exited',
                      color: AppColors.accentOrange,
                      icon: Icons.logout_outlined,
                    ),
                    AppHeaderStat(
                      value: '$_totalCount',
                      label: 'Total Visitors',
                      color: AppColors.accentPurple,
                      icon: Icons.people_outline_rounded,
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad + 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader('Gate Actions'),
                    const SizedBox(height: 14),
                    _buildTileCard([
                      _Tile(
                        icon: Icons.vpn_key_rounded,
                        color: AppColors.accentGreen,
                        title: 'Verify Pass Code',
                        subtitle: 'Check a resident\'s pre-approved invite',
                        onTap: () => _go(const VerifyPasscodeScreen()),
                      ),
                      _Tile(
                        icon: Icons.directions_walk_rounded,
                        color: AppColors.accentBlue,
                        title: 'Walk-in / Delivery',
                        subtitle: 'Log an unannounced visitor or delivery',
                        onTap: () => _go(const WalkInEntryScreen()),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Monitor'),
                    const SizedBox(height: 14),
                    _buildTileCard([
                      _Tile(
                        icon: Icons.groups_outlined,
                        color: AppColors.accentTeal,
                        title: 'Inside Now',
                        subtitle: '$_insideCount visitor(s) currently on premises',
                        onTap: () => _go(const CurrentVisitorsScreen()),
                      ),
                      _Tile(
                        icon: Icons.fact_check_outlined,
                        color: AppColors.accentPurple,
                        title: 'Visitor Logs',
                        subtitle: 'Browse complete entry & exit history',
                        onTap: () => _go(const VisitorReportScreen()),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Community'),
                    const SizedBox(height: 14),
                    _buildTileCard([
                      _Tile(
                        icon: Icons.directions_car_outlined,
                        color: AppColors.accentTeal,
                        title: 'Vehicles',
                        subtitle: 'View registered vehicles in the society',
                        onTap: () => _go(const VehicleListScreen()),
                      ),
                      _Tile(
                        icon: Icons.campaign_outlined,
                        color: AppColors.accentIndigo,
                        title: 'Notices',
                        subtitle: 'View society notices and announcements',
                        onTap: () => _go(const NoticeListScreen()),
                      ),
                      _Tile(
                        icon: Icons.event_outlined,
                        color: AppColors.accentPink,
                        title: 'Events',
                        subtitle: 'View upcoming society events',
                        onTap: () => _go(const EventManageScreen()),
                      ),
                      _Tile(
                        icon: Icons.badge_outlined,
                        color: AppColors.accentOrange,
                        title: 'Service Staff',
                        subtitle: 'Add and manage society service staff',
                        onTap: () => _go(const ServiceStaffScreen()),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildLogoutCard(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Logout card ─────────────────────────────────────────────────────────────

  Widget _buildLogoutCard() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB71C1C), AppColors.accentRed],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentRed.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.30),
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.logout_rounded, color: AppColors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Logout',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sign out of this device',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.70),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.white.withValues(alpha: 0.60),
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

  // ─── Tile card ───────────────────────────────────────────────────────────────

  Widget _buildTileCard(List<_Tile> tiles) {
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
            _buildTile(tiles[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildTile(_Tile tile) {
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
}

class _Tile {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _Tile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
