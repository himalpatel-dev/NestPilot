import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_bottom_nav.dart';
import '../dashboard_screen.dart';
import '../services_hub_screen.dart';
import '../common/visitor_report_screen.dart';
import '../login_screen.dart';
import 'bills_manage_screen.dart';

class MemberListScreen extends StatefulWidget {
  final bool embedded;
  const MemberListScreen({super.key, this.embedded = false});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchCtrl = TextEditingController();

  // Secretary tab index for "Residents" — matches dashboard nav order.
  static const int _residentsTabIndex = 1;

  List<UserModel> _members = [];
  bool _isLoading = true;
  String? _error;
  String _query = '';
  _SortMode _sortMode = _SortMode.flat;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final members = await _adminService.getSocietyMembers();
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ─── Derived stats ─────────────────────────────────────────────────────────

  int get _ownerCount =>
      _members.where((m) => _isOwner(m.relationType)).length;

  int get _tenantCount =>
      _members.where((m) => _isTenant(m.relationType)).length;

  int get _occupiedCount {
    final flats = <String>{};
    for (final m in _members) {
      final f = m.flatNumber;
      if (f != null && f.isNotEmpty) flats.add(f);
    }
    return flats.length;
  }

  // Vacant flats are not derivable from the members endpoint alone.
  // Shown as 0 until a flats endpoint is wired in for this society.
  int get _vacantCount => 0;

  bool _isOwner(String? rel) {
    final r = (rel ?? '').toUpperCase();
    return r == 'OWNER' || r == 'OWNER_RESIDENT' || r == 'SELF';
  }

  bool _isTenant(String? rel) {
    final r = (rel ?? '').toUpperCase();
    return r == 'TENANT' || r == 'RENTER';
  }

  String _relationLabel(String? rel) {
    if (_isOwner(rel)) return 'Owner';
    if (_isTenant(rel)) return 'Tenant';
    if (rel == null || rel.isEmpty) return 'Resident';
    return rel.replaceAll('_', ' ');
  }

  // ─── Filter + sort ─────────────────────────────────────────────────────────

  List<UserModel> get _visible {
    Iterable<UserModel> list = _members;

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((m) {
        return m.fullName.toLowerCase().contains(q) ||
            (m.flatNumber ?? '').toLowerCase().contains(q) ||
            m.mobile.toLowerCase().contains(q);
      });
    }

    final result = list.toList();
    switch (_sortMode) {
      case _SortMode.flat:
        result.sort(
          (a, b) => (a.flatNumber ?? '').compareTo(b.flatNumber ?? ''),
        );
        break;
      case _SortMode.name:
        result.sort(
          (a, b) => a.fullName.toLowerCase().compareTo(
            b.fullName.toLowerCase(),
          ),
        );
        break;
      case _SortMode.relation:
        result.sort(
          (a, b) => _relationLabel(
            a.relationType,
          ).compareTo(_relationLabel(b.relationType)),
        );
        break;
    }
    return result;
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

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
        backgroundColor: AppColors.black,
        bottomNavigationBar: AppBottomNav(
          selectedIndex: _residentsTabIndex,
          bottomPadding: bottomPad,
          onTap: _onNavTap,
          items: const [
            AppNavItem(Icons.home_rounded, 'Home'),
            AppNavItem(Icons.contacts_rounded, 'Residents'),
            AppNavItem(Icons.apps_rounded, 'Services'),
            AppNavItem(Icons.receipt_long_rounded, 'Bills'),
            AppNavItem(Icons.person_pin_circle_rounded, 'Visitor'),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.black,
            backgroundColor: AppColors.primary,
            onRefresh: _fetchMembers,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      _buildStatsGrid(),
                      const SizedBox(height: 22),
                      _buildListHeader(),
                      const SizedBox(height: 12),
                      _buildList(),
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

  // ─── Tab nav ───────────────────────────────────────────────────────────────

  Future<void> _onNavTap(int index) async {
    if (index == _residentsTabIndex) return;

    // Home tab — pop back to dashboard if we got pushed from it,
    // otherwise rebuild the dashboard from the current user.
    if (index == 0) {
      if (!widget.embedded && Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        await _goHome();
      }
      return;
    }

    Widget? target;
    switch (index) {
      case 2:
        final user = await _currentUser();
        if (user != null) target = ServicesHubScreen(user: user);
        break;
      case 3:
        target = const BillsManageScreen();
        break;
      case 4:
        target = const VisitorReportScreen();
        break;
    }
    if (target != null && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => target!));
    }
  }

  Future<void> _goHome() async {
    final user = await _currentUser();
    if (user == null || !mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => DashboardScreen(user: user)),
      (r) => false,
    );
  }

  Future<UserModel?> _currentUser() async {
    try {
      final user = await AuthService().getMe();
      if (user == null && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (r) => false,
        );
      }
      return user;
    } catch (_) {
      return null;
    }
  }

  // ─── Header (top bar) ──────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 14),
      child: Row(
        children: [
          if (!widget.embedded)
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.white.withValues(alpha: 0.9),
                size: 18,
              ),
            )
          else
            const SizedBox(width: 16),
          const Text(
            'Residents',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            '${_members.length} total',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.55),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    final hasQuery = _query.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasQuery
              ? AppColors.primary.withValues(alpha: 0.45)
              : AppColors.white.withValues(alpha: 0.06),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: hasQuery
                ? AppColors.primary
                : AppColors.white.withValues(alpha: 0.55),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
              cursorColor: AppColors.primary,
              cursorHeight: 18,
              decoration: InputDecoration(
                // Override the global filled=true + grey.shade50 fill from main.dart
                // so the dark container shows through.
                filled: true,
                fillColor: AppColors.transparent,
                hintText: 'Search by name, flat or mobile',
                hintStyle: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.40),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
          ),
          if (hasQuery)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.white.withValues(alpha: 0.55),
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Stats grid (Owners / Tenants / Occupied / Vacant) ─────────────────────

  Widget _buildStatsGrid() {
    final tiles = <_ResidentStat>[
      _ResidentStat(
        value: '$_ownerCount',
        label: 'Owners',
        color: AppColors.accentOrange,
      ),
      _ResidentStat(
        value: '$_tenantCount',
        label: 'Tenants',
        color: AppColors.accentPurple,
      ),
      _ResidentStat(
        value: '$_occupiedCount',
        label: 'Occupied',
        color: AppColors.accentBlue,
      ),
      _ResidentStat(
        value: '$_vacantCount',
        label: 'Vacant',
        color: AppColors.accentGreen,
      ),
    ];

    return Row(
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _statTile(tiles[i])),
        ],
      ],
    );
  }

  Widget _statTile(_ResidentStat s) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Text(
            s.value,
            style: TextStyle(
              color: s.color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.label,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.60),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── List header (title + sort) ────────────────────────────────────────────

  Widget _buildListHeader() {
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
            const Text(
              'Resident List',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: _showSortSheet,
          child: Row(
            children: [
              Text(
                'Sort',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.75),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.white.withValues(alpha: 0.75),
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Resident list ─────────────────────────────────────────────────────────

  Widget _buildList() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
    }
    if (_error != null) {
      return _emptyBox(
        icon: Icons.error_outline,
        title: 'Could not load residents',
        subtitle: _error!,
        actionLabel: 'Retry',
        onAction: _fetchMembers,
      );
    }

    final list = _visible;
    if (list.isEmpty) {
      return _emptyBox(
        icon: Icons.group_off_rounded,
        title: _query.isEmpty
            ? 'No residents yet'
            : 'No residents match "$_query"',
      );
    }

    return Column(
      children: [
        for (int i = 0; i < list.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _residentTile(list[i]),
        ],
      ],
    );
  }

  Widget _residentTile(UserModel user) {
    final initials = _initials(user.fullName);
    final relation = _relationLabel(user.relationType);
    final flat = (user.flatNumber ?? '').isNotEmpty ? user.flatNumber! : '—';

    return GestureDetector(
      onTap: () => _showResidentSheet(user),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            _avatar(initials),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        flat,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _relationChip(user.relationType),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    user.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    relation,
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.55),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _circleAction(
              icon: Icons.phone_rounded,
              color: AppColors.accentGreen,
              onTap: () => _call(user.mobile),
            ),
            const SizedBox(width: 10),
            _circleAction(
              icon: Icons.remove_red_eye_rounded,
              color: AppColors.accentPurple,
              onTap: () => _showResidentSheet(user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _relationChip(String? rel) {
    if (!_isOwner(rel) && !_isTenant(rel)) return const SizedBox.shrink();
    final isOwner = _isOwner(rel);
    final color = isOwner ? AppColors.accentOrange : AppColors.accentPurple;
    final label = isOwner ? 'Owner' : 'Tenant';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _avatar(String initials) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.black,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _circleAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }

  Widget _emptyBox({
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.white.withValues(alpha: 0.45), size: 32),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.50),
                fontSize: 11.5,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Sheets / actions ──────────────────────────────────────────────────────

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _grabber(),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Sort residents by',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _sortOption(
                label: 'Flat number',
                mode: _SortMode.flat,
                ctx: ctx,
              ),
              _sortOption(label: 'Name', mode: _SortMode.name, ctx: ctx),
              _sortOption(
                label: 'Owner / Tenant',
                mode: _SortMode.relation,
                ctx: ctx,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sortOption({
    required String label,
    required _SortMode mode,
    required BuildContext ctx,
  }) {
    final selected = _sortMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _sortMode = mode);
        Navigator.pop(ctx);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? AppColors.primary
                  : AppColors.white.withValues(alpha: 0.45),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.white
                    : AppColors.white.withValues(alpha: 0.80),
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResidentSheet(UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _grabber(),
              const SizedBox(height: 18),
              Row(
                children: [
                  _avatar(_initials(user.fullName)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _relationLabel(user.relationType),
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.60),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _detailRow(
                Icons.door_front_door_outlined,
                'Flat',
                user.flatNumber ?? '—',
              ),
              _detailRow(Icons.phone_outlined, 'Mobile', user.mobile),
              if ((user.email ?? '').isNotEmpty)
                _detailRow(Icons.email_outlined, 'Email', user.email!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.white.withValues(alpha: 0.45), size: 18),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.55),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _grabber() => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> _call(String mobile) async {
    final uri = Uri(scheme: 'tel', path: mobile);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _ResidentStat {
  final String value;
  final String label;
  final Color color;
  const _ResidentStat({
    required this.value,
    required this.label,
    required this.color,
  });
}

enum _SortMode { flat, name, relation }
