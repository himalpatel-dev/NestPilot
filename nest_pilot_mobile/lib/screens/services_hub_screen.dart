import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../config/roles.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dashboard_header.dart';
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
import 'secretary/bills_dashboard_screen.dart';
import 'secretary/visitor_dashboard_screen.dart';
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
  final bool embedded;
  const ServicesHubScreen({
    super.key,
    required this.user,
    this.embedded = true,
  });

  @override
  State<ServicesHubScreen> createState() => _ServicesHubScreenState();
}

class _ServicesHubScreenState extends State<ServicesHubScreen> {
  int _selectedTab = 2;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  bool get _isMember => widget.user.role == UserRoles.member;
  bool get _isSecretary => widget.user.role == UserRoles.societyAdmin;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sectionsForRole(widget.user.role);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cardBackground,
        bottomNavigationBar: widget.embedded
            ? null
            : AppBottomNav(
                selectedIndex: _selectedTab,
                bottomPadding: bottomPad,
                onTap: _onNavTap,
                items: _navItems(),
              ),
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AppDashboardHeader(
                leftAction: Navigator.canPop(context)
                    ? appHeaderBackButton(context)
                    : null,
                title: 'Services',
                subtitle: 'All your tools in one place',
                onNotificationTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationListScreen(),
                  ),
                ),
                bottomSection: _buildSearchBar(),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad + 24),
              sliver: _searchQuery.isEmpty
                  ? SliverList(
                      delegate: SliverChildBuilderDelegate((ctx, i) {
                        final s = sections[i];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: i == sections.length - 1 ? 0 : 24,
                          ),
                          child: _Section(title: s.title, tiles: s.tiles),
                        );
                      }, childCount: sections.length),
                    )
                  : SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSearchResults(sections),
                      ]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Search bar ──────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      height: 37,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 13),
          const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.2,
              ),
              cursorColor: AppColors.primary,
              cursorHeight: 16,
              decoration: InputDecoration(
                hintText: 'Search services...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            GestureDetector(
              onTap: () => _searchController.clear(),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                  size: 13,
                ),
              ),
            ),
          ],
          const SizedBox(width: 13),
        ],
      ),
    );
  }

  // ─── Search results ──────────────────────────────────────────────────────────

  Widget _buildSearchResults(List<_HubSection> sections) {
    final tiles = _filterTiles(sections);
    if (tiles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              'No services found',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try different keywords',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.40),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    return _Grid(tiles: tiles);
  }

  List<_Tile> _filterTiles(List<_HubSection> sections) {
    final words = _searchQuery
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return [];

    final scores = <_Tile, int>{};
    for (final section in sections) {
      for (final tile in section.tiles) {
        final s = _scoreTile(tile, words);
        if (s > 0) scores[tile] = s;
      }
    }
    final result = scores.keys.toList();
    result.sort((a, b) => scores[b]!.compareTo(scores[a]!));
    return result;
  }

  int _scoreTile(_Tile tile, List<String> words) {
    final label = tile.label.toLowerCase();
    final terms = [label, ...tile.tags];
    int total = 0;
    for (final word in words) {
      int best = 0;
      for (final term in terms) {
        if (term == word) {
          best = best > 100 ? best : 100;
        } else if (term.startsWith(word)) {
          best = best > 70 ? best : 70;
        } else if (term.contains(word)) {
          best = best > 50 ? best : 50;
        } else if (word.length >= 3 && _fuzzyMatch(term, word)) {
          best = best > 20 ? best : 20;
        }
      }
      total += best;
    }
    return total;
  }

  bool _fuzzyMatch(String text, String pattern) {
    int pi = 0;
    for (int i = 0; i < text.length && pi < pattern.length; i++) {
      if (text[i] == pattern[pi]) pi++;
    }
    return pi == pattern.length;
  }

  // ─── Bottom nav ───────────────────────────────────────────────────────────────

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
    if (index == 2) return;
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
          screen = const BillsDashboardScreen();
          break;
        case 4:
          screen = const VisitorDashboardScreen();
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

  // ─── Role-driven section model ────────────────────────────────────────────────

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
        ['announcement', 'news', 'update', 'broadcast', 'circular', 'alert'],
      ),
      _Tile(
        Icons.how_to_vote_outlined,
        'Polls',
        AppColors.accentPurple,
        (c) => _go(c, const PollListScreen()),
        ['vote', 'survey', 'decision', 'opinion', 'question'],
      ),
      _Tile(
        Icons.folder_open_outlined,
        'Documents',
        AppColors.accentGreen,
        (c) => _go(c, const DocumentListScreen()),
        ['doc', 'file', 'pdf', 'upload', 'download', 'paper', 'record', 'form'],
      ),
      _Tile(
        Icons.directions_car_outlined,
        'Vehicles',
        AppColors.accentBlue,
        (c) => _go(c, const VehicleListScreen()),
        [
          'car',
          'bike',
          'parking',
          'motor',
          'transport',
          'sticker',
          'two wheeler',
          'four wheeler',
        ],
      ),
    ]),
    _HubSection('Services', [
      _Tile(
        Icons.calendar_today_outlined,
        'Amenities',
        AppColors.accentIndigo,
        (c) => _go(c, const AmenityBookingScreen()),
        [
          'gym',
          'pool',
          'hall',
          'club',
          'book',
          'booking',
          'facility',
          'sport',
          'court',
          'ground',
        ],
      ),
      _Tile(
        Icons.report_problem_outlined,
        'Complaints',
        AppColors.accentRed,
        (c) => _go(c, const ComplaintListScreen()),
        [
          'issue',
          'problem',
          'report',
          'complain',
          'fix',
          'repair',
          'request',
          'raise',
          'grievance',
        ],
      ),
      _Tile(
        Icons.cleaning_services_outlined,
        'Daily Help',
        AppColors.accentPink,
        (c) => _go(c, const StaffListScreen()),
        [
          'maid',
          'cook',
          'servant',
          'helper',
          'housekeeping',
          'staff',
          'worker',
          'cleaning',
          'domestic',
        ],
      ),
      _Tile(
        Icons.person_add_outlined,
        'Visitors',
        AppColors.accentBlue,
        (c) => _go(c, const VisitorManagementScreen()),
        ['guest', 'pass', 'entry', 'invite', 'visitor', 'outsider', 'log'],
      ),
    ]),
    _HubSection('Payments', [
      _Tile(
        Icons.receipt_long_outlined,
        'My Bills',
        AppColors.accentAmber,
        (c) => _go(c, const BillsListScreen()),
        [
          'payment',
          'dues',
          'maintenance',
          'fees',
          'rent',
          'pay',
          'charge',
          'bill',
          'amount',
          'monthly',
        ],
      ),
      _Tile(
        Icons.account_balance_outlined,
        'Ledger',
        AppColors.accentTeal,
        (c) => _go(c, const LedgerScreen()),
        [
          'history',
          'statement',
          'account',
          'record',
          'transaction',
          'balance',
          'paid',
          'receipt',
        ],
      ),
    ]),
    _HubSection('Settings', [
      _Tile(
        Icons.notifications_outlined,
        'Notifications',
        AppColors.accentOrange,
        (c) => _go(c, const NotificationListScreen()),
        ['alert', 'notify', 'push', 'message', 'reminder', 'bell'],
      ),
      _Tile(
        Icons.logout_rounded,
        'Logout',
        AppColors.accentRed,
        (c) => _logout(c),
        ['sign out', 'exit', 'signout', 'quit', 'leave'],
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
        [
          'approve',
          'request',
          'new member',
          'join',
          'pending member',
          'waiting',
          'acceptance',
        ],
      ),
      _Tile(
        Icons.contacts_outlined,
        'Residents',
        AppColors.accentBlue,
        (c) => _go(c, const MemberListScreen()),
        [
          'member',
          'flat',
          'tenant',
          'owner',
          'resident',
          'people',
          'family',
          'occupant',
          'contact',
        ],
      ),
      _Tile(
        Icons.campaign_outlined,
        'Notices',
        AppColors.accentPurple,
        (c) => _go(c, const NoticeCreateScreen()),
        [
          'announcement',
          'news',
          'broadcast',
          'alert',
          'update',
          'circular',
          'information',
        ],
      ),
      _Tile(
        Icons.how_to_vote_outlined,
        'Polls',
        AppColors.accentPink,
        (c) => _go(c, const PollCreateScreen()),
        ['vote', 'survey', 'decision', 'opinion', 'question'],
      ),
    ]),
    _HubSection('Operations', [
      _Tile(
        Icons.calendar_today_outlined,
        'Amenities',
        AppColors.accentIndigo,
        (c) => _go(c, const AmenityManagementScreen()),
        [
          'gym',
          'pool',
          'hall',
          'club',
          'book',
          'booking',
          'facility',
          'sport',
          'court',
          'ground',
        ],
      ),
      _Tile(
        Icons.cleaning_services_outlined,
        'Staff',
        AppColors.accentPink,
        (c) => _go(c, const StaffAddScreen()),
        [
          'maid',
          'employee',
          'worker',
          'helper',
          'housekeeping',
          'daily help',
          'cleaning',
          'domestic',
          'add staff',
        ],
      ),
      _Tile(
        Icons.directions_car_outlined,
        'Vehicles',
        AppColors.accentBlue,
        (c) => _go(c, const VehicleManagementScreen()),
        [
          'car',
          'bike',
          'parking',
          'motor',
          'sticker',
          'transport',
          'two wheeler',
          'four wheeler',
        ],
      ),
      _Tile(
        Icons.folder_open_outlined,
        'Documents',
        AppColors.accentGreen,
        (c) => _go(c, const DocumentUploadScreen()),
        ['doc', 'file', 'pdf', 'upload', 'paper', 'record', 'form', 'download'],
      ),
    ]),
    _HubSection('Billing & Payments', [
      _Tile(
        Icons.add_card_outlined,
        'Create Bill',
        AppColors.accentGreen,
        (c) => _go(c, const BillCreateScreen()),
        [
          'generate',
          'new',
          'billing',
          'invoice',
          'bill generate',
          'make bill',
          'add bill',
        ],
      ),
      _Tile(
        Icons.receipt_long_outlined,
        'Manage Bills',
        AppColors.accentAmber,
        (c) => _go(c, const BillsManageScreen()),
        [
          'bill list',
          'billing',
          'view bills',
          'invoice list',
          'all bills',
          'dues list',
        ],
      ),
      _Tile(
        Icons.payments_outlined,
        'Mark Payment',
        AppColors.accentTeal,
        (c) => _go(c, const PaymentMarkScreen()),
        [
          'payment',
          'pay',
          'dues',
          'maintenance',
          'collect',
          'mark',
          'record',
          'rent',
          'fees',
          'paid',
          'receipt',
          'bill pay',
          'collected',
        ],
      ),
    ]),
    _HubSection('Community', [
      _Tile(
        Icons.event_outlined,
        'Events',
        AppColors.accentIndigo,
        (c) => _go(c, const EventManageScreen()),
        [
          'event',
          'celebration',
          'party',
          'gathering',
          'programme',
          'function',
          'occasion',
          'festival',
        ],
      ),
      _Tile(
        Icons.report_problem_outlined,
        'Complaints',
        AppColors.accentRed,
        (c) => _go(c, const ComplaintManageScreen()),
        [
          'issue',
          'problem',
          'report',
          'complain',
          'fix',
          'repair',
          'request',
          'grievance',
          'raise',
        ],
      ),
    ]),
    _HubSection('Security', [
      _Tile(
        Icons.directions_run_outlined,
        'Visitor Entry',
        AppColors.accentOrange,
        (c) => _go(c, const SecurityDashboardScreen()),
        [
          'gate',
          'guard',
          'entry',
          'guest',
          'visitor',
          'log in',
          'check in',
          'security',
          'allow',
          'approve entry',
        ],
      ),
      _Tile(
        Icons.group_outlined,
        'Inside Now',
        AppColors.accentGreen,
        (c) => _go(c, const CurrentVisitorsScreen()),
        [
          'current',
          'present',
          'inside',
          'visitor',
          'who',
          'guest',
          'active',
          'inside now',
          'ongoing',
        ],
      ),
      _Tile(
        Icons.history_outlined,
        'Visitor Logs',
        AppColors.accentBlue,
        (c) => _go(c, const VisitorReportScreen()),
        [
          'history',
          'past',
          'log',
          'visitor',
          'report',
          'guest',
          'exit',
          'record',
          'visit history',
        ],
      ),
    ]),
    _HubSection('Settings', [
      _Tile(
        Icons.notifications_outlined,
        'Notifications',
        AppColors.accentOrange,
        (c) => _go(c, const NotificationListScreen()),
        ['alert', 'notify', 'push', 'message', 'reminder', 'bell'],
      ),
      _Tile(
        Icons.logout_rounded,
        'Logout',
        AppColors.accentRed,
        (c) => _logout(c),
        ['sign out', 'exit', 'signout', 'quit', 'leave'],
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
        [
          'gate',
          'log',
          'check in',
          'guest',
          'visitor',
          'security',
          'mark',
          'entry',
          'allow',
          'approve',
        ],
      ),
      _Tile(
        Icons.group_outlined,
        'Inside Now',
        AppColors.accentGreen,
        (c) => _go(c, const CurrentVisitorsScreen()),
        [
          'current',
          'present',
          'visitor',
          'who',
          'guest',
          'active',
          'inside',
          'ongoing',
        ],
      ),
      _Tile(
        Icons.history_outlined,
        'Logs',
        AppColors.accentBlue,
        (c) => _go(c, const VisitorReportScreen()),
        [
          'history',
          'past',
          'log',
          'visitor',
          'report',
          'guest',
          'exit',
          'record',
        ],
      ),
    ]),
    _HubSection('Community', [
      _Tile(
        Icons.cleaning_services_outlined,
        'Daily Help',
        AppColors.accentPink,
        (c) => _go(c, const StaffListScreen()),
        [
          'maid',
          'cook',
          'servant',
          'helper',
          'staff',
          'housekeeping',
          'cleaning',
          'worker',
          'domestic',
        ],
      ),
    ]),
    _HubSection('Settings', [
      _Tile(
        Icons.notifications_outlined,
        'Notifications',
        AppColors.accentOrange,
        (c) => _go(c, const NotificationListScreen()),
        ['alert', 'notify', 'push', 'message', 'bell'],
      ),
      _Tile(
        Icons.logout_rounded,
        'Logout',
        AppColors.accentRed,
        (c) => _logout(c),
        ['sign out', 'exit', 'signout', 'quit'],
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
        [
          'society',
          'create society',
          'new society',
          'apartment',
          'complex',
          'housing',
          'colony',
        ],
      ),
      _Tile(
        Icons.apartment_outlined,
        'Buildings',
        AppColors.accentBlue,
        (c) => _go(c, const BuildingCreateScreen()),
        ['building', 'tower', 'block', 'wing', 'floor', 'structure'],
      ),
      _Tile(
        Icons.door_front_door_outlined,
        'Add Flat',
        AppColors.accentPurple,
        (c) => _go(c, const FlatCreateScreen()),
        ['flat', 'unit', 'apartment', 'room', 'house', 'add flat', 'new flat'],
      ),
      _Tile(
        Icons.list_alt_outlined,
        'Flats',
        AppColors.accentTeal,
        (c) => _go(c, const FlatsListScreen()),
        ['flat list', 'unit list', 'all flats', 'rooms', 'units', 'view flats'],
      ),
    ]),
    _HubSection('Settings', [
      _Tile(
        Icons.notifications_outlined,
        'Notifications',
        AppColors.accentOrange,
        (c) => _go(c, const NotificationListScreen()),
        ['alert', 'notify', 'push', 'message', 'bell'],
      ),
      _Tile(
        Icons.logout_rounded,
        'Logout',
        AppColors.accentRed,
        (c) => _logout(c),
        ['sign out', 'exit', 'signout', 'quit'],
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
  final List<String> tags;
  const _Tile(
    this.icon,
    this.label,
    this.color,
    this.onTap, [
    this.tags = const [],
  ]);
}
