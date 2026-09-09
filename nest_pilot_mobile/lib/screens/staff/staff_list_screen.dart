import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:intl/intl.dart';

import '../../../config/modules.dart';
import '../../../models/community_models.dart';
import '../../../services/community_service.dart';
import '../../../services/permission_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/nest_loader.dart';
import '../../../widgets/app_field_card.dart';
import '../../../widgets/app_form_sheet.dart';
import '../../../widgets/glare_button.dart';
import '../../../widgets/module_page_header.dart';
import '../../../widgets/status_widgets.dart';

// ── Role helpers — shared by the list, the cards and the add sheet ───────────

/// The roles the backend's ServiceStaff enum accepts.
const List<String> _staffRoles = [
  'MAID',
  'DRIVER',
  'COOK',
  'GARDENER',
  'SECURITY',
  'OTHER',
];

IconData _roleIcon(String role) {
  switch (role.toUpperCase()) {
    case 'MAID':
      return Icons.cleaning_services_outlined;
    case 'DRIVER':
      return Icons.local_taxi_outlined;
    case 'COOK':
      return Icons.restaurant_rounded;
    case 'GARDENER':
      return Icons.yard_outlined;
    case 'SECURITY':
      return Icons.shield_outlined;
    default:
      return Icons.handyman_outlined;
  }
}

Color _roleColor(String role) {
  switch (role.toUpperCase()) {
    case 'MAID':
      return AppColors.accentPurple;
    case 'DRIVER':
      return AppColors.accentBlue;
    case 'COOK':
      return AppColors.accentOrange;
    case 'GARDENER':
      return AppColors.accentGreen;
    case 'SECURITY':
      return AppColors.accentIndigo;
    default:
      return AppColors.accentTeal;
  }
}

String _roleLabel(String role) {
  if (role.isEmpty) return role;
  return role[0].toUpperCase() + role.substring(1).toLowerCase();
}

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  final CommunityService _service = CommunityService();
  final TextEditingController _searchController = TextEditingController();

  List<ServiceStaff> _staff = [];
  bool _isLoading = true;
  String? _error;

  String _query = '';
  String _roleFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStaff() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final staff = await _service.getAllStaff();
      if (!mounted) return;
      setState(() {
        _staff = staff;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<ServiceStaff> get _filtered {
    final q = _query.trim().toLowerCase();
    return _staff.where((s) {
      final matchesRole = _roleFilter == 'ALL' || s.role == _roleFilter;
      final matchesQuery =
          q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.role.toLowerCase().contains(q) ||
          s.mobile.contains(q);
      return matchesRole && matchesQuery;
    }).toList();
  }

  void _openAttendance(ServiceStaff staff) {
    showAppFormSheet(
      context: context,
      builder: (ctx) => StaffAttendanceSheet(staff: staff),
    );
  }

  void _openAddSheet() {
    showAppFormSheet(
      context: context,
      builder: (ctx) => _StaffFormSheet(
        onSaved: () {
          Navigator.pop(ctx);
          _fetchStaff();
        },
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canManage = PermissionService().canManage(ModuleCodes.staff);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      // Header and filter chips stay pinned; only the staff cards scroll.
      body: Column(
        children: [
          _buildHeader(),
          if (!_isLoading && _error == null) _buildFilters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchStaff,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (_isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: NestLoader(),
                    )
                  else if (_error != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ErrorWidgetView(
                        message: _error!,
                        onRetry: _fetchStaff,
                      ),
                    )
                  else if (_filtered.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyWidget(
                        message: 'No daily help found',
                        icon: Icons.cleaning_services_outlined,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad + 90),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _buildCard(_filtered[i]),
                          childCount: _filtered.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Adding staff is a manage-only action — the list itself is shared with
      // view-only roles.
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: _openAddSheet,
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final active = _staff.where((s) => s.isActive).length;
    final roles = _staff.map((s) => s.role).toSet().length;

    return ModulePageHeader(
      title: 'Daily Help',
      description: 'Society staff & attendance',
      icon: Icons.cleaning_services_outlined,
      iconColor: ModuleColors.staff,
      stats: [
        ModuleHeaderStat('${_staff.length}', 'TOTAL'),
        ModuleHeaderStat('$active', 'ACTIVE'),
        ModuleHeaderStat('$roles', 'ROLES'),
      ],
      showSearch: true,
      searchHint: 'Search daily help...',
      searchController: _searchController,
      onSearchChanged: (v) => setState(() => _query = v),
    );
  }

  // ─── Filter chips ───────────────────────────────────────────────────────────

  Widget _buildFilters() {
    // Only offer the roles actually present, so the row doesn't fill with
    // chips that can never match anything.
    final present = _staff.map((s) => s.role).toSet().toList()..sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('All', 'ALL'),
            for (final role in present) ...[
              const SizedBox(width: 8),
              _filterChip(_roleLabel(role), role),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _roleFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _roleFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ─── Staff card ─────────────────────────────────────────────────────────────

  Widget _buildCard(ServiceStaff staff) {
    final color = _roleColor(staff.role);

    return GestureDetector(
      onTap: () => _openAttendance(staff),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        child: Row(
          children: [
            _avatar(staff, color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          staff.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: color.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Text(
                          _roleLabel(staff.role),
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_rounded,
                        size: 11,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        staff.mobile,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      if (!staff.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentRed.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'INACTIVE',
                            style: TextStyle(
                              color: AppColors.accentRed,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Attendance is the card's whole point, so the chip repeats the
            // row's tap target rather than replacing it.
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ModuleColors.staff.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.event_available_rounded,
                size: 19,
                color: ModuleColors.staff,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(ServiceStaff staff, Color color) {
    final image = staff.profileImage;
    if (image != null && image.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          image,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _iconAvatar(staff, color),
        ),
      );
    }
    return _iconAvatar(staff, color);
  }

  Widget _iconAvatar(ServiceStaff staff, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Icon(_roleIcon(staff.role), color: color, size: 24),
    );
  }
}

// ── Add daily help sheet ─────────────────────────────────────────────────────

class _StaffFormSheet extends StatefulWidget {
  final VoidCallback onSaved;

  const _StaffFormSheet({required this.onSaved});

  @override
  State<_StaffFormSheet> createState() => _StaffFormSheetState();
}

class _StaffFormSheetState extends State<_StaffFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();

  final CommunityService _service = CommunityService();

  String _role = 'MAID';
  bool _isLoading = false;

  // Inline error state — modal sheets hide snackbars behind them, so API
  // failures are surfaced in the sheet instead.
  String? _apiError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _aadhaarCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _apiError = null;
    });
    try {
      await _service.addStaff({
        'name': _nameCtrl.text.trim(),
        'mobile': _mobileCtrl.text.trim(),
        'role': _role,
        'aadhaar_number': _aadhaarCtrl.text.trim(),
      });
      if (mounted) widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(
          () => _apiError = e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      accentColor: ModuleColors.staff,
      icon: Icons.person_add_alt_1_rounded,
      title: 'Add Daily Help',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader('Staff Details'),
            const SizedBox(height: 14),
            AppFieldCard(
              icon: Icons.person_outline_rounded,
              label: 'Full Name',
              field: AppBorderlessField(
                controller: _nameCtrl,
                hint: 'e.g. Ramesh Kumar',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
            ),
            const SizedBox(height: 12),
            AppFieldCard(
              icon: Icons.phone_rounded,
              label: 'Mobile Number',
              field: AppBorderlessField(
                controller: _mobileCtrl,
                hint: '10-digit mobile number',
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (v == null || v.trim().length != 10)
                    ? 'Enter a 10-digit mobile number'
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            AppFieldCard(
              icon: Icons.badge_outlined,
              label: 'Role',
              field: AppCardDropdown<String>(
                value: _role,
                items: _staffRoles,
                itemLabel: _roleLabel,
                onChanged: (v) => setState(() => _role = v!),
              ),
            ),
            const SizedBox(height: 24),
            const AppSectionHeader('Identification'),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text(
                'Optional — helps the gate verify who is coming in',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            AppFieldCard(
              icon: Icons.credit_card_rounded,
              label: 'Aadhaar Number',
              field: AppBorderlessField(
                controller: _aadhaarCtrl,
                hint: '12-digit Aadhaar number',
                keyboardType: TextInputType.number,
                maxLength: 12,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                // Optional, but a partial number is worse than none.
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty || value.length == 12) return null;
                  return 'Aadhaar must be 12 digits';
                },
              ),
            ),
            if (_apiError != null) ...[
              const SizedBox(height: 18),
              AppSheetErrorBanner(_apiError!),
            ],
            const SizedBox(height: 26),
            GlarePrimaryButton(
              text: 'Add Daily Help',
              trailingIcon: Icons.check_rounded,
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Attendance sheet ─────────────────────────────────────────────────────────

class StaffAttendanceSheet extends StatefulWidget {
  final ServiceStaff staff;

  const StaffAttendanceSheet({super.key, required this.staff});

  @override
  State<StaffAttendanceSheet> createState() => _StaffAttendanceSheetState();
}

class _StaffAttendanceSheetState extends State<StaffAttendanceSheet> {
  final CommunityService _service = CommunityService();

  List<StaffAttendance> _attendance = [];
  bool _isLoading = true;
  String? _marking; // 'IN' / 'OUT' while that button is in flight

  // A modal sheet renders on top of any snackbar, so failures are surfaced
  // inline instead.
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    try {
      final data = await _service.getStaffAttendance(widget.staff.id);
      if (!mounted) return;
      setState(() {
        _attendance = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _markAttendance(String type) async {
    setState(() {
      _marking = type;
      _error = null;
    });
    try {
      await _service.markStaffAttendance(widget.staff.id, type);
      if (!mounted) return;
      setState(() => _marking = null);
      await _fetchAttendance();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _marking = null;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// Today's row, when there is one — drives the "checked in / out" summary.
  StaffAttendance? get _today {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    for (final a in _attendance) {
      if (a.date.startsWith(today)) return a;
    }
    return null;
  }

  String _time(String? raw) {
    if (raw == null) return '—';
    final parsed = DateTime.tryParse(raw);
    return parsed == null ? '—' : DateFormat('hh:mm a').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final canManage = PermissionService().canManage(ModuleCodes.staff);

    return AppFormSheet(
      accentColor: ModuleColors.staff,
      icon: Icons.event_available_rounded,
      title: widget.staff.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _todayCard(),
          if (canManage) ...[
            const SizedBox(height: 22),
            const AppSectionHeader('Mark Attendance'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _markButton(
                    type: 'IN',
                    label: 'Mark Entry',
                    icon: Icons.login_rounded,
                    color: AppColors.accentGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _markButton(
                    type: 'OUT',
                    label: 'Mark Exit',
                    icon: Icons.logout_rounded,
                    color: AppColors.accentRed,
                  ),
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 18),
            AppSheetErrorBanner(_error!),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              const AppSectionHeader('History'),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ModuleColors.staff.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_attendance.length}',
                  style: const TextStyle(
                    color: ModuleColors.staff,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: NestLoader(size: 44, showDots: false)),
            )
          else if (_attendance.isEmpty)
            _emptyHistory()
          else
            // A ListView here would scroll inside the sheet's own scroll view,
            // so the rows are laid out as a plain column instead.
            for (final a in _attendance) _historyRow(a),
        ],
      ),
    );
  }

  // ─── Today ──────────────────────────────────────────────────────────────────

  Widget _todayCard() {
    final today = _today;
    final inTime = _time(today?.inTime);
    final outTime = _time(today?.outTime);
    final isIn = today?.inTime != null && today?.outTime == null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'TODAY',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (isIn ? AppColors.accentGreen : AppColors.textHint)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isIn ? 'ON DUTY' : 'OFF DUTY',
                  style: TextStyle(
                    color: isIn ? AppColors.accentGreen : AppColors.textHint,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _timeCell(
                  label: 'Entry',
                  value: inTime,
                  icon: Icons.login_rounded,
                  color: AppColors.accentGreen,
                ),
              ),
              Container(width: 1, height: 38, color: AppColors.border),
              Expanded(
                child: _timeCell(
                  label: 'Exit',
                  value: outTime,
                  icon: Icons.logout_rounded,
                  color: AppColors.accentRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeCell({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final empty = value == '—';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: empty ? 0.06 : 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 16,
            color: empty ? AppColors.textHint : color,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: empty ? AppColors.textHint : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Mark buttons ───────────────────────────────────────────────────────────

  /// Re-marking overwrites today's recorded time, so the old value is shown
  /// before it goes.
  Future<void> _confirmRemark(String type, Color color) async {
    final isEntry = type == 'IN';
    final current = _time(isEntry ? _today?.inTime : _today?.outTime);
    final word = isEntry ? 'entry' : 'exit';
    // A new entry invalidates an exit stamped earlier in the day — the server
    // clears it, so say so up front.
    final clearsExit = isEntry && _today?.outTime != null;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.15),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                color: color,
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.40),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: AppColors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Replace $word time?',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Currently $current',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  children: [
                    Text(
                      clearsExit
                          ? "Today's entry time will be replaced with the "
                                'current time, and the exit time will be '
                                'cleared — an exit before the new entry '
                                "isn't possible."
                          : "Today's $word time will be replaced with the "
                                'current time. The old one is not kept.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx, false),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx, true),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Replace',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) await _markAttendance(type);
  }

  /// Two states, same label: pale and outlined while today's time is still
  /// unstamped, solid with a tick once it is marked — so the pair reads at a
  /// glance. Tapping a marked side confirms first, since re-marking replaces
  /// the recorded time.
  Widget _markButton({
    required String type,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final busy = _marking == type;
    final dimmed = _marking != null && !busy;
    final marked = type == 'IN'
        ? _today?.inTime != null
        : _today?.outTime != null;
    final fg = marked ? AppColors.white : color;

    return GestureDetector(
      onTap: _marking != null
          ? null
          : () => marked ? _confirmRemark(type, color) : _markAttendance(type),
      child: Opacity(
        opacity: dimmed ? 0.5 : 1,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: marked ? color : color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: marked
                ? null
                : Border.all(color: color.withValues(alpha: 0.30)),
            boxShadow: marked
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: busy
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      marked ? Icons.check_circle_rounded : icon,
                      size: 17,
                      color: fg,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: fg,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ─── History ────────────────────────────────────────────────────────────────

  Widget _historyRow(StaffAttendance a) {
    final date = DateTime.tryParse(a.date);
    final dateLabel = date == null
        ? a.date
        : DateFormat('dd MMM yyyy').format(date);
    final dayLabel = date == null ? '' : DateFormat('EEEE').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (dayLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dayLabel,
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _timeChip(_time(a.inTime), AppColors.accentGreen),
          const SizedBox(width: 6),
          _timeChip(_time(a.outTime), AppColors.accentRed),
        ],
      ),
    );
  }

  Widget _timeChip(String value, Color color) {
    final empty = value == '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: (empty ? AppColors.textHint : color).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: empty ? AppColors.textHint : color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _emptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.event_busy_outlined,
              size: 24,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No attendance yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Entry and exit times will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
