import 'package:flutter/material.dart';

import '../config/modules.dart';
import '../services/permission_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

import 'super_admin/society_create_screen.dart';
import 'super_admin/societies_list_screen.dart';
import 'super_admin/building_create_screen.dart';
import 'super_admin/buildings_list_screen.dart';
import 'super_admin/flat_create_screen.dart';
import 'super_admin/flats_list_screen.dart';
import 'super_admin/role_management_screen.dart';
import 'super_admin/secretary_buildings_screen.dart';

import 'secretary/pending_members_screen.dart';
import 'secretary/bill_create_screen.dart';
import 'secretary/bills_manage_screen.dart';
import 'secretary/bills_dashboard_screen.dart';
import 'secretary/amenity_management_screen.dart';
import 'secretary/member_list_screen.dart';
import 'secretary/event_manage_screen.dart';
import 'secretary/payment_mark_screen.dart';

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

import 'security/verify_passcode_screen.dart';
import 'security/walk_in_entry_screen.dart';
import 'security/current_visitors_screen.dart';
import 'common/visitor_report_screen.dart';

// ─── Permission-driven master tile catalogue ─────────────────────────────────
//
// One master section list shared by every role — rendered on the unified
// dashboard AND the services hub. Each tile is gated by a (module, action)
// pair, so filterModuleSections() drops anything the user can't see. Tiles
// that have both a "manager" view and a "member" view auto-pick the
// destination via the dest helpers below — e.g. a user with
// canManage(NOTICES) lands on NoticeCreateScreen, everyone else on
// NoticeListScreen. Add a tile here once and it shows for any role whose
// permissions allow it.

class ModuleSection {
  final String title;
  final List<ModuleTile> tiles;
  const ModuleSection(this.title, this.tiles);
}

class ModuleTile {
  final IconData icon;
  final String label;
  final Color color;
  final void Function(BuildContext context) onTap;
  final List<String> tags;

  /// Module this tile belongs to. null = always shown (e.g. Logout, Notifications).
  final String? module;

  /// Action required on [module] for this tile to be shown. Defaults to view.
  final String requiredAction;

  const ModuleTile(
    this.icon,
    this.label,
    this.color,
    this.onTap, [
    this.tags = const [],
  ]) : module = null,
       requiredAction = PermAction.view;

  const ModuleTile.gated(
    this.icon,
    this.label,
    this.color,
    this.onTap,
    this.module, {
    this.requiredAction = PermAction.view,
    this.tags = const [],
  });
}

/// Drop tiles whose module the user can't access. Drop sections that end up empty.
List<ModuleSection> filterModuleSections(List<ModuleSection> sections) {
  final perms = PermissionService();
  final out = <ModuleSection>[];
  for (final s in sections) {
    final allowed = s.tiles
        .where((t) => t.module == null || perms.can(t.module!, t.requiredAction))
        .toList();
    if (allowed.isNotEmpty) {
      out.add(ModuleSection(s.title, allowed));
    }
  }
  return out;
}

// ── Destination pickers ─────────────────────────────────────────────────────
// Each picker inspects the user's permissions and returns the correct screen
// for that tile. Keeps the section list declarative.

// One shared notices screen for every role — the list shows a manage-gated
// floating add button that opens the create form.
Widget noticesDest() => const NoticeListScreen();

// List-first: every role lands on the list; create/upload screens open via
// the manage-gated floating add button inside each list.
Widget pollsDest() => const PollListScreen();

Widget documentsDest() => const DocumentListScreen();

Widget vehiclesDest() => const VehicleListScreen();

Widget amenitiesDest() {
  // Managers get the management screen, everyone else the booking screen.
  return PermissionService().canManage(ModuleCodes.amenities)
      ? const AmenityManagementScreen()
      : const AmenityBookingScreen();
}

Widget staffDest() => const StaffListScreen();

Widget eventsDest() => const EventManageScreen();

/// Everyone lands on the invite/history list; the analytics overview stays
/// reachable via the manage-gated "Visitor Overview" tile.
Widget visitorsDest() => const VisitorManagementScreen();

// One shared complaints screen for every role — the list gates its add
// button and detail actions on manage internally.
Widget complaintsDest() => const ComplaintListScreen();

Widget billsDest() => PermissionService().canManage(ModuleCodes.bills)
    ? const BillsManageScreen()
    : const BillsListScreen();

// ── Master section list ─────────────────────────────────────────────────────

List<ModuleSection> masterModuleSections() => [
  ModuleSection('Community', [
    ModuleTile.gated(
      Icons.campaign_outlined, 'Notices', ModuleColors.notices,
      (c) => _go(c, noticesDest()),
      ModuleCodes.notices,
      tags: const ['announcement', 'news', 'update', 'broadcast', 'circular', 'alert'],
    ),
    ModuleTile.gated(
      Icons.event_outlined, 'Events', ModuleColors.events,
      (c) => _go(c, const EventManageScreen()),
      ModuleCodes.events,
      tags: const ['event', 'celebration', 'party', 'gathering', 'programme', 'function', 'occasion', 'festival'],
    ),
    ModuleTile.gated(
      Icons.how_to_vote_outlined, 'Polls', ModuleColors.polls,
      (c) => _go(c, pollsDest()),
      ModuleCodes.polls,
      tags: const ['vote', 'survey', 'decision', 'opinion', 'question'],
    ),
    ModuleTile.gated(
      Icons.folder_open_outlined, 'Documents', ModuleColors.documents,
      (c) => _go(c, documentsDest()),
      ModuleCodes.documents,
      tags: const ['doc', 'file', 'pdf', 'upload', 'download', 'paper', 'record', 'form'],
    ),
    ModuleTile.gated(
      Icons.directions_car_outlined, 'Vehicles', ModuleColors.vehicles,
      (c) => _go(c, vehiclesDest()),
      ModuleCodes.vehicles,
      tags: const ['car', 'bike', 'parking', 'motor', 'transport', 'sticker', 'two wheeler', 'four wheeler'],
    ),
  ]),
  ModuleSection('Services', [
    ModuleTile.gated(
      Icons.calendar_today_outlined, 'Amenities', ModuleColors.amenities,
      (c) => _go(c, amenitiesDest()),
      ModuleCodes.amenities,
      tags: const ['gym', 'pool', 'hall', 'club', 'book', 'booking', 'facility', 'sport', 'court', 'ground'],
    ),
    ModuleTile.gated(
      Icons.report_problem_outlined, 'Complaints', ModuleColors.complaints,
      (c) => _go(c, complaintsDest()),
      ModuleCodes.complaints,
      tags: const ['issue', 'problem', 'report', 'complain', 'fix', 'repair', 'request', 'raise', 'grievance'],
    ),
    ModuleTile.gated(
      Icons.cleaning_services_outlined, 'Daily Help', ModuleColors.staff,
      (c) => _go(c, staffDest()),
      ModuleCodes.staff,
      tags: const ['maid', 'cook', 'servant', 'helper', 'housekeeping', 'staff', 'worker', 'cleaning', 'domestic'],
    ),
  ]),
  ModuleSection('Visitors', [
    ModuleTile.gated(
      Icons.person_add_outlined, 'Invite / History', ModuleColors.visitors,
      (c) => _go(c, const VisitorManagementScreen()),
      ModuleCodes.visitors,
      tags: const ['guest', 'pass', 'entry', 'invite', 'visitor', 'outsider', 'log', 'history'],
    ),
    ModuleTile.gated(
      Icons.vpn_key_outlined, 'Verify Code', ModuleColors.verifyCode,
      (c) => _go(c, const VerifyPasscodeScreen()),
      ModuleCodes.visitors,
      requiredAction: PermAction.manage,
      tags: const ['gate', 'guard', 'verify', 'pass code', 'passcode', 'security', 'invite code', 'check in'],
    ),
    ModuleTile.gated(
      Icons.directions_walk_rounded, 'Walk-in Entry', ModuleColors.walkIn,
      (c) => _go(c, const WalkInEntryScreen()),
      ModuleCodes.visitors,
      requiredAction: PermAction.manage,
      tags: const ['gate', 'guard', 'entry', 'delivery', 'walk-in', 'walk in', 'security', 'allow', 'log visitor'],
    ),
    ModuleTile.gated(
      Icons.group_outlined, 'Inside Now', ModuleColors.visitors,
      (c) => _go(c, const CurrentVisitorsScreen()),
      ModuleCodes.visitors,
      tags: const ['current', 'present', 'inside', 'visitor', 'who', 'guest', 'active', 'ongoing'],
    ),
    ModuleTile.gated(
      Icons.history_outlined, 'Visitor Logs', ModuleColors.visitors,
      (c) => _go(c, const VisitorReportScreen()),
      ModuleCodes.visitors,
      tags: const ['history', 'past', 'log', 'visitor', 'report', 'guest', 'exit', 'record'],
    ),
  ]),
  ModuleSection('Billing & Payments', [
    ModuleTile.gated(
      Icons.add_card_outlined, 'Create Bill', ModuleColors.bills,
      (c) => _go(c, const BillCreateScreen()),
      ModuleCodes.bills,
      requiredAction: PermAction.manage,
      tags: const ['generate', 'new', 'billing', 'invoice', 'bill generate', 'make bill', 'add bill'],
    ),
    ModuleTile.gated(
      Icons.receipt_long_outlined, 'Bills', ModuleColors.bills,
      (c) => _go(c, billsDest()),
      ModuleCodes.bills,
      tags: const ['bill', 'payment', 'dues', 'maintenance', 'fees', 'rent', 'pay', 'charge', 'amount', 'monthly', 'view bills', 'all bills'],
    ),
    ModuleTile.gated(
      Icons.payments_outlined, 'Mark Payment', ModuleColors.bills,
      (c) => _go(c, const PaymentMarkScreen()),
      ModuleCodes.bills,
      requiredAction: PermAction.manage,
      tags: const ['payment', 'pay', 'dues', 'maintenance', 'collect', 'mark', 'record', 'paid', 'receipt', 'bill pay', 'collected'],
    ),
    ModuleTile.gated(
      Icons.account_balance_outlined, 'Ledger', ModuleColors.bills,
      (c) => _go(c, const LedgerScreen()),
      ModuleCodes.bills,
      tags: const ['history', 'statement', 'account', 'transaction', 'balance', 'paid', 'receipt'],
    ),
    ModuleTile.gated(
      Icons.pie_chart_outline_rounded, 'Bills Overview', ModuleColors.bills,
      (c) => _go(c, const BillsDashboardScreen()),
      ModuleCodes.bills,
      requiredAction: PermAction.manage,
      tags: const ['overview', 'stats', 'collection', 'summary', 'billing dashboard', 'outstanding'],
    ),
  ]),
  ModuleSection('Administration', [
    ModuleTile.gated(
      Icons.person_add_alt_1_outlined, 'Pending', ModuleColors.users,
      (c) => _go(c, const PendingMembersScreen()),
      ModuleCodes.users,
      requiredAction: PermAction.manage,
      tags: const ['approve', 'request', 'new member', 'join', 'pending member', 'waiting', 'acceptance'],
    ),
    ModuleTile.gated(
      Icons.contacts_outlined, 'Residents', ModuleColors.users,
      (c) => _go(c, const MemberListScreen()),
      ModuleCodes.users,
      tags: const ['member', 'flat', 'tenant', 'owner', 'resident', 'people', 'family', 'occupant', 'contact'],
    ),
    ModuleTile.gated(
      Icons.business_outlined, 'Societies', ModuleColors.buildings,
      (c) => _go(c, const SocietyCreateScreen()),
      ModuleCodes.buildings,
      requiredAction: PermAction.manage,
      tags: const ['society', 'create society', 'new society', 'apartment', 'complex', 'housing', 'colony'],
    ),
    ModuleTile.gated(
      Icons.apartment_outlined, 'Buildings', ModuleColors.buildings,
      (c) => _go(c, const BuildingCreateScreen()),
      ModuleCodes.buildings,
      requiredAction: PermAction.manage,
      tags: const ['building', 'tower', 'block', 'wing', 'floor', 'structure'],
    ),
    ModuleTile.gated(
      Icons.door_front_door_outlined, 'Add Flat', ModuleColors.buildings,
      (c) => _go(c, const FlatCreateScreen()),
      ModuleCodes.buildings,
      requiredAction: PermAction.manage,
      tags: const ['flat', 'unit', 'apartment', 'room', 'house', 'add flat', 'new flat'],
    ),
    ModuleTile.gated(
      Icons.list_alt_outlined, 'Flats', ModuleColors.buildings,
      (c) => _go(c, const FlatsListScreen()),
      ModuleCodes.buildings,
      tags: const ['flat list', 'unit list', 'all flats', 'rooms', 'units', 'view flats'],
    ),
    ModuleTile.gated(
      Icons.location_city_outlined, 'All Societies', ModuleColors.buildings,
      (c) => _go(c, const SocietiesListScreen()),
      ModuleCodes.buildings,
      tags: const ['society list', 'all societies', 'directory', 'view societies', 'edit society'],
    ),
    ModuleTile.gated(
      Icons.domain_outlined, 'All Buildings', ModuleColors.buildings,
      (c) => _go(c, const BuildingsListScreen()),
      ModuleCodes.buildings,
      tags: const ['building list', 'all buildings', 'directory', 'blocks', 'sectors', 'view buildings'],
    ),
  ]),
  ModuleSection('System', [
    ModuleTile.gated(
      Icons.shield_outlined, 'Roles', ModuleColors.roles,
      (c) => _go(c, const RoleManagementScreen()),
      ModuleCodes.roles,
      tags: const ['role', 'permission', 'access', 'module access', 'rights', 'configure'],
    ),
    ModuleTile.gated(
      Icons.assignment_ind_outlined, 'Secretaries', ModuleColors.roles,
      (c) => _go(c, const SecretaryBuildingsScreen()),
      ModuleCodes.roles,
      tags: const ['secretary', 'assign', 'secretary buildings', 'society admin', 'building assign'],
    ),
  ]),
];

void _go(BuildContext context, Widget screen) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

// ─── Section block ───────────────────────────────────────────────────────────

class ModuleSectionView extends StatelessWidget {
  final String title;
  final List<ModuleTile> tiles;
  const ModuleSectionView({super.key, required this.title, required this.tiles});

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
        ModuleGrid(tiles: tiles),
      ],
    );
  }
}

class ModuleGrid extends StatelessWidget {
  final List<ModuleTile> tiles;
  const ModuleGrid({super.key, required this.tiles});

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
                      ? _ModuleTileView(tile: rowTiles[i])
                      : const SizedBox(height: 98),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _ModuleTileView extends StatelessWidget {
  final ModuleTile tile;
  const _ModuleTileView({required this.tile});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => tile.onTap(context),
      behavior: HitTestBehavior.opaque,
      child: AppIconTile(
        icon: tile.icon,
        color: tile.color,
        label: tile.label,
      ),
    );
  }
}
