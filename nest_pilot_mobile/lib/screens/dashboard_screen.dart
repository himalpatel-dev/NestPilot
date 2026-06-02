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
import '../theme/app_colors.dart';

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
      backgroundColor: AppColors.dashBg,
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
                style: const TextStyle(color: AppColors.white, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                widget.user.mobile,
                style: const TextStyle(color: AppColors.white, fontSize: 13),
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
        backgroundColor: AppColors.dashBg,
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
                  padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPad + 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (_isAdmin) ...[
                        _buildStatsRow(),
                        const SizedBox(height: 24),
                      ],
                      _buildSectionLabel(
                        _isSecurity ? 'On Duty' : 'Resident Corner',
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

  // ─── Full-bleed hero ────────────────────────────────────────────────────────

  Widget _buildHero() {
    String line1, line2, subtext, ctaLabel;
    IconData ctaIcon;
    VoidCallback ctaAction;

    if (_isMember) {
      final hasDue = _outstandingAmount > 0;
      line1 = 'Your community,';
      line2 = hasDue ? 'bills pending.' : 'all cleared.';
      subtext = hasDue
          ? 'Pay before the due date to avoid penalties.'
          : 'Everything you need, right here.';
      ctaLabel = hasDue ? 'View & Pay Bills' : 'View Bills';
      ctaIcon = Icons.receipt_long_rounded;
      ctaAction = () =>
          _go(const BillsListScreen(), refresh: _fetchOutstandingBills);
    } else if (_isSecurity) {
      line1 = 'Stay alert,';
      line2 = 'keep gates safe.';
      subtext = 'Log every visitor, every time.';
      ctaLabel = 'Visitor Entry';
      ctaIcon = Icons.directions_run_rounded;
      ctaAction = () => _go(const SecurityDashboardScreen());
    } else {
      line1 = 'Your society,';
      line2 = 'well managed.';
      subtext = 'Everything you need, in one place.';
      ctaLabel = 'Manage Notices';
      ctaIcon = Icons.campaign_rounded;
      ctaAction = () => _go(const NoticeCreateScreen());
    }

    final firstName = widget.user.fullName.split(' ').first;
    final topPad = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 380 + topPad,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ① Full-bleed society photo
          Image.asset(
            'dash1.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),

          // ② Cinematic gradient — clear window in middle, black at bottom
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.80, 0.50, 1.20],
                colors: [
                  AppColors.heroOverlayMid,
                  AppColors.transparent,
                  AppColors.heroOverlayMid,
                  AppColors.black,
                ],
              ),
            ),
          ),

          // ③ Content
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nav bar
                Row(
                  children: [
                    GestureDetector(
                      onTap: _showProfileSheet,
                      child: _GlassChip(
                        width: 40,
                        height: 40,
                        radius: 20,
                        tint: 0.14,
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.white.withValues(alpha: 0.9),
                          size: 20,
                        ),
                      ),
                    ),
                    const Spacer(),
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
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.black,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.65,
                                    ),
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

                const Spacer(),

                // Greeting row
                Row(
                  children: [
                    Text(
                      '${_getGreeting()}, $firstName',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('👋', style: TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 10),

                // Headline — line 1 white, line 2 first-word accent
                Text(
                  line1,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                _heroLine2(line2),

                const SizedBox(height: 10),

                // Subtitle
                Text(
                  subtext,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.58),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 6),
                _buildHeroStatusPill(),
                const SizedBox(height: 20),

                // CTA button
                GestureDetector(
                  onTap: ctaAction,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.40),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(ctaIcon, color: AppColors.black, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ctaLabel,
                            style: const TextStyle(
                              color: AppColors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.black.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.black,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // First word of the second headline line rendered in accent, rest white.
  Widget _heroLine2(String text) {
    final words = text.split(' ');
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: words.first,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          if (words.length > 1)
            TextSpan(
              text: ' ${words.skip(1).join(' ')}',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.1,
                letterSpacing: -0.5,
              ),
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
      tint: 0.14,
      child: Icon(
        icon,
        color: AppColors.white.withValues(alpha: 0.9),
        size: 20,
      ),
    ),
  );

  // Status pill shown below headline — bills for member, role tag for others.
  Widget _buildHeroStatusPill() {
    if (_isMember) {
      if (_loadingBills) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
          ),
          child: const SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.6,
              color: AppColors.primary,
            ),
          ),
        );
      }
      final hasDue = _outstandingAmount > 0;
      final currency = NumberFormat.currency(
        locale: 'HI',
        symbol: '₹',
        decimalDigits: 0,
      );
      final tint = hasDue ? AppColors.warning : AppColors.success;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tint.withValues(alpha: 0.35)),
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
                  ? '${currency.format(_outstandingAmount)} · due ${DateFormat('dd MMM').format(_dueDate)}'
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
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Text(
        _roleLabel(widget.user.role).toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  // ─── Stats row (admins only) ─────────────────────────────────────────────────

  Widget _buildStatsRow() {
    final isSuperAdmin = widget.user.role == UserRoles.superAdmin;
    final stats = isSuperAdmin
        ? const [
            _StatData('Societies', '0', AppColors.accentOrange),
            _StatData('Buildings', '0', AppColors.accentPurple),
            _StatData('Flats', '0', AppColors.accentBlue),
            _StatData('Members', '0', AppColors.accentGreen),
          ]
        : const [
            _StatData('Owners', '0', AppColors.accentOrange),
            _StatData('Tenants', '0', AppColors.accentPurple),
            _StatData('Occupied', '0', AppColors.accentBlue),
            _StatData('Vacant', '0', AppColors.accentGreen),
          ];

    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _statCard(stats[i])),
        ],
      ],
    );
  }

  Widget _statCard(_StatData s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.dashBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            s.value,
            style: TextStyle(
              color: s.color,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            s.label,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.42),
              fontSize: 11,
              fontWeight: FontWeight.w500,
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
      Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
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
        style: TextStyle(color: AppColors.white),
      ),
    );
  }

  Widget _superAdminMenu() => _compactGrid([
    _Item(
      Icons.business_outlined,
      'Create Society',
      () => _go(const SocietyCreateScreen()),
      AppColors.accentPink,
    ),
    _Item(
      Icons.apartment_outlined,
      'Add Building',
      () => _go(const BuildingCreateScreen()),
      AppColors.accentBlue,
    ),
    _Item(
      Icons.door_front_door_outlined,
      'Add Flat',
      () => _go(const FlatCreateScreen()),
      AppColors.accentOrange,
    ),
    _Item(
      Icons.list_alt_outlined,
      'Flats List',
      () => _go(const FlatsListScreen()),
      AppColors.accentTeal,
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
          AppColors.accentAmber,
        ),
        _Item(
          Icons.contacts_outlined,
          'Residents',
          () => _go(const MemberListScreen()),
          AppColors.accentBlue,
        ),
        _Item(
          Icons.campaign_outlined,
          'Notices',
          () => _go(const NoticeCreateScreen()),
          AppColors.accentPurple,
        ),
        _Item(
          Icons.add_card_outlined,
          'Create Bill',
          () => _go(const BillCreateScreen()),
          AppColors.accentGreen,
        ),
        _Item(
          Icons.receipt_long_outlined,
          'Manage Bills',
          () => _go(const BillsManageScreen()),
          AppColors.accentTeal,
        ),
        _Item(
          Icons.payments_outlined,
          'Payment',
          () => _go(const PaymentMarkScreen()),
          AppColors.accentOrange,
        ),
        _Item(
          Icons.report_problem_outlined,
          'Complaints',
          () => _go(const ComplaintListScreen()),
          AppColors.accentRed,
        ),
        _Item(
          Icons.pool_outlined,
          'Amenities',
          () => _go(const AmenityManagementScreen()),
          AppColors.accentIndigo,
        ),
      ]),
      const SizedBox(height: 24),
      _buildSectionLabel('Society Control'),
      const SizedBox(height: 14),
      _compactGrid([
        _Item(
          Icons.poll_outlined,
          'Polls',
          () => _go(const PollListScreen()),
          AppColors.accentPurple,
        ),
        _Item(
          Icons.directions_run_outlined,
          'Visitor Entry',
          () => _go(const SecurityDashboardScreen()),
          AppColors.accentOrange,
        ),
        _Item(
          Icons.group_work_outlined,
          'Visitor Logs',
          () => _go(const VisitorReportScreen()),
          AppColors.accentBlue,
        ),
        _Item(
          Icons.directions_car_outlined,
          'Vehicles',
          () => _go(const VehicleManagementScreen()),
          AppColors.accentTeal,
        ),
        _Item(
          Icons.folder_open_outlined,
          'Documents',
          () => _go(const DocumentListScreen()),
          AppColors.accentAmber,
        ),
        _Item(
          Icons.cleaning_services_outlined,
          'Daily Help',
          () => _go(const StaffListScreen()),
          AppColors.accentPink,
        ),
      ]),
    ],
  );

  Widget _memberMenu() => _compactGrid([
    _Item(
      Icons.campaign_outlined,
      'Notices',
      () => _go(const NoticeListScreen()),
      AppColors.accentPurple,
    ),
    _Item(
      Icons.receipt_long_outlined,
      'Bills',
      () => _go(const BillsListScreen(), refresh: _fetchOutstandingBills),
      AppColors.accentOrange,
    ),
    _Item(
      Icons.person_add_outlined,
      'Visitor Pass',
      () => _go(const VisitorManagementScreen()),
      AppColors.accentBlue,
    ),
    _Item(
      Icons.headset_mic_outlined,
      'Complaints',
      () => _go(const ComplaintListScreen()),
      AppColors.accentRed,
    ),
    _Item(
      Icons.calendar_today_outlined,
      'Amenities',
      () => _go(const AmenityBookingScreen()),
      AppColors.accentGreen,
    ),
    _Item(
      Icons.bar_chart_outlined,
      'Polls',
      () => _go(const PollListScreen()),
      AppColors.accentIndigo,
    ),
    _Item(
      Icons.folder_open_outlined,
      'Documents',
      () => _go(const DocumentListScreen()),
      AppColors.accentAmber,
    ),
    _Item(
      Icons.account_balance_wallet_outlined,
      'Ledger',
      () => _go(const LedgerScreen()),
      AppColors.accentTeal,
    ),
    _Item(
      Icons.directions_car_outlined,
      'Vehicles',
      () => _go(const VehicleListScreen()),
      AppColors.accentBrown,
    ),
    _Item(
      Icons.cleaning_services_outlined,
      'Daily Help',
      () => _go(const StaffListScreen()),
      AppColors.accentPink,
    ),
  ]);

  Widget _securityMenu() => _compactGrid([
    _Item(
      Icons.directions_run_outlined,
      'Visitor Entry',
      () => _go(const SecurityDashboardScreen()),
      AppColors.accentOrange,
    ),
    _Item(
      Icons.history_outlined,
      'Visitor Logs',
      () => _go(const VisitorReportScreen()),
      AppColors.accentBlue,
    ),
    _Item(
      Icons.group_outlined,
      'Inside Now',
      () => _go(const CurrentVisitorsScreen()),
      AppColors.accentGreen,
    ),
    _Item(
      Icons.cleaning_services_outlined,
      'Daily Help',
      () => _go(const StaffListScreen()),
      AppColors.accentPink,
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
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.tileSurfaceHigh,
                AppColors.tileSurfaceMid,
                AppColors.tileSurfaceLow,
              ],
              stops: [0.0, 0.55, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.white.withValues(alpha: 0.04),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.45),
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
            color: AppColors.white,
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
        colors: [AppColors.primary, AppColors.primaryDark],
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.30),
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
              Text(
                'VISITOR PASS',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.87),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create Visitor Pass',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Generate a secure pass for your guests',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.65),
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
                    color: AppColors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Generate Pass',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.white,
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
            color: AppColors.black.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.qr_code_2_rounded,
            color: AppColors.white,
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
                AppColors.white.withValues(alpha: tint),
                AppColors.white.withValues(alpha: tint * 0.35),
              ],
            ),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.08),
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
  final String value;
  final Color color;
  const _StatData(this.label, this.value, this.color);
}
