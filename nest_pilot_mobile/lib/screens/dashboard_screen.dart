import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../config/roles.dart';
import '../models/society_structure.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/billing_payment_service.dart';
import '../services/community_service.dart';
import 'notification_list_screen.dart';
import 'login_screen.dart';
import 'module_catalog.dart';
import 'services_hub_screen.dart';
import '../services/socket_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dashboard_header.dart';
import '../theme/app_icons.dart';

/// Single unified home for every role. The dashboard adapts itself through
/// module permissions — no per-role dashboard screens anymore.
Widget homeScreenFor(UserModel user) => DashboardScreen(user: user);

class DashboardScreen extends StatefulWidget {
  final UserModel user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _unreadCount = 0;
  double _outstandingAmount = 0.0;
  bool _loadingBills = false;
  DashboardStats? _dashStats;
  SuperAdminStats? _superStats;

  // Security visitor stats (shown in the header for security roles).
  int _todayCount = 0;
  int _insideCount = 0;
  int _exitedCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _fetchOutstandingBills();
    _fetchDashboardStats();
    _fetchSecurityStats();
    _setupSocket();
  }

  Future<void> _fetchDashboardStats() async {
    try {
      if (_isSuperAdmin) {
        final stats = await AdminService().getSuperAdminStats();
        if (mounted) setState(() => _superStats = stats);
      } else if (_isSecretary) {
        final stats = await AdminService().getDashboardStats();
        if (mounted) setState(() => _dashStats = stats);
      }
    } catch (e) {
      debugPrint('Dashboard stats error: $e');
    }
  }

  Future<void> _fetchSecurityStats() async {
    if (!_isSecurity) return;
    try {
      final community = CommunityService();
      final results = await Future.wait([
        community.getInsideVisitors(),
        community.getAllSocietyVisitors(),
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
        _exitedCount = todayLogs.where((v) => v['status'] == 'EXITED').length;
      });
    } catch (e) {
      debugPrint('Security stats error: $e');
    }
  }

  @override
  void dispose() {
    SocketService().off('new_notification');
    super.dispose();
  }

  Future<void> _setupSocket() async {
    try {
      await SocketService().initSocket();
      SocketService().on('new_notification', (data) {
        if (mounted) {
          setState(() => _unreadCount++);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New notification received')),
          );
        }
      });
    } catch (e) {
      debugPrint('Socket error: $e');
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

  Future<void> _fetchOutstandingBills() async {
    if (widget.user.role != UserRoles.member) return;
    setState(() => _loadingBills = true);
    try {
      final bills = await BillService().getMyBills();
      if (mounted && bills.isNotEmpty) {
        final pending = bills
            .where(
              (b) =>
                  b.status == 'PENDING' ||
                  b.status == 'PARTIAL' ||
                  b.status == 'OVERDUE',
            )
            .toList();
        if (pending.isNotEmpty) {
          double total = 0;
          for (final b in pending) {
            total += b.amount;
          }
          setState(() {
            _outstandingAmount = total;
          });
        } else {
          setState(() => _outstandingAmount = 0.0);
        }
      }
    } catch (e) {
      debugPrint('Bills error: $e');
    } finally {
      if (mounted) setState(() => _loadingBills = false);
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

  String _roleLabel(String role) {
    switch (role) {
      case UserRoles.superAdmin:
        return 'Super Administrator';
      case UserRoles.societyAdmin:
        return 'Society Administrator';
      case UserRoles.securityGuard:
        return 'Security Officer';
      case UserRoles.member:
        return 'Resident';
      default:
        return role.replaceAll('_', ' ');
    }
  }

  bool get _isMember => widget.user.role == UserRoles.member;
  bool get _isSecurity => widget.user.role == UserRoles.securityGuard;
  bool get _isSuperAdmin => widget.user.role == UserRoles.superAdmin;
  bool get _isSecretary => widget.user.role == UserRoles.societyAdmin;

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
                      : 'U',
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
              Text(
                _roleLabel(widget.user.role),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
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

  // ─── Build ──────────────────────────────────────────────────────────────────

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
        body: _buildHome(bottomPad),
      ),
    );
  }

  Widget _buildHome(double bottomPad) {
    final modules = _moduleEntries();

    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          // Fixed hero header + "Modules" title — stay pinned while the
          // module grid below scrolls.
          _buildHero(),
          if (modules.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
              child: _buildModulesHeader(),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _fetchNotifications();
                await _fetchOutstandingBills();
                await _fetchDashboardStats();
                await _fetchSecurityStats();
              },
              color: AppColors.white,
              backgroundColor: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Module cards — one per module, filtered by permissions.
                    if (modules.isNotEmpty) _buildModulesGrid(modules),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Modules grid ────────────────────────────────────────────────────────────

  /// One card per catalogue tile — the dashboard mirrors the services hub:
  /// every tile the user's permissions allow there shows here too, so the
  /// two screens can never drift apart. Alerts and Profile are appended as
  /// dashboard-only extras.
  List<_ModuleEntry> _moduleEntries() {
    final sections = filterModuleSections(masterModuleSections());
    return [
      for (final section in sections)
        for (final tile in section.tiles)
          _ModuleEntry(
            tile.icon,
            tile.label,
            tile.color,
            () => tile.onTap(context),
          ),
      _ModuleEntry(
        Icons.apps_rounded, 'Services', AppColors.accentGreen,
        () => _go(ServicesHubScreen(user: widget.user, embedded: true)),
      ),
      _ModuleEntry(
        Icons.notifications_outlined, 'Alerts', AppColors.accentRed,
        _showNotifications,
      ),
      _ModuleEntry(
        Icons.person_outline, 'Profile', AppColors.accentPurple,
        _showProfileSheet,
      ),
    ];
  }

  Widget _buildModulesHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Modules',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'Tap to open',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesGrid(List<_ModuleEntry> entries) {
    const columns = 3;
    const gap = 12.0;
    final rowCount = (entries.length / columns).ceil();
    return Column(
      children: List.generate(rowCount, (rowIdx) {
        final start = rowIdx * columns;
        final end = (start + columns).clamp(0, entries.length);
        final row = entries.sublist(start, end);
        return Padding(
          padding: EdgeInsets.only(top: rowIdx == 0 ? 0 : gap),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < columns; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(
                  child: i < row.length
                      ? AppModuleCard(
                          icon: row[i].icon,
                          color: row[i].color,
                          label: row[i].label,
                          onTap: row[i].onTap,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  // ─── Hero ───────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    final hasFlat = (widget.user.flatNumber ?? '').isNotEmpty;
    final hasSociety = (widget.user.societyName ?? '').isNotEmpty;

    String subtitle;
    if (hasFlat && hasSociety) {
      subtitle = 'Flat ${widget.user.flatNumber} · ${widget.user.societyName}';
    } else if (hasFlat) {
      subtitle = 'Flat ${widget.user.flatNumber}';
    } else if (hasSociety) {
      subtitle = widget.user.societyName!;
    } else {
      subtitle = _roleLabel(widget.user.role);
    }

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
      subtitle: subtitle,
      unreadCount: _unreadCount,
      onNotificationTap: _showNotifications,
      stats: _headerStats(),
    );
  }

  List<AppHeaderStat> _headerStats() {
    final currency =
        NumberFormat.currency(locale: 'HI', symbol: '₹', decimalDigits: 0);

    if (_isMember) {
      return [
        AppHeaderStat(
          value: _loadingBills
              ? '...'
              : (_outstandingAmount > 0
                  ? currency.format(_outstandingAmount)
                  : '₹0'),
          label: 'Due',
          color: AppColors.accentAmber,
          icon: Icons.account_balance_wallet_outlined,
        ),
        AppHeaderStat(
            value: '0',
            label: 'Visitors',
            color: AppColors.accentBlue,
            icon: Icons.person_pin_circle_outlined),
        AppHeaderStat(
            value: '$_unreadCount',
            label: 'Notices',
            color: AppColors.accentPurple,
            icon: Icons.notifications_outlined),
        AppHeaderStat(
            value: '0',
            label: 'Complaints',
            color: AppColors.accentRed,
            icon: Icons.report_problem_outlined),
      ];
    } else if (_isSecurity) {
      return [
        AppHeaderStat(
            value: '$_todayCount',
            label: "Today's Entry",
            color: AppColors.accentBlue,
            icon: Icons.login_outlined),
        AppHeaderStat(
            value: '$_insideCount',
            label: 'Inside',
            color: AppColors.accentGreen,
            icon: Icons.group_outlined),
        AppHeaderStat(
            value: '$_exitedCount',
            label: 'Exited',
            color: AppColors.accentOrange,
            icon: Icons.logout_outlined),
        AppHeaderStat(
            value: '$_totalCount',
            label: 'Total Visitors',
            color: AppColors.accentPurple,
            icon: Icons.people_outline_rounded),
      ];
    } else if (_isSuperAdmin) {
      return [
        AppHeaderStat(
            value: '${_superStats?.totalSocieties ?? 0}',
            label: 'Societies',
            color: AppColors.accentOrange,
            icon: Icons.business_outlined),
        AppHeaderStat(
            value: '${_superStats?.totalBuildings ?? 0}',
            label: 'Buildings',
            color: AppColors.accentBlue,
            icon: Icons.apartment_outlined),
        AppHeaderStat(
            value: '${_superStats?.totalFlats ?? 0}',
            label: 'Flats',
            color: AppColors.accentPurple,
            icon: Icons.door_front_door_outlined),
        AppHeaderStat(
            value: '${_superStats?.totalMembers ?? 0}',
            label: 'Members',
            color: AppColors.accentGreen,
            icon: Icons.people_outlined),
      ];
    } else {
      final s = _dashStats;
      return [
        AppHeaderStat(
            value: s == null ? '...' : '${s.totalResidents}',
            label: 'Residents',
            color: AppColors.accentBlue,
            icon: Icons.contacts_outlined),
        AppHeaderStat(
            value: s == null ? '...' : '${s.totalNotices}',
            label: 'Notices',
            color: AppColors.accentPurple,
            icon: Icons.notifications_outlined),
        AppHeaderStat(
            value: s == null ? '...' : '${s.totalComplaints}',
            label: 'Complaints',
            color: AppColors.accentRed,
            icon: Icons.report_problem_outlined),
      ];
    }
  }

  // ─── Navigation helper ───────────────────────────────────────────────────────

  void _go(Widget screen, {VoidCallback? refresh}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => refresh?.call());
  }
}

// ─── Data classes ────────────────────────────────────────────────────────────

class _ModuleEntry {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ModuleEntry(
    this.icon,
    this.label,
    this.color,
    this.onTap,
  );
}

