import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../config/roles.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/billing_payment_service.dart';
import 'notification_list_screen.dart';
import 'login_screen.dart';
import 'super_admin/society_create_screen.dart';
import 'super_admin/building_create_screen.dart';
import 'super_admin/flat_create_screen.dart';
import 'super_admin/flats_list_screen.dart';
import 'secretary/pending_members_screen.dart';
import 'secretary/notice_create_screen.dart';
import 'secretary/bill_create_screen.dart';
import 'secretary/bills_manage_screen.dart';
import 'secretary/amenity_management_screen.dart';
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
import '../services/socket_service.dart';
import '../theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _fetchOutstandingBills();
    _setupSocket();
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

  bool get _isAdmin =>
      widget.user.role == UserRoles.superAdmin ||
      widget.user.role == UserRoles.societyAdmin;
  bool get _isMember => widget.user.role == UserRoles.member;
  bool get _isSecurity => widget.user.role == UserRoles.securityGuard;
  bool get _isSuperAdmin => widget.user.role == UserRoles.superAdmin;

  // ─── Profile sheet ──────────────────────────────────────────────────────────

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
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
                  color: AppColors.white.withValues(alpha: 0.25),
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
                    color: AppColors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.user.fullName,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _roleLabel(widget.user.role),
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.60),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.user.mobile,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.60),
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
                    color: AppColors.black,
                  ),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.black,
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
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        bottomNavigationBar: AppBottomNav(
          selectedIndex: _selectedTab,
          bottomPadding: bottomPad,
          onTap: (i) {
            setState(() => _selectedTab = i);
            _onNavTap(i);
          },
          items: const [
            AppNavItem(Icons.home_rounded, 'Home'),
            AppNavItem(Icons.people_rounded, 'Community'),
            AppNavItem(Icons.apps_rounded, 'Services'),
            AppNavItem(Icons.account_balance_wallet_rounded, 'Payments'),
            AppNavItem(Icons.person_rounded, 'Profile'),
          ],
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              await _fetchNotifications();
              await _fetchOutstandingBills();
            },
            color: AppColors.black,
            backgroundColor: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHero()),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildMyOverview(),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Quick Actions'),
                      const SizedBox(height: 14),
                      _buildQuickActions(),
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
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Hero ───────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    final screenWidth = MediaQuery.of(context).size.width;
    final firstName = widget.user.fullName.split(' ').first;
    final hasFlat = (widget.user.flatNumber ?? '').isNotEmpty;
    final hasSociety = (widget.user.societyName ?? '').isNotEmpty;

    return Container(
      color: const Color(0xFF0A0A0A),
      child: Stack(
        children: [
          // Building image — right half, fades in from left edge
          Positioned(
            right: 0,
            top: 20,
            bottom: -40,
            width: screenWidth * 0.55,
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.80, 0.90, 1.0],
                colors: [
                  Colors.transparent,
                  Color.fromARGB(255, 0, 0, 0),
                  Colors.white,
                  Colors.white,
                ],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/dash2.png',
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),
          // Top fade — darkens status bar / nav row area
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 200,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFF0A0A0A), Colors.transparent],
                ),
              ),
            ),
          ),
          // Bottom fade so stats section blends seamlessly
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, const Color(0xFF0A0A0A)],
                ),
              ),
            ),
          ),
          // Content (determines Stack height)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _showProfileSheet,
                        child: Icon(
                          Icons.menu_rounded,
                          color: AppColors.white.withValues(alpha: 0.9),
                          size: 26,
                        ),
                      ),
                      const Spacer(),
                      _buildNotifBell(),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Text(
                        '${_getGreeting()}, $firstName',
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.85),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('👋', style: TextStyle(fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasFlat
                        ? 'Flat ${widget.user.flatNumber}'
                        : _roleLabel(widget.user.role),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  if (hasSociety)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.user.societyName!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifBell() {
    return GestureDetector(
      onTap: _showNotifications,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            color: AppColors.white.withValues(alpha: 0.9),
            size: 26,
          ),
          if (_unreadCount > 0)
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0A0A0A),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.60),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── My Overview (stats grid) ────────────────────────────────────────────────

  Widget _buildMyOverview() => _buildStatsGrid();

  Widget _buildStatsGrid() {
    final cards = _getStatCards();
    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: DashStatCard(
              icon: cards[i].icon,
              color: cards[i].color,
              value: cards[i].value,
              label: cards[i].label,
              onTap: cards[i].onTap,
            ),
          ),
        ],
      ],
    );
  }

  List<_StatCard> _getStatCards() {
    final currency = NumberFormat.currency(
      locale: 'HI',
      symbol: '₹',
      decimalDigits: 0,
    );

    if (_isMember) {
      return [
        _StatCard(
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.accentAmber,
          value: _loadingBills
              ? '...'
              : (_outstandingAmount > 0
                    ? currency.format(_outstandingAmount)
                    : '₹0'),
          label: 'Maintenance Due',
          onTap: () =>
              _go(const BillsListScreen(), refresh: _fetchOutstandingBills),
        ),
        _StatCard(
          icon: Icons.person_pin_circle_outlined,
          color: AppColors.accentBlue,
          value: '0',
          label: 'Visitors Today',
          onTap: () => _go(const VisitorManagementScreen()),
        ),
        _StatCard(
          icon: Icons.notifications_outlined,
          color: AppColors.accentPurple,
          value: '$_unreadCount',
          label: 'Unread Notices',
          onTap: _showNotifications,
        ),
        _StatCard(
          icon: Icons.report_problem_outlined,
          color: AppColors.accentRed,
          value: '0',
          label: 'Open Complaints',
          onTap: () => _go(const ComplaintListScreen()),
        ),
      ];
    } else if (_isSecurity) {
      return [
        _StatCard(
          icon: Icons.group_outlined,
          color: AppColors.accentGreen,
          value: '0',
          label: 'Inside Now',
          onTap: () => _go(const CurrentVisitorsScreen()),
        ),
        _StatCard(
          icon: Icons.login_outlined,
          color: AppColors.accentBlue,
          value: '0',
          label: "Today's Entries",
          onTap: () => _go(const VisitorReportScreen()),
        ),
        _StatCard(
          icon: Icons.notifications_outlined,
          color: AppColors.accentPurple,
          value: '$_unreadCount',
          label: 'Notifications',
          onTap: _showNotifications,
        ),
        _StatCard(
          icon: Icons.cleaning_services_outlined,
          color: AppColors.accentPink,
          value: '0',
          label: 'Daily Help',
          onTap: () => _go(const StaffListScreen()),
        ),
      ];
    } else if (_isSuperAdmin) {
      return [
        _StatCard(
          icon: Icons.business_outlined,
          color: AppColors.accentOrange,
          value: '0',
          label: 'Societies',
          onTap: () => _go(const SocietyCreateScreen()),
        ),
        _StatCard(
          icon: Icons.apartment_outlined,
          color: AppColors.accentBlue,
          value: '0',
          label: 'Buildings',
          onTap: () => _go(const BuildingCreateScreen()),
        ),
        _StatCard(
          icon: Icons.door_front_door_outlined,
          color: AppColors.accentPurple,
          value: '0',
          label: 'Flats',
          onTap: () => _go(const FlatsListScreen()),
        ),
        _StatCard(
          icon: Icons.people_outlined,
          color: AppColors.accentGreen,
          value: '0',
          label: 'Members',
          onTap: () => _go(const FlatsListScreen()),
        ),
      ];
    } else {
      return [
        _StatCard(
          icon: Icons.person_add_outlined,
          color: AppColors.accentAmber,
          value: '0',
          label: 'Pending',
          onTap: () => _go(const PendingMembersScreen()),
        ),
        _StatCard(
          icon: Icons.contacts_outlined,
          color: AppColors.accentBlue,
          value: '0',
          label: 'Residents',
          onTap: () => _go(const MemberListScreen()),
        ),
        _StatCard(
          icon: Icons.notifications_outlined,
          color: AppColors.accentPurple,
          value: '$_unreadCount',
          label: 'Notices',
          onTap: _showNotifications,
        ),
        _StatCard(
          icon: Icons.report_problem_outlined,
          color: AppColors.accentRed,
          value: '0',
          label: 'Complaints',
          onTap: () => _go(const ComplaintListScreen()),
        ),
      ];
    }
  }

  // ─── Quick Actions ───────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    final actions = _getQuickActions();
    return Row(
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
    );
  }

  List<_Action> _getQuickActions() {
    if (_isMember) {
      return [
        _Action(
          Icons.person_add_outlined,
          'Invite\nGuest',
          AppColors.accentBlue,
          () => _go(const VisitorManagementScreen()),
        ),
        _Action(
          Icons.credit_card_outlined,
          'Pay\nMaintenance',
          AppColors.accentGreen,
          () => _go(const BillsListScreen(), refresh: _fetchOutstandingBills),
        ),
        _Action(
          Icons.campaign_outlined,
          'Raise\nComplaint',
          AppColors.accentRed,
          () => _go(const ComplaintListScreen()),
        ),
        _Action(
          Icons.calendar_today_outlined,
          'Book\nAmenities',
          AppColors.accentIndigo,
          () => _go(const AmenityBookingScreen()),
        ),
      ];
    } else if (_isSecurity) {
      return [
        _Action(
          Icons.directions_run_outlined,
          'Visitor\nEntry',
          AppColors.accentOrange,
          () => _go(const SecurityDashboardScreen()),
        ),
        _Action(
          Icons.history_outlined,
          'Visitor\nLogs',
          AppColors.accentBlue,
          () => _go(const VisitorReportScreen()),
        ),
        _Action(
          Icons.group_outlined,
          'Inside\nNow',
          AppColors.accentGreen,
          () => _go(const CurrentVisitorsScreen()),
        ),
        _Action(
          Icons.cleaning_services_outlined,
          'Daily\nHelp',
          AppColors.accentPink,
          () => _go(const StaffListScreen()),
        ),
      ];
    } else if (_isSuperAdmin) {
      return [
        _Action(
          Icons.business_outlined,
          'Create\nSociety',
          AppColors.accentPink,
          () => _go(const SocietyCreateScreen()),
        ),
        _Action(
          Icons.apartment_outlined,
          'Add\nBuilding',
          AppColors.accentBlue,
          () => _go(const BuildingCreateScreen()),
        ),
        _Action(
          Icons.door_front_door_outlined,
          'Add\nFlat',
          AppColors.accentOrange,
          () => _go(const FlatCreateScreen()),
        ),
        _Action(
          Icons.list_alt_outlined,
          'Flats\nList',
          AppColors.accentTeal,
          () => _go(const FlatsListScreen()),
        ),
      ];
    } else {
      return [
        _Action(
          Icons.person_add_alt_1_outlined,
          'Pending',
          AppColors.accentAmber,
          () => _go(const PendingMembersScreen()),
        ),
        _Action(
          Icons.campaign_outlined,
          'Notices',
          AppColors.accentPurple,
          () => _go(const NoticeCreateScreen()),
        ),
        _Action(
          Icons.add_card_outlined,
          'Create\nBill',
          AppColors.accentGreen,
          () => _go(const BillCreateScreen()),
        ),
        _Action(
          Icons.contacts_outlined,
          'Residents',
          AppColors.accentBlue,
          () => _go(const MemberListScreen()),
        ),
      ];
    }
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
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.07)),
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
                  color: AppColors.white,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.accentAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.campaign_outlined,
                  color: AppColors.accentAmber,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Water Supply\nMaintenance',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tomorrow, 10:00 AM\nto 12:00 PM',
                      style: TextStyle(
                        color: Color(0x7AFFFFFF),
                        fontSize: 10.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _go(
              _isMember ? const NoticeListScreen() : const NoticeCreateScreen(),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'View Notice',
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
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.07)),
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
                  color: AppColors.white,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('MMM').format(now).toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      DateFormat('dd').format(now),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Annual General\nMeeting',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Community Hall\n7:00 PM',
                      style: TextStyle(
                        color: Color(0x7AFFFFFF),
                        fontSize: 10.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _go(const PollListScreen()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'View Event',
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
    return Column(
      children: [
        _complaintTile(
          title: 'Lift not working',
          status: 'In Progress',
          statusColor: AppColors.accentAmber,
          date: 'Raised on 20 May, 10:30 AM',
          id: '#C-1245',
        ),
        const SizedBox(height: 10),
        _complaintTile(
          title: 'Water Leakage',
          status: 'Resolved',
          statusColor: AppColors.accentGreen,
          date: 'Resolved on 18 May, 09:15 AM',
          id: '#C-1244',
        ),
      ],
    );
  }

  Widget _complaintTile({
    required String title,
    required String status,
    required Color statusColor,
    required String date,
    required String id,
  }) {
    return GestureDetector(
      onTap: () => _go(const ComplaintListScreen()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.report_problem_outlined,
                color: statusColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    date,
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.42),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  id,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.white.withValues(alpha: 0.28),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
                color: AppColors.white,
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

  void _onNavTap(int index) {
    if (index == 0) return;
    Widget? screen;
    switch (index) {
      case 1:
        screen = _isMember
            ? const NoticeListScreen()
            : const NoticeCreateScreen();
        break;
      case 2:
        screen = _isMember
            ? const AmenityBookingScreen()
            : _isSecurity
            ? const SecurityDashboardScreen()
            : const AmenityManagementScreen();
        break;
      case 3:
        screen = _isMember
            ? const BillsListScreen()
            : const BillsManageScreen();
        break;
      case 4:
        setState(() => _selectedTab = 0);
        _showProfileSheet();
        return;
    }
    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen!)).then((
        _,
      ) {
        if (mounted) setState(() => _selectedTab = 0);
        if (index == 3 && _isMember) _fetchOutstandingBills();
      });
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

class _StatCard {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final VoidCallback onTap;
  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.onTap,
  });
}

class _Action {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Action(this.icon, this.label, this.color, this.onTap);
}
