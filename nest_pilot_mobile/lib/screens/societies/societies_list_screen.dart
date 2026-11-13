import 'dart:async';

import 'package:flutter/material.dart';
import '../../theme/nest_loader.dart';
import '../../theme/app_colors.dart';
import '../../services/society_service.dart';
import '../../models/society_structure.dart';
import '../../widgets/app_field_card.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/app_sheet_action.dart';
import '../../widgets/society_picker_sheet.dart'
    show societyTypeColor, societyTypeIcon;
import '../buildings/buildings_list_screen.dart';
import '../users/user_management_screen.dart';
import 'society_create_screen.dart';

/// Super Admin's society directory. Search, the status filter and paging run
/// on the server so it stays quick with hundreds of societies; each card
/// carries its headline counts and opens that society's users, buildings and
/// settings.
class SocietiesListScreen extends StatefulWidget {
  const SocietiesListScreen({super.key});

  @override
  State<SocietiesListScreen> createState() => _SocietiesListScreenState();
}

class _SocietiesListScreenState extends State<SocietiesListScreen> {
  final SocietyService _societyService = SocietyService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  final List<SocietyOverview> _societies = [];
  int _total = 0;
  int _page = 0;
  bool _hasMore = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _loadMoreError;
  String _searchQuery = '';
  String? _statusFilter; // null = all, 'active' or 'inactive'
  int _allCount = 0;
  int _activeCount = 0;
  int _inactiveCount = 0;

  // Bumped by every reload so responses for a stale search are dropped.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _loadSocieties();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Reloads page 1 for the current search and status filter.
  Future<void> _loadSocieties() async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _loadMoreError = null;
    });
    try {
      final result = await _societyService.getSocietyDirectory(
        page: 1,
        search: _searchQuery,
        status: _statusFilter,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _societies
          ..clear()
          ..addAll(result.items);
        _applyTotals(result);
        _page = 1;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load societies: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore || _loadMoreError != null) {
      return;
    }
    final requestId = _requestId;
    setState(() => _isLoadingMore = true);
    try {
      final result = await _societyService.getSocietyDirectory(
        page: _page + 1,
        search: _searchQuery,
        status: _statusFilter,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _societies.addAll(result.items);
        _applyTotals(result);
        _page += 1;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loadMoreError = e.toString();
        _isLoadingMore = false;
      });
    }
  }

  void _applyTotals(SocietyDirectoryPage result) {
    _total = result.total;
    _hasMore = result.hasMore;
    _allCount = result.allCount;
    _activeCount = result.activeCount;
    _inactiveCount = result.inactiveCount;
  }

  void _onSearchChanged() {
    setState(() {}); // AppSearchField derives its clear button from the text
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final q = _searchController.text.trim();
      if (q == _searchQuery) return;
      _searchQuery = q;
      _loadSocieties();
    });
  }

  void _setStatusFilter(String? status) {
    if (status == _statusFilter) return;
    _statusFilter = status;
    _loadSocieties();
  }

  String _count(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';

  // ─── Navigation / actions ───────────────────────────────────────────────────

  Future<void> _openEditPage(Society society) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SocietyCreateScreen(society: society),
      ),
    );
    if (saved == true) _loadSocieties();
  }

  Future<void> _openCreatePage() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SocietyCreateScreen()),
    );
    if (saved == true) _loadSocieties();
  }

  Future<void> _openUsers(Society society, {String? status}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            UserManagementScreen(society: society, initialStatus: status),
      ),
    );
    // Approvals and edits there change this society's counts.
    if (mounted) _loadSocieties();
  }

  void _openBuildings(Society society) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BuildingsListScreen(society: society)),
    );
  }

  Future<void> _toggleStatus(SocietyOverview overview) async {
    final society = overview.society;
    final deactivate = !overview.isInactive;
    if (deactivate) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Mark Inactive',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Move "${society.name}" to the inactive list? Nothing is deleted '
            'and its residents can still sign in. You can reactivate it any time.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentRed,
              ),
              child: const Text(
                'Mark Inactive',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      final done = await _societyService.setSocietyStatus(
        society.id,
        deactivate ? 'inactive' : 'active',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !done
                ? 'Failed to update society'
                : deactivate
                ? '${society.name} marked inactive'
                : '${society.name} reactivated',
          ),
        ),
      );
      if (done) _loadSocieties();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _showSocietyActions(SocietyOverview overview) {
    final society = overview.society;
    final color = overview.isInactive
        ? AppColors.grey
        : societyTypeColor(society.societyType);
    final location = [
      society.address,
      if ((society.city ?? '').isNotEmpty) society.city!,
      if ((society.pincode ?? '').isNotEmpty) society.pincode!,
    ].where((s) => s.isNotEmpty).join(', ');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        void run(VoidCallback action) {
          Navigator.pop(ctx);
          action();
        }

        return SafeArea(
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
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        societyTypeIcon(society.societyType),
                        color: color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            society.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (location.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              location,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _statBox('${overview.buildings}', 'Buildings'),
                    const SizedBox(width: 8),
                    _statBox('${overview.flats}', 'Flats'),
                    const SizedBox(width: 8),
                    _statBox('${overview.activeUsers}', 'Users'),
                    const SizedBox(width: 8),
                    _statBox('${overview.admins}', 'Secretaries'),
                  ],
                ),
                const SizedBox(height: 6),
                AppSheetAction(
                  icon: Icons.manage_accounts_rounded,
                  label: 'Manage users',
                  subtitle: 'Everyone in this society',
                  color: ModuleColors.users,
                  onTap: () => run(() => _openUsers(society)),
                ),
                if (overview.pendingUsers > 0)
                  AppSheetAction(
                    icon: Icons.how_to_reg_rounded,
                    label: 'Pending approvals',
                    subtitle: '${overview.pendingUsers} waiting for approval',
                    color: AppColors.accentAmber,
                    onTap: () =>
                        run(() => _openUsers(society, status: 'pending')),
                  ),
                AppSheetAction(
                  icon: Icons.domain_outlined,
                  label: 'Buildings',
                  subtitle: 'Browse and edit its buildings',
                  color: ModuleColors.buildings,
                  onTap: () => run(() => _openBuildings(society)),
                ),
                AppSheetAction(
                  icon: Icons.edit_outlined,
                  label: 'Edit details',
                  subtitle: 'Name, type and address',
                  color: AppColors.accentBlue,
                  onTap: () => run(() => _openEditPage(society)),
                ),
                if (overview.isInactive)
                  AppSheetAction(
                    icon: Icons.restart_alt_rounded,
                    label: 'Reactivate',
                    subtitle: 'Move it back to the active list',
                    color: AppColors.accentGreen,
                    onTap: () => run(() => _toggleStatus(overview)),
                  )
                else
                  AppSheetAction(
                    icon: Icons.archive_outlined,
                    label: 'Mark inactive',
                    subtitle: 'Keeps all data — residents can still sign in',
                    color: AppColors.accentRed,
                    onTap: () => run(() => _toggleStatus(overview)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePage,
        backgroundColor: AppColors.primary,
        icon: const Icon(
          Icons.add_business_rounded,
          color: AppColors.white,
          size: 20,
        ),
        label: const Text(
          'Add Society',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
      body: Column(
        children: [
          const AppPageHeader(
            icon: Icons.domain_rounded,
            title: 'All Societies',
            accentColor: ModuleColors.buildings,
            subtitle: 'Browse and manage onboarded societies',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  AppSearchField(
                    controller: _searchController,
                    hint: 'Search by name, city, type or pincode',
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('All · $_allCount', null),
                        const SizedBox(width: 8),
                        _filterChip('Active · $_activeCount', 'active'),
                        const SizedBox(width: 8),
                        _filterChip('Inactive · $_inactiveCount', 'inactive'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isLoading
                        ? 'Searching…'
                        : 'Found $_total ${_total == 1 ? 'society' : 'societies'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _buildList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) return const Center(child: NestLoader());
    if (_societies.isEmpty) {
      return AppListEmpty(
        icon: Icons.business_outlined,
        message: _searchQuery.isNotEmpty
            ? 'No search matches'
            : _statusFilter == 'inactive'
            ? 'No inactive societies'
            : 'No societies created yet',
      );
    }

    final showFooter = _hasMore || _loadMoreError != null;
    return RefreshIndicator(
      onRefresh: _loadSocieties,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: _societies.length + (showFooter ? 1 : 0),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemBuilder: (context, index) {
          if (index >= _societies.length) return _buildFooter();
          final overview = _societies[index];
          final society = overview.society;
          final Color typeColor = overview.isInactive
              ? AppColors.grey
              : societyTypeColor(society.societyType);

          return AppListCard(
            accentColor: typeColor,
            icon: societyTypeIcon(society.societyType),
            title: society.name,
            badgeText: overview.isInactive ? 'INACTIVE' : society.societyType,
            subtitleChips: [
              [
                society.address,
                if ((society.city ?? '').isNotEmpty) society.city!,
              ].join(', '),
              _count(overview.buildings, 'building'),
              _count(overview.flats, 'flat'),
              _count(overview.activeUsers, 'user'),
              if (overview.pendingUsers > 0)
                '${overview.pendingUsers} pending',
            ],
            trailing: IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: AppColors.textSecondary,
              ),
              tooltip: 'Edit society',
              onPressed: () => _openEditPage(society),
            ),
            onTap: () => _showSocietyActions(overview),
          );
        },
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
    // Only built once it scrolls near the viewport — reaching it pulls the
    // next page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadMore();
    });
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: NestLoader(size: 28, showDots: false)),
    );
  }

  // Same chip as the Complaints / Notices filters.
  Widget _filterChip(String label, String? value) {
    final selected = _statusFilter == value;
    return GestureDetector(
      onTap: () => _setStatusFilter(value),
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

  Widget _statBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
