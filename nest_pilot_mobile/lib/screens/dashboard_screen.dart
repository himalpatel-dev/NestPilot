import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../config/roles.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/billing_payment_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
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
import 'secretary/payment_mark_screen.dart';
import 'secretary/amenity_management_screen.dart';
import 'secretary/vehicle_management_screen.dart';
import 'secretary/member_list_screen.dart';
import 'member/notice_list_screen.dart';
import 'security/security_dashboard_screen.dart';
import 'security/current_visitors_screen.dart';
import 'common/visitor_report_screen.dart';
import 'member/complaint_list_screen.dart';
import 'member/bills_list_screen.dart';
import 'member/ledger_screen.dart';
import 'member/community/visitor_management_screen.dart';
import 'member/community/vehicle_list_screen.dart';
import 'member/community/amenity_booking_screen.dart';
import 'member/community/staff_list_screen.dart';
import 'member/community/poll_list_screen.dart';
import 'member/community/document_list_screen.dart';
import '../services/socket_service.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _unreadCount = 0;
  double _outstandingAmount = 0.0;
  DateTime _dueDate = DateTime(2024, 6, 15);
  bool _loadingBills = false;

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
            .where((b) =>
                b.status == 'PENDING' ||
                b.status == 'PARTIAL' ||
                b.status == 'OVERDUE')
            .toList();
        if (pending.isNotEmpty) {
          double total = 0;
          DateTime earliest = pending.first.dueDate;
          for (final b in pending) {
            total += b.amount;
            if (b.dueDate.isBefore(earliest)) earliest = b.dueDate;
          }
          setState(() {
            _outstandingAmount = total;
            _dueDate = earliest;
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
    if (h < 12) return 'Good morning! 👋';
    if (h < 17) return 'Good afternoon! 👋';
    return 'Good evening! 👋';
  }

  // ─── Profile sheet ──────────────────────────────────────────────────────────

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 38,
                backgroundColor: AppColors.cardBackground,
                child: Text(
                  widget.user.fullName.isNotEmpty
                      ? widget.user.fullName[0].toUpperCase()
                      : 'U',
                  style: AppTextStyles.profileInitial,
                ),
              ),
              const SizedBox(height: 14),
              Text(widget.user.fullName, style: AppTextStyles.drawerName),
              const SizedBox(height: 4),
              Text(
                widget.user.role.replaceAll('_', ' '),
                style: AppTextStyles.drawerSubtext(),
              ),
              const SizedBox(height: 2),
              Text(widget.user.mobile, style: AppTextStyles.drawerSubtext()),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Logout', style: AppTextStyles.logoutLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white.withValues(alpha: 0.12),
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
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _fetchNotifications();
                      await _fetchOutstandingBills();
                    },
                    color: AppColors.primaryDark,
                    backgroundColor: AppColors.cardBackground,
                    child: Container(
                      color: AppColors.cardBackground,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPad + 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoCard(),
                            const SizedBox(height: 28),
                            _buildSectionLabel('Quick Actions'),
                            const SizedBox(height: 14),
                            _buildRoleMenu(),
                            if (widget.user.role == UserRoles.member) ...[
                              const SizedBox(height: 28),
                              _buildPromoCard(),
                            ],
                          ],
                        ),
                      ),
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

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    String flatInfo;
    if (widget.user.flatNumber != null && widget.user.societyName != null) {
      flatInfo = '${widget.user.flatNumber}, ${widget.user.societyName}';
    } else if (widget.user.societyName != null) {
      flatInfo = widget.user.societyName!;
    } else {
      flatInfo = widget.user.role.replaceAll('_', ' ');
    }

    return SizedBox(
      height: 262,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ① Full-bleed hero image
          Image.asset(
            'assets/society_3.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),

          // ② Cinematic scrim — clear at top, deep dark at bottom
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.30, 0.65, 1.0],
                colors: [
                  Color(0x33000000), // soft dark at very top
                  Color(0x00000000), // transparent window — image shines
                  Color(0xCC0A1929), // darkens toward text zone
                  Color(0xF50A1929), // near-opaque base for text
                ],
              ),
            ),
          ),

          // ③ Top controls — floating over image
          Positioned(
            top: 12,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Society name tag
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.home_work_rounded,
                            color: AppColors.accent,
                            size: 13,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'NestPilot',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Notification + avatar
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _glassIconBtn(
                          icon: Icons.notifications_none_rounded,
                          onTap: _showNotifications,
                        ),
                        if (_unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.badgeGold,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF0A1929),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$_unreadCount',
                                  style: AppTextStyles.badgeLabel,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _showProfileSheet,
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.accent, Color(0xFF8A5E20)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 17,
                          backgroundColor: const Color(0xFF0A1929),
                          child: Text(
                            widget.user.fullName.isNotEmpty
                                ? widget.user.fullName[0].toUpperCase()
                                : 'U',
                            style: AppTextStyles.avatarInitial,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ④ Bottom content — greeting, name, location
          Positioned(
            bottom: 24,
            left: 22,
            right: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Greeting micro-label
                Text(
                  _getGreeting().replaceAll(' 👋', '').toUpperCase(),
                  style: TextStyle(
                    color: AppColors.accent.withValues(alpha: 0.90),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.8,
                  ),
                ),

                const SizedBox(height: 5),

                // Name — large, bold, white
                Text(
                  widget.user.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 16),

                // Location pill — glassmorphism
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.accent,
                            size: 13,
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Text(
                              flatInfo,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.locationText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassIconBtn({required IconData icon, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.20),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      );

  // ─── Info / outstanding card ─────────────────────────────────────────────────

  Widget _buildInfoCard() {
    final currency = NumberFormat.currency(
      locale: 'HI',
      symbol: '₹ ',
      decimalDigits: 2,
    );
    final dateF = DateFormat('dd MMM yyyy');

    const cardDecoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 0.50, 1.0],
        colors: [
          Color(0xFF0A1929),
          Color(0xFF0F2440),
          Color(0xFF1A3A5C),
        ],
      ),
      borderRadius: BorderRadius.all(Radius.circular(24)),
    );

    const cardShadow = [
      BoxShadow(
        color: Color(0x660A1929),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ];

    // Admin / non-member welcome card
    if (widget.user.role != UserRoles.member) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: cardDecoration.copyWith(
          boxShadow: cardShadow,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WELCOME BACK',
                    style: TextStyle(
                      color: AppColors.accent.withValues(alpha: 0.85),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.user.role.replaceAll('_', ' '),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your society operations smoothly.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.48),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.28),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.admin_panel_settings_outlined,
                color: AppColors.accent,
                size: 28,
              ),
            ),
          ],
        ),
      );
    }

    // Member outstanding card
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: cardDecoration.copyWith(
        boxShadow: cardShadow,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL OUTSTANDING',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.52),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 10),
                _loadingBills
                    ? const SizedBox(
                        height: 32,
                        width: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: AppColors.accent,
                        ),
                      )
                    : Text(
                        currency.format(_outstandingAmount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                          letterSpacing: -0.5,
                        ),
                      ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _outstandingAmount > 0
                            ? const Color(0xFFFF8C42)
                            : const Color(0xFF4ADE80),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _outstandingAmount > 0
                          ? 'Due on ${dateF.format(_dueDate)}'
                          : 'All cleared  ✓',
                      style: TextStyle(
                        color: _outstandingAmount > 0
                            ? const Color(0xFFFF8C42)
                            : const Color(0xFF4ADE80),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: () => _go(
              const BillsListScreen(),
              refresh: _fetchOutstandingBills,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.32),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.accent,
                    size: 22,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'View\nBills',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
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

  // ─── Section label ───────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String title) => Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(title, style: AppTextStyles.sectionTitle),
        ],
      );

  // ─── Role menus (all items inline — no "More" button) ────────────────────────

  Widget _buildRoleMenu() {
    if (widget.user.role == UserRoles.superAdmin) return _superAdminMenu();
    if (widget.user.role == UserRoles.societyAdmin) return _societyAdminMenu();
    if (widget.user.role == UserRoles.member) return _memberMenu();
    if (widget.user.role == UserRoles.securityGuard) return _securityMenu();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          'No actions available for role: ${widget.user.role}',
          style: AppTextStyles.cardLabel,
        ),
      ),
    );
  }

  Widget _superAdminMenu() => _grid([
        _Item(Icons.business_outlined, 'Create Society', () => _go(const SocietyCreateScreen()), const Color(0xFFEC407A)),
        _Item(Icons.apartment_outlined, 'Add Building', () => _go(const BuildingCreateScreen()), const Color(0xFF42A5F5)),
        _Item(Icons.door_front_door_outlined, 'Add Flat', () => _go(const FlatCreateScreen()), const Color(0xFFFF7043)),
        _Item(Icons.list_alt_outlined, 'Flats List', () => _go(const FlatsListScreen()), const Color(0xFF26A69A)),
      ]);

  Widget _societyAdminMenu() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _grid([
            _Item(Icons.person_add_alt_1_outlined, 'Pending', () => _go(const PendingMembersScreen()), const Color(0xFFFFA726)),
            _Item(Icons.contacts_outlined, 'Residents', () => _go(const MemberListScreen()), const Color(0xFF42A5F5)),
            _Item(Icons.campaign_outlined, 'Notices', () => _go(const NoticeCreateScreen()), const Color(0xFFAB47BC)),
            _Item(Icons.add_card_outlined, 'Create Bill', () => _go(const BillCreateScreen()), const Color(0xFF66BB6A)),
            _Item(Icons.receipt_long_outlined, 'Manage Bills', () => _go(const BillsManageScreen()), const Color(0xFF26A69A)),
            _Item(Icons.payments_outlined, 'Payment', () => _go(const PaymentMarkScreen()), const Color(0xFFFF7043)),
            _Item(Icons.report_problem_outlined, 'Complaints', () => _go(const ComplaintListScreen()), const Color(0xFFEC407A)),
            _Item(Icons.pool_outlined, 'Amenities', () => _go(const AmenityManagementScreen()), const Color(0xFF5C6BC0)),
          ]),
          const SizedBox(height: 28),
          _buildSectionLabel('Operations & Tools'),
          const SizedBox(height: 14),
          _grid([
            _Item(Icons.poll_outlined, 'Polls', () => _go(const PollListScreen()), const Color(0xFFAB47BC)),
            _Item(Icons.directions_run_outlined, 'Visitor Entry', () => _go(const SecurityDashboardScreen()), const Color(0xFFFF7043)),
            _Item(Icons.group_work_outlined, 'Visitor Logs', () => _go(const VisitorReportScreen()), const Color(0xFF42A5F5)),
            _Item(Icons.directions_car_outlined, 'Vehicles', () => _go(const VehicleManagementScreen()), const Color(0xFF26A69A)),
            _Item(Icons.folder_open_outlined, 'Documents', () => _go(const DocumentListScreen()), const Color(0xFFFFA726)),
            _Item(Icons.cleaning_services_outlined, 'Daily Help', () => _go(const StaffListScreen()), const Color(0xFFEC407A)),
          ]),
        ],
      );

  Widget _memberMenu() => _grid([
        _Item(Icons.campaign_outlined, 'Notices', () => _go(const NoticeListScreen()), const Color(0xFFAB47BC)),
        _Item(Icons.receipt_long_outlined, 'Bills', () => _go(const BillsListScreen(), refresh: _fetchOutstandingBills), const Color(0xFFFF7043)),
        _Item(Icons.person_add_outlined, 'Visitor Pass', () => _go(const VisitorManagementScreen()), const Color(0xFF42A5F5)),
        _Item(Icons.headset_mic_outlined, 'Complaints', () => _go(const ComplaintListScreen()), const Color(0xFFEC407A)),
        _Item(Icons.calendar_today_outlined, 'Amenities', () => _go(const AmenityBookingScreen()), const Color(0xFF66BB6A)),
        _Item(Icons.bar_chart_outlined, 'Polls', () => _go(const PollListScreen()), const Color(0xFF5C6BC0)),
        _Item(Icons.folder_open_outlined, 'Documents', () => _go(const DocumentListScreen()), const Color(0xFFFFA726)),
        _Item(Icons.account_balance_wallet_outlined, 'Ledger', () => _go(const LedgerScreen()), const Color(0xFF26A69A)),
        _Item(Icons.directions_car_outlined, 'Vehicles', () => _go(const VehicleListScreen()), const Color(0xFF29B6F6)),
        _Item(Icons.cleaning_services_outlined, 'Daily Help', () => _go(const StaffListScreen()), const Color(0xFFF06292)),
      ]);

  Widget _securityMenu() => _grid([
        _Item(Icons.directions_run_outlined, 'Visitor Entry', () => _go(const SecurityDashboardScreen()), const Color(0xFFFF7043)),
        _Item(Icons.history_outlined, 'Visitor Logs', () => _go(const VisitorReportScreen()), const Color(0xFF42A5F5)),
        _Item(Icons.group_outlined, 'Inside Now', () => _go(const CurrentVisitorsScreen()), const Color(0xFF66BB6A)),
        _Item(Icons.cleaning_services_outlined, 'Daily Help', () => _go(const StaffListScreen()), const Color(0xFFEC407A)),
      ]);

  // ─── Action grid ─────────────────────────────────────────────────────────────

  Widget _grid(List<_Item> items) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.05,
        children: items.map(_tile).toList(),
      );

  Widget _tile(_Item item) {
    final cardBg = item.color.withValues(alpha: 0.12);
    final iconBg = item.color.withValues(alpha: 0.22);

    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon well
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, size: 28, color: item.color),
            ),
            const Spacer(),
            // Label
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Promo card (member only) ─────────────────────────────────────────────────

  Widget _buildPromoCard() => Container(
        width: double.infinity,
        height: 158,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.50, 1.0],
            colors: [
              Color(0xFF0A1929),
              Color(0xFF0F2440),
              Color(0xFF1A3A5C),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            const BoxShadow(
              color: Color(0x660A1929),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Decorative glow orb
            Positioned(
              right: 60,
              top: -30,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.09),
                ),
              ),
            ),
            // society_4 image as faded decorative backdrop
            Positioned(
              right: -12,
              bottom: -8,
              child: SizedBox(
                height: 140,
                width: 140,
                child: Opacity(
                  opacity: 0.30,
                  child: Image.asset(
                    'assets/society_4.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'VISITOR PASS',
                    style: TextStyle(
                      color: AppColors.accent.withValues(alpha: 0.85),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create Visitor Pass',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Generate a secure pass for your guests',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.48),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _go(const VisitorManagementScreen()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Generate Pass',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  // ─── Navigation helpers ───────────────────────────────────────────────────────

  void _go(Widget screen, {VoidCallback? refresh}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => refresh?.call());
  }
}

// ─── Action item data class ───────────────────────────────────────────────────

class _Item {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _Item(this.icon, this.label, this.onTap, [this.color = const Color(0xFF4A6589)]);
}
