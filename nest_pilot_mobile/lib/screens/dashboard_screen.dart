import 'dart:ui' show ImageFilter;
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

// ─── Theme tokens (matte black + gold) ───────────────────────────────────────
const _kBg = Color(0xFF000000);
const _kSurface = Color(0xFF15151B);
const _kGold = Color.fromARGB(255, 189, 104, 47);
const _kGoldDeep = Color.fromARGB(255, 228, 106, 31);
const _kTextHi = Colors.white;
const _kTextMid = Color(0xCCFFFFFF);
const _kTextLo = Color(0x80FFFFFF);
const _kSuccess = Color(0xFF4ADE80);
const _kDanger = Color(0xFFFF8C42);

// Per-tile accent palette — used only on the small icon chips so each module
// gets a recognisable color while the rest of the UI stays black + gold.
const _kRed = Color(0xFFEF4444);
const _kBlue = Color(0xFF3B82F6);
const _kGreen = Color(0xFF22C55E);
const _kOrange = Color(0xFFF97316);
const _kPurple = Color(0xFFA855F7);
const _kPink = Color(0xFFEC4899);
const _kTeal = Color(0xFF14B8A6);
const _kIndigo = Color(0xFF6366F1);
const _kAmber = Color(0xFFF59E0B);
const _kBrown = Color(0xFF8B5A3C);

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
            .where(
              (b) =>
                  b.status == 'PENDING' ||
                  b.status == 'PARTIAL' ||
                  b.status == 'OVERDUE',
            )
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

  // ─── Profile sheet ──────────────────────────────────────────────────────────

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kSurface,
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
                  color: Colors.white.withValues(alpha: 0.25),
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
                    colors: [_kGold, _kGoldDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kGold.withValues(alpha: 0.35),
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
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.user.fullName,
                style: const TextStyle(
                  color: _kTextHi,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _roleLabel(widget.user.role),
                style: const TextStyle(color: _kTextLo, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                widget.user.mobile,
                style: const TextStyle(color: _kTextLo, fontSize: 13),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: Colors.black,
                  ),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGold,
                    foregroundColor: Colors.black,
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
        backgroundColor: _kBg,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              await _fetchNotifications();
              await _fetchOutstandingBills();
            },
            color: Colors.black,
            backgroundColor: _kGold,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPad + 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeroCard(),
                      const SizedBox(height: 24),
                      if (_isAdmin) ...[
                        _buildStatsRow(),
                        const SizedBox(height: 24),
                      ],
                      _buildSectionLabel(
                        _isSecurity ? 'On Duty' : 'Quick Actions',
                      ),
                      const SizedBox(height: 14),
                      _buildRoleMenu(),
                      if (_isMember) ...[
                        const SizedBox(height: 24),
                        _buildPromoCard(),
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

  // ─── Header (top bar) ───────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Row(
        children: [
          // Left: avatar (profile)
          GestureDetector(
            onTap: _showProfileSheet,
            child: _GlassChip(
              width: 40,
              height: 40,
              radius: 20,
              tint: 0.08,
              child: Icon(
                Icons.person_outline_rounded,
                color: Colors.white.withValues(alpha: 0.85),
                size: 20,
              ),
            ),
          ),
          // Center: brand title
          const Expanded(
            child: Center(
              child: Text(
                'NestPilot',
                style: TextStyle(
                  color: _kTextHi,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          // Right: notifications with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              _circleIconBtn(
                icon: Icons.notifications_none_rounded,
                onTap: _showNotifications,
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: _kGold,
                      shape: BoxShape.circle,
                      border: Border.all(color: _kBg, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: _kGold.withValues(alpha: 0.60),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleIconBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: _GlassChip(
      width: 40,
      height: 40,
      radius: 20,
      tint: 0.08,
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 20),
    ),
  );

  // ─── Hero card (greeting + role context) ─────────────────────────────────────

  Widget _buildHeroCard() {
    // Tagline differs by role so the hero stays meaningful for each persona.
    String headline;
    String subhead;
    String ctaLabel;
    IconData ctaIcon;
    VoidCallback ctaAction;

    if (_isMember) {
      final hasDue = _outstandingAmount > 0;
      headline = hasDue ? 'You have bills' : 'All bills are';
      subhead = hasDue ? 'pending today.' : 'cleared.';
      ctaLabel = hasDue ? 'View & Pay Bills' : 'View Bills';
      ctaIcon = Icons.receipt_long_rounded;
      ctaAction = () =>
          _go(const BillsListScreen(), refresh: _fetchOutstandingBills);
    } else if (_isSecurity) {
      headline = 'Stay alert,';
      subhead = 'keep gates safe.';
      ctaLabel = 'Visitor Entry';
      ctaIcon = Icons.directions_run_rounded;
      ctaAction = () => _go(const SecurityDashboardScreen());
    } else {
      headline = 'Run your society';
      subhead = 'smoothly today.';
      ctaLabel = 'Manage Notices';
      ctaIcon = Icons.campaign_rounded;
      ctaAction = () => _go(const NoticeCreateScreen());
    }

    final firstName = widget.user.fullName.split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: greeting + tagline on the left, framed image on the right.
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${_getGreeting()}, $firstName',
                          style: const TextStyle(
                            color: _kTextMid,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('👋', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      headline,
                      style: const TextStyle(
                        color: _kTextHi,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      subhead,
                      style: const TextStyle(
                        color: _kTextHi,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildHeroStatusPill(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildHeroImage(),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Wide gold CTA pill.
        GestureDetector(
          onTap: ctaAction,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kGold, _kGoldDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _kGold.withValues(alpha: 0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(ctaIcon, color: Colors.black, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ctaLabel,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.black,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Small inline status pill under the hero headline — shows outstanding
  /// amount + due date for members, role pill for everyone else.
  Widget _buildHeroStatusPill() {
    if (_isMember) {
      if (_loadingBills) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: const SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(strokeWidth: 1.6, color: _kGold),
          ),
        );
      }

      final hasDue = _outstandingAmount > 0;
      final currency = NumberFormat.currency(
        locale: 'HI',
        symbol: '₹',
        decimalDigits: 0,
      );
      final dateF = DateFormat('dd MMM');
      final tint = hasDue ? _kDanger : _kSuccess;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tint.withValues(alpha: 0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: tint),
            ),
            const SizedBox(width: 6),
            Text(
              hasDue
                  ? '${currency.format(_outstandingAmount)} · due ${dateF.format(_dueDate)}'
                  : 'All cleared',
              style: TextStyle(
                color: tint,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kGold.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        _roleLabel(widget.user.role).toUpperCase(),
        style: const TextStyle(
          color: _kGold,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  /// Rounded-rectangle hero image on the right — a clean photographic crop of
  /// the lit community entrance from the reference design.
  Widget _buildHeroImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        'assets/dash.png',
        width: 140,
        height: 160,
        fit: BoxFit.cover,
      ),
    );
  }

  // ─── Stats row (admins only) ─────────────────────────────────────────────────

  Widget _buildStatsRow() {
    const stats = [
      _StatData('Notices', Icons.campaign_outlined),
      _StatData('Bills', Icons.receipt_long_outlined),
      _StatData('Members', Icons.group_outlined),
    ];
    return Row(
      children: [
        Expanded(child: _statCard(stats[0])),
        const SizedBox(width: 12),
        Expanded(child: _statCard(stats[1])),
        const SizedBox(width: 12),
        Expanded(child: _statCard(stats[2])),
      ],
    );
  }

  Widget _statCard(_StatData s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inner icon chip — glass-style, soft white border + subtle glow.
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(s.icon, color: _kGold, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            s.label,
            style: const TextStyle(
              color: _kTextLo,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Manage',
            style: TextStyle(
              color: _kTextHi,
              fontSize: 15,
              fontWeight: FontWeight.w800,
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
          color: _kGold,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: _kTextHi,
          letterSpacing: 0.2,
        ),
      ),
    ],
  );

  // ─── Role menus ──────────────────────────────────────────────────────────────

  Widget _buildRoleMenu() {
    if (widget.user.role == UserRoles.superAdmin) return _superAdminMenu();
    if (widget.user.role == UserRoles.societyAdmin) return _societyAdminMenu();
    if (widget.user.role == UserRoles.member) return _memberMenu();
    if (widget.user.role == UserRoles.securityGuard) return _securityMenu();
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Text(
        'No actions available for your role.',
        style: TextStyle(color: _kTextLo),
      ),
    );
  }

  Widget _superAdminMenu() => _compactGrid([
    _Item(
      Icons.business_outlined,
      'Create Society',
      () => _go(const SocietyCreateScreen()),
      _kPink,
    ),
    _Item(
      Icons.apartment_outlined,
      'Add Building',
      () => _go(const BuildingCreateScreen()),
      _kBlue,
    ),
    _Item(
      Icons.door_front_door_outlined,
      'Add Flat',
      () => _go(const FlatCreateScreen()),
      _kOrange,
    ),
    _Item(
      Icons.list_alt_outlined,
      'Flats List',
      () => _go(const FlatsListScreen()),
      _kTeal,
    ),
  ]);

  Widget _societyAdminMenu() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _compactGrid([
        _Item(
          Icons.person_add_alt_1_outlined,
          'Pending',
          () => _go(const PendingMembersScreen()),
          _kAmber,
        ),
        _Item(
          Icons.contacts_outlined,
          'Residents',
          () => _go(const MemberListScreen()),
          _kBlue,
        ),
        _Item(
          Icons.campaign_outlined,
          'Notices',
          () => _go(const NoticeCreateScreen()),
          _kPurple,
        ),
        _Item(
          Icons.add_card_outlined,
          'Create Bill',
          () => _go(const BillCreateScreen()),
          _kGreen,
        ),
        _Item(
          Icons.receipt_long_outlined,
          'Manage Bills',
          () => _go(const BillsManageScreen()),
          _kTeal,
        ),
        _Item(
          Icons.payments_outlined,
          'Payment',
          () => _go(const PaymentMarkScreen()),
          _kOrange,
        ),
        _Item(
          Icons.report_problem_outlined,
          'Complaints',
          () => _go(const ComplaintListScreen()),
          _kRed,
        ),
        _Item(
          Icons.pool_outlined,
          'Amenities',
          () => _go(const AmenityManagementScreen()),
          _kIndigo,
        ),
      ]),
      const SizedBox(height: 24),
      _buildSectionLabel('Operations & Tools'),
      const SizedBox(height: 14),
      _compactGrid([
        _Item(
          Icons.poll_outlined,
          'Polls',
          () => _go(const PollListScreen()),
          _kPurple,
        ),
        _Item(
          Icons.directions_run_outlined,
          'Visitor Entry',
          () => _go(const SecurityDashboardScreen()),
          _kOrange,
        ),
        _Item(
          Icons.group_work_outlined,
          'Visitor Logs',
          () => _go(const VisitorReportScreen()),
          _kBlue,
        ),
        _Item(
          Icons.directions_car_outlined,
          'Vehicles',
          () => _go(const VehicleManagementScreen()),
          _kTeal,
        ),
        _Item(
          Icons.folder_open_outlined,
          'Documents',
          () => _go(const DocumentListScreen()),
          _kAmber,
        ),
        _Item(
          Icons.cleaning_services_outlined,
          'Daily Help',
          () => _go(const StaffListScreen()),
          _kPink,
        ),
      ]),
    ],
  );

  Widget _memberMenu() => _compactGrid([
    _Item(
      Icons.campaign_outlined,
      'Notices',
      () => _go(const NoticeListScreen()),
      _kPurple,
    ),
    _Item(
      Icons.receipt_long_outlined,
      'Bills',
      () => _go(const BillsListScreen(), refresh: _fetchOutstandingBills),
      _kOrange,
    ),
    _Item(
      Icons.person_add_outlined,
      'Visitor Pass',
      () => _go(const VisitorManagementScreen()),
      _kBlue,
    ),
    _Item(
      Icons.headset_mic_outlined,
      'Complaints',
      () => _go(const ComplaintListScreen()),
      _kRed,
    ),
    _Item(
      Icons.calendar_today_outlined,
      'Amenities',
      () => _go(const AmenityBookingScreen()),
      _kGreen,
    ),
    _Item(
      Icons.bar_chart_outlined,
      'Polls',
      () => _go(const PollListScreen()),
      _kIndigo,
    ),
    _Item(
      Icons.folder_open_outlined,
      'Documents',
      () => _go(const DocumentListScreen()),
      _kAmber,
    ),
    _Item(
      Icons.account_balance_wallet_outlined,
      'Ledger',
      () => _go(const LedgerScreen()),
      _kTeal,
    ),
    _Item(
      Icons.directions_car_outlined,
      'Vehicles',
      () => _go(const VehicleListScreen()),
      _kBrown,
    ),
    _Item(
      Icons.cleaning_services_outlined,
      'Daily Help',
      () => _go(const StaffListScreen()),
      _kPink,
    ),
  ]);

  Widget _securityMenu() => _compactGrid([
    _Item(
      Icons.directions_run_outlined,
      'Visitor Entry',
      () => _go(const SecurityDashboardScreen()),
      _kOrange,
    ),
    _Item(
      Icons.history_outlined,
      'Visitor Logs',
      () => _go(const VisitorReportScreen()),
      _kBlue,
    ),
    _Item(
      Icons.group_outlined,
      'Inside Now',
      () => _go(const CurrentVisitorsScreen()),
      _kGreen,
    ),
    _Item(
      Icons.cleaning_services_outlined,
      'Daily Help',
      () => _go(const StaffListScreen()),
      _kPink,
    ),
  ]);

  // ─── Compact icon-tile grid ──────────────────────────────────────────────────

  Widget _compactGrid(List<_Item> items) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 4,
    mainAxisSpacing: 18,
    crossAxisSpacing: 10,
    childAspectRatio: 0.78,
    children: items.map(_compactTile).toList(),
  );

  Widget _compactTile(_Item item) => GestureDetector(
    onTap: item.onTap,
    behavior: HitTestBehavior.opaque,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Glass tile — flat dark surface with a vertical highlight gradient
        // (brighter at the top → dim at the bottom) for the glossy sheen
        // from the reference. Subtle inner top highlight + thin border.
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF26262E),
                Color(0xFF15151B),
                Color(0xFF0F0F14),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              // Soft inner-style top highlight (acts as glass sheen)
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.04),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
              // Outer drop shadow to lift the tile off the background
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(item.icon, color: item.color, size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          item.label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: _kTextMid,
            height: 1.2,
            letterSpacing: 0.1,
          ),
        ),
      ],
    ),
  );

  // ─── Promo card (member only) ────────────────────────────────────────────────

  Widget _buildPromoCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_kGold, _kGoldDeep],
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: _kGold.withValues(alpha: 0.30),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VISITOR PASS',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create Visitor Pass',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Generate a secure pass for your guests',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.65),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => _go(const VisitorManagementScreen()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Generate Pass',
                        style: TextStyle(
                          color: _kGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: _kGold,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.qr_code_2_rounded,
            color: Colors.black,
            size: 36,
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

// ─── Data classes ────────────────────────────────────────────────────────────

class _Item {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _Item(this.icon, this.label, this.onTap, this.color);
}

/// Reusable frosted-glass surface: backdrop blur + translucent white tint.
class _GlassChip extends StatelessWidget {
  final Widget child;
  final double radius;
  final double? width;
  final double? height;
  final double tint;

  const _GlassChip({
    required this.child,
    this.radius = 16,
    this.width,
    this.height,
    this.tint = 0.06,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: width,
          height: height,
          alignment: width != null ? Alignment.center : null,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: tint),
                Colors.white.withValues(alpha: tint * 0.35),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StatData {
  final String label;
  final IconData icon;
  const _StatData(this.label, this.icon);
}
