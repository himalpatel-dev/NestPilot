import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../config/roles.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_bottom_nav.dart';
import '../theme/tab_route.dart';

import 'login_screen.dart';
import 'notification_list_screen.dart';

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
import 'secretary/poll_create_screen.dart';
import 'secretary/document_upload_screen.dart';
import 'secretary/staff_add_screen.dart';
import 'secretary/vehicle_management_screen.dart';
import 'secretary/event_manage_screen.dart';
import 'secretary/payment_mark_screen.dart';
import 'secretary/complaint_manage_screen.dart';

import 'member/notice_list_screen.dart';
import 'member/complaint_list_screen.dart';
import 'member/bills_list_screen.dart';
import 'member/ledger_screen.dart';
import 'member/community/visitor_management_screen.dart';
import 'member/community/amenity_booking_screen.dart';
import 'member/community/staff_list_screen.dart';
import 'member/community/poll_list_screen.dart';
import 'member/community/document_list_screen.dart';
import 'member/community/vehicle_list_screen.dart';

import 'security/security_dashboard_screen.dart';
import 'security/current_visitors_screen.dart';
import 'common/visitor_report_screen.dart';

class ServicesHubScreen extends StatefulWidget {
  final UserModel user;
  const ServicesHubScreen({super.key, required this.user});

  @override
  State<ServicesHubScreen> createState() => _ServicesHubScreenState();
}

class _ServicesHubScreenState extends State<ServicesHubScreen> {
  // Services tab pre-selected on this screen.
  int _selectedTab = 2;

  bool get _isMember => widget.user.role == UserRoles.member;
  bool get _isSecretary => widget.user.role == UserRoles.societyAdmin;

  @override
  Widget build(BuildContext context) {
    final sections = _sectionsForRole(widget.user.role);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.light,
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
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
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
    );
  }

  // ─── Bottom nav: items + tap routing (mirrors dashboard) ──────────────────

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
    // Services tab — already here.
    if (index == 2) return;

    // Home — pop back to the dashboard underneath.
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    setState(() => _selectedTab = index);

    Widget? screen;
    if (_isSecretary) {
      switch (index) {
        case 1:
          screen = const MemberListScreen();
          break;
        case 3:
          screen = const BillsManageScreen();
          break;
        case 4:
          screen = const VisitorReportScreen();
          break;
      }
    } else {
      switch (index) {
        case 1:
          screen = _isMember
              ? const NoticeListScreen()
              : const NoticeCreateScreen();
          break;
        case 3:
          screen = _isMember
              ? const BillsListScreen()
              : const BillsManageScreen();
          break;
        case 4:
          // Profile — no profile screen yet; just pop home.
          Navigator.of(context).popUntil((route) => route.isFirst);
          return;
      }
    }

    if (screen != null) {
      Navigator.push(context, tabRoute(screen)).then((_) {
        if (mounted) setState(() => _selectedTab = 2);
      });
    }
  }

  Widget _buildHeader(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    final heroHeight = safeTop + 130.0;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: SizedBox(
        height: heroHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.6, 1.0],
                  colors: [
                    AppColors.heroGradientDeep,
                    AppColors.primaryDark,
                    AppColors.primary,
                  ],
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 40,
              top: -10,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Building image — right side, fades left
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: screenWidth * 0.50,
              child: ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: const [0.0, 0.40, 1.0],
                  colors: [
                    AppColors.transparent,
                    AppColors.white.withValues(alpha: 0.35),
                    AppColors.white.withValues(alpha: 0.60),
                  ],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/dash2.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
            // Content
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button row
                    if (Navigator.canPop(context))
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    const Spacer(),
                    const Text(
                      'Services',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All your tools in one place',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.70),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Role-driven section model ───────────────────────────────────────────────

  List<_HubSection> _sectionsForRole(String role) {
    switch (role) {
      case UserRoles.member:
        return _memberSections();
      case UserRoles.societyAdmin:
        return _secretarySections();
      case UserRoles.securityGuard:
        return _securitySections();
      case UserRoles.superAdmin:
        return _superAdminSections();
      default:
        return _memberSections();
    }
  }

  List<_HubSection> _memberSections() => [
    _HubSection('Community', [
      _Tile(
        Icons.campaign_outlined,
        'Notices',
        AppColors.accentAmber,
        (c) => _go(c, const NoticeListScreen()),
      ),
      _Tile(
        Icons.how_to_vote_outlined,
        'Polls',
        AppColors.accentPurple,
        (c) => _go(c, const PollListScreen()),
      ),
      _Tile(
        Icons.folder_open_outlined,
        'Documents',
        AppColors.accentGreen,
        (c) => _go(c, const DocumentListScreen()),
      ),
      _Tile(
        Icons.directions_car_outlined,
        'Vehicles',
        AppColors.accentBlue,
        (c) => _go(c, const VehicleListScreen()),
      ),
    ]),
    _HubSection('Services', [
      _Tile(
        Icons.calendar_today_outlined,
        'Amenities',
        AppColors.accentIndigo,
        (c) => _go(c, const AmenityBookingScreen()),
      ),
      _Tile(
        Icons.report_problem_outlined,
        'Complaints',
        AppColors.accentRed,
        (c) => _go(c, const ComplaintListScreen()),
      ),
      _Tile(
        Icons.cleaning_services_outlined,
        'Daily Help',
        AppColors.accentPink,
        (c) => _go(c, const StaffListScreen()),
      ),
      _Tile(
        Icons.person_add_outlined,
        'Visitors',
        AppColors.accentBlue,
        (c) => _go(c, const VisitorManagementScreen()),
      ),
    ]),
    _HubSection('Payments', [
      _Tile(
        Icons.receipt_long_outlined,
        'My Bills',
        AppColors.accentAmber,
        (c) => _go(c, const BillsListScreen()),
      ),
      _Tile(
        Icons.account_balance_outlined,
        'Ledger',
        AppColors.accentTeal,
        (c) => _go(c, const LedgerScreen()),
      ),
    ]),
    _HubSection('Settings', [
      _Tile(
        Icons.notifications_outlined,
        'Notifications',
        AppColors.accentOrange,
        (c) => _go(c, const NotificationListScreen()),
      ),
      _Tile(
        Icons.logout_rounded,
        'Logout',
        AppColors.accentRed,
        (c) => _logout(c),
      ),
    ]),
  ];

  List<_HubSection> _secretarySections() => [
    _HubSection('Administration', [
      _Tile(
        Icons.person_add_alt_1_outlined,
        'Pending',
        AppColors.accentAmber,
        (c) => _go(c, const PendingMembersScreen()),
      ),
      _Tile(
        Icons.contacts_outlined,
        'Residents',
        AppColors.accentBlue,
        (c) => _go(c, const MemberListScreen()),
      ),
      _Tile(
        Icons.campaign_outlined,
        'Notices',
        AppColors.accentPurple,
        (c) => _go(c, const NoticeCreateScreen()),
      ),
      _Tile(
        Icons.how_to_vote_outlined,
        'Polls',
        AppColors.accentPink,
        (c) => _go(c, const PollCreateScreen()),
      ),
    ]),
    _HubSection('Operations', [
      _Tile(
        Icons.calendar_today_outlined,
        'Amenities',
        AppColors.accentIndigo,
        (c) => _go(c, const AmenityManagementScreen()),
      ),
      _Tile(
        Icons.cleaning_services_outlined,
        'Staff',
        AppColors.accentPink,
        (c) => _go(c, const StaffAddScreen()),
      ),
      _Tile(
        Icons.directions_car_outlined,
        'Vehicles',
        AppColors.accentBlue,
        (c) => _go(c, const VehicleManagementScreen()),
      ),
      _Tile(
        Icons.folder_open_outlined,
        'Documents',
        AppColors.accentGreen,
        (c) => _go(c, const DocumentUploadScreen()),
      ),
    ]),
    _HubSection('Billing & Payments', [
      _Tile(
        Icons.add_card_outlined,
        'Create Bill',
        AppColors.accentGreen,
        (c) => _go(c, const BillCreateScreen()),
      ),
      _Tile(
        Icons.receipt_long_outlined,
        'Manage Bills',
        AppColors.accentAmber,
        (c) => _go(c, const BillsManageScreen()),
      ),
      _Tile(
        Icons.payments_outlined,
        'Mark Payment',
        AppColors.accentTeal,
        (c) => _go(c, const PaymentMarkScreen()),
      ),
    ]),
    _HubSection('Community', [
      _Tile(
        Icons.event_outlined,
        'Events',
        AppColors.accentIndigo,
        (c) => _go(c, const EventManageScreen()),
      ),
      _Tile(
        Icons.report_problem_outlined,
        'Complaints',
        AppColors.accentRed,
        (c) => _go(c, const ComplaintManageScreen()),
      ),
    ]),
    _HubSection('Security', [
      _Tile(
        Icons.directions_run_outlined,
        'Visitor Entry',
        AppColors.accentOrange,
        (c) => _go(c, const SecurityDashboardScreen()),
      ),
      _Tile(
        Icons.group_outlined,
        'Inside Now',
        AppColors.accentGreen,
        (c) => _go(c, const CurrentVisitorsScreen()),
      ),
      _Tile(
        Icons.history_outlined,
        'Visitor Logs',
        AppColors.accentBlue,
        (c) => _go(c, const VisitorReportScreen()),
      ),
    ]),
    _HubSection('Settings', [
      _Tile(
        Icons.notifications_outlined,
        'Notifications',
        AppColors.accentOrange,
        (c) => _go(c, const NotificationListScreen()),
      ),
      _Tile(
        Icons.logout_rounded,
        'Logout',
        AppColors.accentRed,
        (c) => _logout(c),
      ),
    ]),
  ];

  List<_HubSection> _securitySections() => [
    _HubSection('Visitor Management', [
      _Tile(
        Icons.directions_run_outlined,
        'Entry',
        AppColors.accentOrange,
        (c) => _go(c, const SecurityDashboardScreen()),
      ),
      _Tile(
        Icons.group_outlined,
        'Inside Now',
        AppColors.accentGreen,
        (c) => _go(c, const CurrentVisitorsScreen()),
      ),
      _Tile(
        Icons.history_outlined,
        'Logs',
        AppColors.accentBlue,
        (c) => _go(c, const VisitorReportScreen()),
      ),
    ]),
    _HubSection('Community', [
      _Tile(
        Icons.cleaning_services_outlined,
        'Daily Help',
        AppColors.accentPink,
        (c) => _go(c, const StaffListScreen()),
      ),
    ]),
    _HubSection('Settings', [
      _Tile(
        Icons.notifications_outlined,
        'Notifications',
        AppColors.accentOrange,
        (c) => _go(c, const NotificationListScreen()),
      ),
      _Tile(
        Icons.logout_rounded,
        'Logout',
        AppColors.accentRed,
        (c) => _logout(c),
      ),
    ]),
  ];

  List<_HubSection> _superAdminSections() => [
    _HubSection('Administration', [
      _Tile(
        Icons.business_outlined,
        'Societies',
        AppColors.accentOrange,
        (c) => _go(c, const SocietyCreateScreen()),
      ),
      _Tile(
        Icons.apartment_outlined,
        'Buildings',
        AppColors.accentBlue,
        (c) => _go(c, const BuildingCreateScreen()),
      ),
      _Tile(
        Icons.door_front_door_outlined,
        'Add Flat',
        AppColors.accentPurple,
        (c) => _go(c, const FlatCreateScreen()),
      ),
      _Tile(
        Icons.list_alt_outlined,
        'Flats',
        AppColors.accentTeal,
        (c) => _go(c, const FlatsListScreen()),
      ),
    ]),
    _HubSection('Settings', [
      _Tile(
        Icons.notifications_outlined,
        'Notifications',
        AppColors.accentOrange,
        (c) => _go(c, const NotificationListScreen()),
      ),
      _Tile(
        Icons.logout_rounded,
        'Logout',
        AppColors.accentRed,
        (c) => _logout(c),
      ),
    ]),
  ];

  void _go(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
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

// ─── Section block ──────────────────────────────────────────────────────────

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

// 4-column responsive grid. Each tile is a self-contained AppIconTile, so
// no dividers are needed — the tile borders provide visual separation.
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

// ─── Data ───────────────────────────────────────────────────────────────────

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
  const _Tile(this.icon, this.label, this.color, this.onTap);
}
