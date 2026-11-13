import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/managed_user.dart';
import '../../models/role_permission_model.dart';
import '../../models/society_structure.dart';
import '../../services/role_service.dart';
import '../../services/secretary_building_service.dart';
import '../../services/session_service.dart';
import '../../services/user_management_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/nest_loader.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_form_sheet.dart'
    show AppFormSheet, AppPickerCard, showAppFormSheet;
import '../../widgets/app_sheet_action.dart';
import '../../widgets/module_page_header.dart';
import '../../widgets/society_picker_sheet.dart';
import 'secretary_assign_screen.dart';
import 'user_form_screen.dart';

/// Super Admin's platform-wide user directory: every user in every society,
/// searchable and filterable by society, role and status, loaded a page at a
/// time so it keeps up as societies are added. Tap a user to approve, block,
/// edit or move them, or to assign a secretary's buildings.
class UserManagementScreen extends StatefulWidget {
  /// Opens filtered to one society (e.g. from the societies directory).
  final Society? society;

  /// Opens filtered to one status, e.g. 'pending' for approvals.
  final String? initialStatus;

  const UserManagementScreen({super.key, this.society, this.initialStatus});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

enum _UserAction { approve, reject, block, unblock, edit, assignBuildings, call }

const List<(String, String)> _statusOptions = [
  ('active', 'Active'),
  ('pending', 'Pending'),
  ('blocked', 'Blocked'),
  ('rejected', 'Rejected'),
];

/// The filters picked in [_UserFilterSheet]; null fields mean "all".
typedef _UserFilters = ({Society? society, RoleModel? role, String? status});

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserManagementService _service = UserManagementService();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  // Filters
  Society? _society;
  RoleModel? _role;
  String? _status;
  String _query = '';
  bool _sortByName = false;

  List<RoleModel> _roles = [];
  UserStats _stats = const UserStats();
  final List<ManagedUser> _users = [];
  int _total = 0;
  int _page = 0;
  bool _hasMore = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  String? _loadMoreError;

  // Bumped by every reload so responses for stale filters are dropped.
  int _requestId = 0;

  int? get _societyId => _society == null ? null : int.tryParse(_society!.id);

  bool get _hasFilters =>
      _query.isNotEmpty || _society != null || _role != null || _status != null;

  /// Society / status / role filters in effect (search is not counted).
  int get _activeFilterCount =>
      (_society != null ? 1 : 0) +
      (_status != null ? 1 : 0) +
      (_role != null ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _society = widget.society;
    _status = widget.initialStatus;
    _loadRoles();
    _reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadRoles() async {
    try {
      final roles = await RoleService().getRoles();
      if (mounted) setState(() => _roles = roles);
    } catch (_) {
      // Role chips are a convenience — the list still works without them.
    }
  }

  Future<UserPage> _fetchPage(int page) => _service.getUsers(
    page: page,
    search: _query,
    societyId: _societyId,
    roleId: _role?.id,
    status: _status,
    sortByName: _sortByName,
  );

  /// Reloads page 1 and the header counts for the current filters.
  Future<void> _reload() async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _loadMoreError = null;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _fetchPage(1),
        _service.getStats(societyId: _societyId),
      ]);
      if (!mounted || requestId != _requestId) return;
      final page = results[0] as UserPage;
      setState(() {
        _users
          ..clear()
          ..addAll(page.items);
        _total = page.total;
        _hasMore = page.hasMore;
        _page = 1;
        _stats = results[1] as UserStats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = _errorText(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore || _loadMoreError != null) {
      return;
    }
    final requestId = _requestId;
    setState(() => _isLoadingMore = true);
    try {
      final page = await _fetchPage(_page + 1);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _users.addAll(page.items);
        _total = page.total;
        _hasMore = page.hasMore;
        _page += 1;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loadMoreError = _errorText(e);
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshStats() async {
    try {
      final stats = await _service.getStats(societyId: _societyId);
      if (mounted) setState(() => _stats = stats);
    } catch (_) {}
  }

  bool _matchesFilters(ManagedUser u) =>
      (_status == null || u.status == _status) &&
      (_role == null || u.roleId == _role!.id) &&
      (_society == null || u.societyId == _societyId);

  /// Swaps a changed user into the list in place — keeping the scroll
  /// position — or drops them if they no longer match the filters.
  void _applyUpdate(ManagedUser updated) {
    final i = _users.indexWhere((u) => u.id == updated.id);
    if (i != -1) {
      setState(() {
        if (_matchesFilters(updated)) {
          _users[i] = updated;
        } else {
          _users.removeAt(i);
          _total = _total > 0 ? _total - 1 : 0;
        }
      });
    }
    _refreshStats();
  }

  // ─── Filters ───────────────────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final q = value.trim();
      if (q == _query) return;
      _query = q;
      _reload();
    });
  }

  void _setStatus(String? status) {
    if (status == _status) return;
    _status = status;
    _reload();
  }

  void _setRole(RoleModel? role) {
    if (role?.id == _role?.id) return;
    _role = role;
    _reload();
  }

  void _clearSociety() {
    _society = null;
    _reload();
  }

  void _clearFilters() {
    _society = null;
    _status = null;
    _role = null;
    _reload();
  }

  /// Society, status and role live in one sheet behind the search bar's
  /// filter button, so the list keeps the screen space.
  Future<void> _openFilters() async {
    final picked = await showAppFormSheet<_UserFilters>(
      context: context,
      builder: (_) => _UserFilterSheet(
        initial: (society: _society, role: _role, status: _status),
        roles: _roles,
        stats: _stats,
      ),
    );
    if (picked == null || !mounted) return;
    if (picked.society?.id == _society?.id &&
        picked.role?.id == _role?.id &&
        picked.status == _status) {
      return;
    }
    _society = picked.society;
    _role = picked.role;
    _status = picked.status;
    _reload();
  }

  void _toggleSort() {
    _sortByName = !_sortByName;
    _reload();
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> _openForm([ManagedUser? user]) async {
    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => UserFormScreen(
          user: user,
          initialSociety: user == null ? _society : null,
        ),
      ),
    );
    if (!mounted) return;
    if (result is ManagedUser) {
      _applyUpdate(result);
    } else if (result == true) {
      _reload();
    }
  }

  Future<void> _openUser(ManagedUser user) async {
    final result = await showModalBottomSheet<(_UserAction, ManagedUser)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _UserDetailSheet(
        user: user,
        isSelf: '${user.id}' == SessionService().currentUser?.id,
      ),
    );
    if (result == null || !mounted) return;
    final (action, latest) = result;
    switch (action) {
      case _UserAction.approve:
      case _UserAction.unblock:
        _changeStatus(latest, 'active');
      case _UserAction.reject:
        _changeStatus(latest, 'rejected');
      case _UserAction.block:
        _changeStatus(latest, 'blocked');
      case _UserAction.edit:
        _openForm(latest);
      case _UserAction.assignBuildings:
        _assignBuildings(latest);
      case _UserAction.call:
        _call(latest.mobile);
    }
  }

  Future<void> _changeStatus(ManagedUser user, String status) async {
    if (status == 'blocked') {
      final ok = await _confirm(
        title: 'Block User',
        message:
            "${user.fullName} won't be able to use the app until you unblock them.",
        action: 'Block',
      );
      if (!ok) return;
    } else if (status == 'rejected') {
      final ok = await _confirm(
        title: 'Reject User',
        message:
            "${user.fullName}'s account will be rejected and they won't be able to sign in.",
        action: 'Reject',
      );
      if (!ok) return;
    }

    try {
      final updated = await _service.setStatus(user.id, status);
      if (!mounted) return;
      _applyUpdate(updated);
      _snack(switch (status) {
        'blocked' => '${updated.fullName} has been blocked',
        'rejected' => '${updated.fullName} has been rejected',
        _ => '${updated.fullName} is now active',
      });
    } catch (e) {
      _snack(_errorText(e));
    }
  }

  void _assignBuildings(ManagedUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SecretaryAssignScreen(
          admin: SecretaryAdmin(
            id: user.id,
            fullName: user.fullName,
            mobile: user.mobile,
            email: user.email,
            societyId: user.societyId,
            societyName: user.societyName,
            buildings: user.assignedBuildings,
          ),
        ),
      ),
    );
  }

  Future<void> _call(String mobile) async {
    final uri = Uri(scheme: 'tel', path: mobile);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
            child: Text(
              action,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    return ok == true;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      // The pinned block is tall — let the keyboard cover the list rather than
      // squeeze the column and overflow on small phones.
      resizeToAvoidBottomInset: false,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        icon: const Icon(
          Icons.person_add_alt_1_rounded,
          color: AppColors.white,
          size: 20,
        ),
        label: const Text(
          'Add User',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
      // Header, search, filters and the count row stay pinned; only the user
      // cards scroll.
      body: Column(
        children: [
          _buildHeader(),
          // Bottom padding is a fixed gap, so cards scroll away below it
          // instead of butting against the count row.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: _buildListHeader(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              color: AppColors.white,
              backgroundColor: AppColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad + 96),
                    sliver: _buildList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return ModulePageHeader(
      title: 'User Management',
      description: _society?.name ?? 'Every user across all societies',
      icon: Icons.manage_accounts_rounded,
      iconColor: ModuleColors.users,
      stats: [
        ModuleHeaderStat('${_stats.total}', 'TOTAL'),
        ModuleHeaderStat('${_stats.active}', 'ACTIVE'),
        ModuleHeaderStat('${_stats.pending}', 'PENDING'),
        ModuleHeaderStat('${_stats.blocked}', 'BLOCKED'),
      ],
      showSearch: true,
      searchHint: 'Search name, mobile, email or flat',
      searchController: _searchCtrl,
      onSearchChanged: _onSearchChanged,
      searchTrailing: _filterButton(),
      // Nothing below the search bar until a filter is applied.
      bottom: _activeFilterCount == 0 ? null : _buildActiveFilters(),
    );
  }

  /// Round tune icon inside the search bar; grows into a dark "⚙ 2" pill
  /// showing how many filters are applied.
  Widget _filterButton() {
    final count = _activeFilterCount;
    final active = count > 0;
    return Tooltip(
      message: 'Filters',
      child: GestureDetector(
        onTap: _openFilters,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 32,
          constraints: const BoxConstraints(minWidth: 32),
          padding: EdgeInsets.symmetric(horizontal: active ? 10 : 0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primaryDark : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 17,
                color: active ? AppColors.white : AppColors.primary,
              ),
              if (active) ...[
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// One slim row of the applied filters — tap a chip to reopen the filter
  /// sheet, or its ✕ to drop just that filter.
  Widget _buildActiveFilters() {
    return _chipRow([
      if (_society != null)
        _activeChip(
          leading: const Icon(
            Icons.location_city_outlined,
            size: 14,
            color: AppColors.primary,
          ),
          label: _society!.name,
          onRemove: _clearSociety,
        ),
      if (_status != null)
        _activeChip(
          leading: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _statusColor(_status!),
              shape: BoxShape.circle,
            ),
          ),
          label: _statusLabel(_status!),
          onRemove: () => _setStatus(null),
        ),
      if (_role != null)
        _activeChip(
          leading: const Icon(
            Icons.badge_outlined,
            size: 14,
            color: AppColors.primary,
          ),
          label: _role!.name,
          onRemove: () => _setRole(null),
        ),
      if (_activeFilterCount > 1)
        GestureDetector(
          onTap: _clearFilters,
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            child: Text(
              'Clear all',
              style: TextStyle(
                color: AppColors.accentRed,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _activeChip({
    required Widget leading,
    required String label,
    required VoidCallback onRemove,
  }) {
    return GestureDetector(
      onTap: _openFilters,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.cardBackground,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.close_rounded,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipRow(List<Widget> chips) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            chips[i],
          ],
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    final label = _isLoading
        ? 'Loading users…'
        : '$_total ${_total == 1 ? 'user' : 'users'}';
    return Row(
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
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        GestureDetector(
          onTap: _toggleSort,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              const Icon(
                Icons.swap_vert_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                _sortByName ? 'Name A–Z' : 'Newest first',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(child: NestLoader(size: 48, showDots: false)),
        ),
      );
    }
    if (_error != null) {
      return SliverToBoxAdapter(
        child: _messageBox(
          icon: Icons.error_outline,
          title: 'Could not load users',
          subtitle: _error,
          actionLabel: 'Retry',
          onAction: _reload,
        ),
      );
    }
    if (_users.isEmpty) {
      return SliverToBoxAdapter(
        child: _messageBox(
          icon: Icons.group_off_rounded,
          title: _hasFilters ? 'No users match these filters' : 'No users yet',
        ),
      );
    }

    final showFooter = _hasMore || _loadMoreError != null;
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          if (i >= _users.length) return _buildFooter();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _userTile(_users[i]),
          );
        },
        childCount: _users.length + (showFooter ? 1 : 0),
      ),
    );
  }

  Widget _buildFooter() {
    if (_loadMoreError != null) {
      return Center(
        child: TextButton.icon(
          onPressed: () {
            setState(() => _loadMoreError = null);
            _loadMore();
          },
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Could not load more — tap to retry'),
        ),
      );
    }
    // The footer is only built once it scrolls near the viewport, so reaching
    // it is what pulls the next page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadMore();
    });
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: NestLoader(size: 28, showDots: false)),
    );
  }

  Widget _userTile(ManagedUser user) {
    final place = user.isSuperAdmin
        ? 'All societies'
        : [
            if ((user.societyName ?? '').isNotEmpty) user.societyName!,
            if (user.flatLabel != null) user.flatLabel!,
          ].join(' · ');

    return GestureDetector(
      onTap: () => _openUser(user),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _avatar(user),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _pill(_statusLabel(user.status), _statusColor(user.status)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _pill(user.roleLabel, _roleColor(user.roleCode)),
                      if (place.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.mobile,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _circleAction(
              icon: Icons.chevron_right_rounded,
              color: AppColors.accentPurple,
              onTap: () => _openUser(user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageBox({
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textHint, size: 32),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    color: AppColors.white,
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
}

// ─── Filter sheet ────────────────────────────────────────────────────────────

/// Society, status and role filters in one sheet. Choices are staged here and
/// only popped (as a [_UserFilters]) on "Show results", so the list reloads
/// once rather than on every tap.
class _UserFilterSheet extends StatefulWidget {
  final _UserFilters initial;
  final List<RoleModel> roles;

  /// Status counts for [initial]'s society.
  final UserStats stats;

  const _UserFilterSheet({
    required this.initial,
    required this.roles,
    required this.stats,
  });

  @override
  State<_UserFilterSheet> createState() => _UserFilterSheetState();
}

class _UserFilterSheetState extends State<_UserFilterSheet> {
  late Society? _society = widget.initial.society;
  late RoleModel? _role = widget.initial.role;
  late String? _status = widget.initial.status;

  /// Null while counts are re-fetched for a newly picked society.
  late UserStats? _stats = widget.stats;
  int _statsRequestId = 0;

  Future<void> _pickSociety() async {
    final picked = await showSocietyPicker(context, selectedId: _society?.id);
    if (picked == null || !mounted || picked.id == _society?.id) return;
    _setSociety(picked);
  }

  /// Status counts are per society, so re-count when the society changes.
  Future<void> _setSociety(Society? society) async {
    final requestId = ++_statsRequestId;
    final isInitial = society?.id == widget.initial.society?.id;
    setState(() {
      _society = society;
      _stats = isInitial ? widget.stats : null;
    });
    if (isInitial) return;
    try {
      final stats = await UserManagementService().getStats(
        societyId: society == null ? null : int.tryParse(society.id),
      );
      if (mounted && requestId == _statsRequestId) {
        setState(() => _stats = stats);
      }
    } catch (_) {
      // Counts are a hint — the chips still work without them.
    }
  }

  void _reset() {
    if (_society != null) _setSociety(null);
    setState(() {
      _status = null;
      _role = null;
    });
  }

  void _apply() => Navigator.pop<_UserFilters>(context, (
    society: _society,
    role: _role,
    status: _status,
  ));

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return AppFormSheet(
      accentColor: ModuleColors.users,
      icon: Icons.tune_rounded,
      title: 'Filter users',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppPickerCard(
                  icon: Icons.location_city_outlined,
                  label: 'Society',
                  value: _society?.name,
                  hint: 'All societies',
                  onTap: _pickSociety,
                ),
              ),
              if (_society != null) ...[
                const SizedBox(width: 10),
                Tooltip(
                  message: 'Show all societies',
                  child: _circleAction(
                    icon: Icons.close_rounded,
                    color: AppColors.accentRed,
                    onTap: () => _setSociety(null),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 22),
          _sectionLabel('Status'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _filterChip(
                'All',
                _status == null,
                () => setState(() => _status = null),
              ),
              for (final (value, label) in _statusOptions)
                _filterChip(
                  stats == null ? label : '$label · ${stats.countFor(value)}',
                  _status == value,
                  () => setState(() => _status = value),
                ),
            ],
          ),
          if (widget.roles.isNotEmpty) ...[
            const SizedBox(height: 22),
            _sectionLabel('Role'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip(
                  'All roles',
                  _role == null,
                  () => setState(() => _role = null),
                ),
                for (final role in widget.roles)
                  _filterChip(
                    role.name,
                    _role?.id == role.id,
                    () => setState(() => _role = role),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: _reset,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppButton(
                  text: 'Show results',
                  color: AppColors.primary,
                  height: 50,
                  onPressed: _apply,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Same small caps as the label inside [AppPickerCard].
  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }
}

// ─── User detail sheet ───────────────────────────────────────────────────────

/// A user's full record with the actions that apply to them. Pops the chosen
/// action together with the freshest copy of the user (the single-user
/// endpoint also carries a secretary's assigned buildings).
class _UserDetailSheet extends StatefulWidget {
  final ManagedUser user;
  final bool isSelf;

  const _UserDetailSheet({required this.user, required this.isSelf});

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  late ManagedUser _user = widget.user;
  bool _isLoadingDetail = true;
  bool _detailLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final full = await UserManagementService().getUser(widget.user.id);
      if (!mounted) return;
      setState(() {
        _user = full;
        _detailLoaded = true;
        _isLoadingDetail = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingDetail = false);
    }
  }

  void _pick(_UserAction action) => Navigator.pop(context, (action, _user));

  @override
  Widget build(BuildContext context) {
    final u = _user;
    final canChangeStatus = !widget.isSelf;
    final buildings = _isLoadingDetail
        ? 'Loading…'
        : !_detailLoaded
        ? 'Could not load'
        : u.assignedBuildings.isEmpty
        ? 'None assigned'
        : u.assignedBuildings.map((b) => b.name).join(', ');

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _avatar(u),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.fullName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _pill(u.roleLabel, _roleColor(u.roleCode)),
                            _pill(_statusLabel(u.status), _statusColor(u.status)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _detailRow(Icons.phone_outlined, 'Mobile', u.mobile),
              if (u.email != null)
                _detailRow(Icons.email_outlined, 'Email', u.email!),
              _detailRow(
                Icons.location_city_outlined,
                'Society',
                u.isSuperAdmin
                    ? 'All societies (platform)'
                    : (u.societyName ?? 'Not linked'),
              ),
              if (u.flatLabel != null)
                _detailRow(
                  Icons.door_front_door_outlined,
                  'Flat',
                  [
                    u.flatLabel!,
                    if (u.buildingName != null) u.buildingName!,
                    if (u.relationType != null) _relationLabel(u.relationType!),
                  ].join(' · '),
                ),
              if (u.isSocietyAdmin)
                _detailRow(Icons.domain_outlined, 'Buildings', buildings),
              if (u.createdAt != null)
                _detailRow(
                  Icons.event_outlined,
                  'Joined',
                  DateFormat('d MMM yyyy').format(u.createdAt!.toLocal()),
                ),
              const SizedBox(height: 8),
              if (widget.isSelf)
                _note(
                  "This is your account — its role and status can't be changed here.",
                ),
              if (canChangeStatus && u.status == 'pending') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        'Approve',
                        Icons.check_rounded,
                        AppColors.accentGreen,
                        () => _pick(_UserAction.approve),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionButton(
                        'Reject',
                        Icons.close_rounded,
                        AppColors.accentRed,
                        () => _pick(_UserAction.reject),
                      ),
                    ),
                  ],
                ),
              ],
              _actionRow(
                Icons.edit_outlined,
                'Edit details',
                'Name, mobile, role, society or flat',
                AppColors.accentBlue,
                () => _pick(_UserAction.edit),
              ),
              if (u.isSocietyAdmin)
                _actionRow(
                  Icons.domain_add_outlined,
                  'Assign buildings',
                  'Choose the buildings this secretary manages',
                  AppColors.accentIndigo,
                  _detailLoaded ? () => _pick(_UserAction.assignBuildings) : null,
                ),
              _actionRow(
                Icons.phone_rounded,
                'Call',
                u.mobile,
                AppColors.accentGreen,
                () => _pick(_UserAction.call),
              ),
              if (canChangeStatus && u.status == 'active')
                _actionRow(
                  Icons.block_rounded,
                  'Block user',
                  'Stop them from using the app',
                  AppColors.accentRed,
                  () => _pick(_UserAction.block),
                ),
              if (canChangeStatus && u.status == 'blocked')
                _actionRow(
                  Icons.lock_open_rounded,
                  'Unblock user',
                  'Let them sign in again',
                  AppColors.accentGreen,
                  () => _pick(_UserAction.unblock),
                ),
              if (canChangeStatus && u.status == 'rejected')
                _actionRow(
                  Icons.how_to_reg_rounded,
                  'Approve instead',
                  'Activate this account',
                  AppColors.accentGreen,
                  () => _pick(_UserAction.approve),
                ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textHint, size: 18),
          const SizedBox(width: 12),
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _note(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentIndigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentIndigo.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.accentIndigo,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.accentIndigo,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 46,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionRow(
    IconData icon,
    String label,
    String subtitle,
    Color color,
    VoidCallback? onTap,
  ) => AppSheetAction(
    icon: icon,
    label: label,
    subtitle: subtitle,
    color: color,
    onTap: onTap,
  );
}

// ─── Shared bits ─────────────────────────────────────────────────────────────

String _errorText(Object e) => e.toString().replaceFirst('Exception: ', '');

String _statusLabel(String status) {
  switch (status) {
    case 'active':
      return 'Active';
    case 'pending':
      return 'Pending';
    case 'blocked':
      return 'Blocked';
    case 'rejected':
      return 'Rejected';
    default:
      return status;
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'active':
      return AppColors.accentGreen;
    case 'pending':
      return AppColors.accentAmber;
    case 'blocked':
      return AppColors.accentRed;
    default:
      return AppColors.textMuted;
  }
}

// Same role colours as the Roles & Permissions screen.
Color _roleColor(String code) {
  switch (code) {
    case 'SUPER_ADMIN':
      return AppColors.accentRed;
    case 'SOCIETY_ADMIN':
      return AppColors.accentIndigo;
    case 'MEMBER':
      return AppColors.accentGreen;
    case 'SECURITY_GUARD':
      return AppColors.accentOrange;
    default:
      return AppColors.accentPurple;
  }
}

String _relationLabel(String relation) {
  switch (relation.toUpperCase()) {
    case 'OWNER':
      return 'Owner';
    case 'TENANT':
      return 'Tenant';
    case 'FAMILY':
      return 'Family';
    default:
      return relation;
  }
}

Widget _pill(String label, Color color) {
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 150),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    ),
  );
}

Widget _avatar(ManagedUser user) {
  final dimmed = user.status == 'blocked' || user.status == 'rejected';
  final colors = dimmed
      ? const [AppColors.grey, AppColors.textSecondary]
      : const [AppColors.primary, AppColors.primaryDark];
  return Container(
    width: 46,
    height: 46,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: colors.first.withValues(alpha: 0.25),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    alignment: Alignment.center,
    child: Text(
      user.initials,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

// Same chip as the Complaints / Notices filters.
Widget _filterChip(String label, bool selected, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
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
      child: Icon(icon, color: color, size: 18),
    ),
  );
}
