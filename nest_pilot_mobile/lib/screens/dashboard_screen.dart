import 'package:flutter/material.dart';
import 'package:nest_pilot_mobile/screens/secretary/payment_mark_screen.dart';
import '../theme/nest_loader.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../config/roles.dart';
import '../config/modules.dart';
import '../models/society_structure.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../services/permission_service.dart';
import '../services/notification_service.dart';
import '../services/billing_payment_service.dart';
import '../services/activity_service.dart';
import '../models/activity_model.dart';
import 'notification_list_screen.dart';
import 'login_screen.dart';
import 'super_admin/society_create_screen.dart';
import 'super_admin/building_create_screen.dart';
import 'super_admin/flat_create_screen.dart';
import 'super_admin/flats_list_screen.dart';
import 'super_admin/role_management_screen.dart';
import 'secretary/pending_members_screen.dart';
import 'secretary/notice_create_screen.dart';
import 'secretary/bills_manage_screen.dart';
import 'secretary/bills_dashboard_screen.dart';
import 'secretary/visitor_dashboard_screen.dart';
import 'secretary/member_list_screen.dart';
import 'member/notice_list_screen.dart';
import 'security/security_dashboard_screen.dart';
import 'security/current_visitors_screen.dart';
import 'common/visitor_report_screen.dart';
import 'member/complaint_list_screen.dart';
import 'member/bills_list_screen.dart';
import 'member/community/visitor_management_screen.dart';
import 'member/community/amenity_booking_screen.dart';
import 'member/community/staff_list_screen.dart';
import 'member/community/poll_list_screen.dart';
import 'services_hub_screen.dart';
import '../services/socket_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dashboard_header.dart';
import '../theme/dashboard_cards.dart';
import '../theme/app_bottom_nav.dart';

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
  int _selectedTab = 0;
  DashboardStats? _dashStats;

  List<ActivityModel> _recentActivity = const [];
  bool _loadingActivity = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _fetchOutstandingBills();
    _fetchRecentActivity();
    _fetchDashboardStats();
    _setupSocket();
  }

  Future<void> _fetchDashboardStats() async {
    if (!_isAdmin) return;
    try {
      final stats = await AdminService().getDashboardStats();
      if (mounted) setState(() => _dashStats = stats);
    } catch (e) {
      debugPrint('Dashboard stats error: $e');
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

  Future<void> _fetchRecentActivity() async {
    debugPrint(
      'RecentActivity fetch — role=${widget.user.role} isAdmin=$_isAdmin isSecurity=$_isSecurity',
    );
    if (!_isAdmin && !_isSecurity) return;
    setState(() => _loadingActivity = true);
    try {
      final items = await ActivityService().getRecent(limit: 5);
      debugPrint('RecentActivity items received: ${items.length}');
      if (mounted) setState(() => _recentActivity = items);
    } catch (e) {
      debugPrint('Activity error: $e');
    } finally {
      if (mounted) setState(() => _loadingActivity = false);
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

  bool get _isAdmin =>
      widget.user.role == UserRoles.superAdmin ||
      widget.user.role == UserRoles.societyAdmin;
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
        bottomNavigationBar: AppBottomNav(
          selectedIndex: _selectedTab,
          bottomPadding: bottomPad,
          onTap: _onNavTap,
          items: _navItems(),
        ),
        body: IndexedStack(
          index: _selectedTab,
          children: _buildTabScreens(bottomPad),
        ),
      ),
    );
  }

  List<Widget> _buildTabScreens(double bottomPad) {
    final homeTab = SafeArea(
      top: false,
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          await _fetchNotifications();
          await _fetchOutstandingBills();
          await _fetchRecentActivity();
          await _fetchDashboardStats();
        },
        color: AppColors.white,
        backgroundColor: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHero()),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad + 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_getQuickActions().isNotEmpty) ...[
                    _buildSectionHeader('Quick Actions'),
                    const SizedBox(height: 14),
                    _buildQuickActions(),
                  ],
                  if (PermissionService().canView(ModuleCodes.roles)) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader('System Management'),
                    const SizedBox(height: 14),
                    _buildSystemManagement(),
                  ],
                  if (_isMember || _isAdmin) ...[
                    const SizedBox(height: 24),
                    _buildNoticeAndEvent(),
                  ],
                  if (_isMember) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      'My Complaints',
                      onViewAll: () => _go(const ComplaintListScreen()),
                    ),
                    const SizedBox(height: 14),
                    _buildRecentComplaints(),
                  ],
                  if (_isAdmin || _isSecurity) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader('Recent Activity'),
                    const SizedBox(height: 14),
                    _buildRecentActivity(),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );

    if (_isSecretary) {
      return [
        homeTab,
        const MemberListScreen(embedded: true),
        ServicesHubScreen(user: widget.user, embedded: true),
        const BillsDashboardScreen(),
        const VisitorDashboardScreen(),
      ];
    }

    return [
      homeTab,
      _isMember ? const NoticeListScreen() : const NoticeCreateScreen(),
      ServicesHubScreen(user: widget.user, embedded: true),
      _isMember ? const BillsListScreen() : const BillsManageScreen(),
      const SizedBox.shrink(), // profile is shown as a sheet
    ];
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
            value: '0',
            label: 'Inside Now',
            color: AppColors.accentGreen,
            icon: Icons.group_outlined),
        AppHeaderStat(
            value: '0',
            label: "Today's Entries",
            color: AppColors.accentBlue,
            icon: Icons.login_outlined),
        AppHeaderStat(
            value: '$_unreadCount',
            label: 'Notifications',
            color: AppColors.accentPurple,
            icon: Icons.notifications_outlined),
        AppHeaderStat(
            value: '0',
            label: 'Daily Help',
            color: AppColors.accentPink,
            icon: Icons.cleaning_services_outlined),
      ];
    } else if (_isSuperAdmin) {
      return [
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

  // ─── Quick Actions ───────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    final actions = _getQuickActions();
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

  List<_Action> _getQuickActions() {
    List<_Action> all;
    if (_isMember) {
      all = [
        _Action(
          Icons.person_add_outlined,
          'Invite\nGuest',
          AppColors.accentBlue,
          () => _go(const VisitorManagementScreen()),
          module: ModuleCodes.visitors,
          requiredAction: PermAction.create,
        ),
        _Action(
          Icons.credit_card_outlined,
          'Pay\nMaintenance',
          AppColors.accentGreen,
          () => _go(const BillsListScreen(), refresh: _fetchOutstandingBills),
          module: ModuleCodes.bills,
        ),
        _Action(
          Icons.campaign_outlined,
          'Raise\nComplaint',
          AppColors.accentRed,
          () => _go(const ComplaintListScreen()),
          module: ModuleCodes.complaints,
          requiredAction: PermAction.create,
        ),
        _Action(
          Icons.calendar_today_outlined,
          'Book\nAmenities',
          AppColors.accentIndigo,
          () => _go(const AmenityBookingScreen()),
          module: ModuleCodes.amenities,
          requiredAction: PermAction.create,
        ),
      ];
    } else if (_isSecurity) {
      all = [
        _Action(
          Icons.directions_run_outlined,
          'Visitor\nEntry',
          AppColors.accentOrange,
          () => _go(const SecurityDashboardScreen()),
          module: ModuleCodes.visitors,
          requiredAction: PermAction.create,
        ),
        _Action(
          Icons.history_outlined,
          'Visitor\nLogs',
          AppColors.accentBlue,
          () => _go(const VisitorReportScreen()),
          module: ModuleCodes.visitors,
        ),
        _Action(
          Icons.group_outlined,
          'Inside\nNow',
          AppColors.accentGreen,
          () => _go(const CurrentVisitorsScreen()),
          module: ModuleCodes.visitors,
        ),
        _Action(
          Icons.cleaning_services_outlined,
          'Daily\nHelp',
          AppColors.accentPink,
          () => _go(const StaffListScreen()),
          module: ModuleCodes.staff,
        ),
      ];
    } else if (_isSuperAdmin) {
      all = [
        _Action(
          Icons.business_outlined,
          'Create\nSociety',
          AppColors.accentPink,
          () => _go(const SocietyCreateScreen()),
          module: ModuleCodes.buildings,
          requiredAction: PermAction.create,
        ),
        _Action(
          Icons.apartment_outlined,
          'Add\nBuilding',
          AppColors.accentBlue,
          () => _go(const BuildingCreateScreen()),
          module: ModuleCodes.buildings,
          requiredAction: PermAction.create,
        ),
        _Action(
          Icons.door_front_door_outlined,
          'Add\nFlat',
          AppColors.accentOrange,
          () => _go(const FlatCreateScreen()),
          module: ModuleCodes.buildings,
          requiredAction: PermAction.create,
        ),
        _Action(
          Icons.list_alt_outlined,
          'Flats\nList',
          AppColors.accentTeal,
          () => _go(const FlatsListScreen()),
          module: ModuleCodes.buildings,
        ),
      ];
    } else {
      all = [
        _Action(
          Icons.person_add_alt_1_outlined,
          'Pending',
          AppColors.accentAmber,
          () => _go(const PendingMembersScreen()),
          module: ModuleCodes.users,
          requiredAction: PermAction.approve,
        ),
        _Action(
          Icons.campaign_outlined,
          'Notices',
          AppColors.accentPurple,
          () => _go(const NoticeCreateScreen()),
          module: ModuleCodes.notices,
          requiredAction: PermAction.create,
        ),
        _Action(
          Icons.warning_amber_rounded,
          'Complaints',
          AppColors.accentGreen,
          () => _go(const ComplaintListScreen()),
          module: ModuleCodes.complaints,
        ),
        _Action(
          Icons.payment_outlined,
          'Payments',
          AppColors.accentBlue,
          () => _go(const PaymentMarkScreen()),
          module: ModuleCodes.bills,
          requiredAction: PermAction.update,
        ),
      ];
    }
    final perms = PermissionService();
    return all
        .where((a) => a.module == null || perms.can(a.module!, a.requiredAction))
        .toList();
  }

  // ─── System Management (SuperAdmin) ─────────────────────────────────────────

  Widget _buildSystemManagement() {
    final perms = PermissionService();
    final tiles = <_SystemTile>[
      _SystemTile(
        icon: Icons.shield_outlined,
        color: AppColors.accentIndigo,
        title: 'Roles & Permissions',
        subtitle: 'Create roles and configure module access',
        onTap: () => _go(const RoleManagementScreen()),
        module: ModuleCodes.roles,
      ),
    ].where((t) => t.module == null || perms.can(t.module!, t.requiredAction)).toList();
    if (tiles.isEmpty) return const SizedBox.shrink();

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
              Divider(height: 1, indent: 60, color: AppColors.border),
            _buildSystemTile(tiles[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemTile(_SystemTile tile) {
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

  // ─── Notice + Event ──────────────────────────────────────────────────────────

  Widget _buildNoticeAndEvent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildLatestNoticeCard()),
        const SizedBox(width: 12),
        Expanded(child: _buildUpcomingEventCard()),
      ],
    );
  }

  Widget _buildLatestNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Latest Notice',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => _go(
                  _isMember
                      ? const NoticeListScreen()
                      : const NoticeCreateScreen(),
                ),
                child: const Text(
                  'View all',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const SizedBox(
            height: 48,
            child: Center(
              child: Text(
                'No notices yet',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _go(
              _isMember ? const NoticeListScreen() : const NoticeCreateScreen(),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'View Notices',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.primary,
                    size: 13,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Event',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => _go(const PollListScreen()),
                child: const Text(
                  'View all',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const SizedBox(
            height: 48,
            child: Center(
              child: Text(
                'No upcoming events',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _go(const PollListScreen()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'View Events',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.primary,
                    size: 13,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Recent Complaints ───────────────────────────────────────────────────────

  Widget _buildRecentComplaints() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        'No recent complaints',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
      ),
    );
  }

  // ─── Recent Activity ─────────────────────────────────────────────────────────

  Widget _buildRecentActivity() {
    final cardDecoration = BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
    if (_loadingActivity && _recentActivity.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        decoration: cardDecoration,
        child: const NestLoader(size: 32, showDots: false),
      );
    }
    if (_recentActivity.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: cardDecoration,
        child: const Text(
          'No recent activity yet',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
        ),
      );
    }
    return Container(
      decoration: cardDecoration,
      child: Column(
        children: [
          for (int i = 0; i < _recentActivity.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.border,
                indent: 16,
                endIndent: 16,
              ),
            _activityTile(_recentActivity[i]),
          ],
        ],
      ),
    );
  }

  Widget _activityTile(ActivityModel a) {
    final palette = _activityPalette(a);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: palette.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(palette.icon, color: palette.color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              a.message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          if (a.createdAt != null)
            Text(
              _relativeTime(a.createdAt!),
              style: TextStyle(
                color: palette.color.withValues(alpha: 0.85),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  _ActivityPalette _activityPalette(ActivityModel a) {
    switch (a.entityType) {
      case 'VISITOR_LOG':
      case 'VISITOR':
        return _ActivityPalette(
          icon: a.action == 'DENIED'
              ? Icons.block_outlined
              : Icons.person_outline,
          color: a.action == 'DENIED'
              ? AppColors.accentRed
              : AppColors.accentGreen,
        );
      case 'BILL':
        return _ActivityPalette(
          icon: Icons.receipt_long_outlined,
          color: AppColors.accentBlue,
        );
      case 'COMPLAINT':
        return _ActivityPalette(
          icon: Icons.report_problem_outlined,
          color: a.action == 'RESOLVED' || a.action == 'CLOSED'
              ? AppColors.accentGreen
              : AppColors.accentAmber,
        );
      case 'NOTICE':
        return _ActivityPalette(
          icon: Icons.campaign_outlined,
          color: AppColors.accentPurple,
        );
      default:
        return _ActivityPalette(
          icon: Icons.history_outlined,
          color: AppColors.primary,
        );
    }
  }

  String _relativeTime(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h hr${h == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d day${d == 1 ? '' : 's'} ago';
    }
    return DateFormat('d MMM').format(when);
  }

  // ─── Section header ──────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: const Text(
              'View all',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  List<AppNavItem> _navItems() {
    if (_isSecretary) {
      return const [
        AppNavItem(Icons.home_rounded, 'Home'),
        AppNavItem(Icons.contacts_rounded, 'Residents'),
        AppNavItem(Icons.apps_rounded, 'Services'),
        AppNavItem(Icons.receipt_long_rounded, 'Bills'),
        AppNavItem(Icons.person_pin_circle_rounded, 'Visitor'),
      ];
    }
    return const [
      AppNavItem(Icons.home_rounded, 'Home'),
      AppNavItem(Icons.people_rounded, 'Community'),
      AppNavItem(Icons.apps_rounded, 'Services'),
      AppNavItem(Icons.account_balance_wallet_rounded, 'Payments'),
      AppNavItem(Icons.person_rounded, 'Profile'),
    ];
  }

  void _onNavTap(int index) {
    if (!_isSecretary && index == 4) {
      _showProfileSheet();
      return;
    }
    setState(() => _selectedTab = index);
    if (index == 3 && _isMember) _fetchOutstandingBills();
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

class _Action {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  /// Module this action belongs to (null = no gate, always shown).
  final String? module;
  /// Action required on [module] for this entry to be shown.
  final String requiredAction;
  const _Action(
    this.icon,
    this.label,
    this.color,
    this.onTap, {
    this.module,
    this.requiredAction = PermAction.view,
  });
}

class _SystemTile {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? module;
  final String requiredAction;
  const _SystemTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.module,
    this.requiredAction = PermAction.view,
  });
}

class _ActivityPalette {
  final IconData icon;
  final Color color;
  const _ActivityPalette({required this.icon, required this.color});
}
