import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/modules.dart';
import '../../models/notice_complaint.dart';
import '../../services/notice_complaint_service.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/nest_loader.dart';
import '../../widgets/module_page_header.dart';
import '../secretary/notice_create_screen.dart';
import 'notice_detail_screen.dart';

class NoticeListScreen extends StatefulWidget {
  const NoticeListScreen({super.key});

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  final NoticeService _noticeService = NoticeService();
  final TextEditingController _searchController = TextEditingController();

  List<Notice> _notices = [];
  bool _isLoading = true;
  String? _error;

  String _query = '';
  String _rangeFilter = 'ALL'; // ALL / TODAY / WEEK / MONTH

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final notices = await _noticeService.getNotices();
      if (mounted) {
        setState(() {
          _notices = notices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // ─── Filtering ──────────────────────────────────────────────────────────────

  bool _inRange(Notice n) {
    if (_rangeFilter == 'ALL') return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
    switch (_rangeFilter) {
      case 'TODAY':
        return day == today;
      case 'WEEK':
        return day.isAfter(today.subtract(const Duration(days: 7)));
      case 'MONTH':
        return day.isAfter(today.subtract(const Duration(days: 30)));
      default:
        return true;
    }
  }

  List<Notice> get _filtered {
    final q = _query.trim().toLowerCase();
    return _notices.where((n) {
      final matchesQuery =
          q.isEmpty ||
          n.title.toLowerCase().contains(q) ||
          n.description.toLowerCase().contains(q) ||
          (n.createdBy ?? '').toLowerCase().contains(q);
      return _inRange(n) && matchesQuery;
    }).toList();
  }

  bool _isNew(Notice n) =>
      DateTime.now().difference(n.createdAt) < const Duration(hours: 48);

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canManage = PermissionService().canManage(ModuleCodes.notices);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: AppColors.white,
        backgroundColor: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: NestLoader(),
              )
            else if (_error != null)
              SliverFillRemaining(hasScrollBody: false, child: _buildError())
            else ...[
              SliverToBoxAdapter(child: _buildSearchAndFilters()),
              if (_filtered.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
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
          ],
        ),
      ),
      // Publishing a notice is a manage-only action — the list itself is
      // shared with view-only roles.
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NoticeCreateScreen()),
              ).then((_) => _fetch()),
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final total = _notices.length;
    final thisWeek = _notices.where((n) => n.createdAt.isAfter(weekAgo)).length;
    final withFiles = _notices
        .where((n) => n.attachmentUrl != null && n.attachmentUrl!.isNotEmpty)
        .length;

    return ModulePageHeader(
      title: 'Notices',
      description: 'Announcements & circulars',
      icon: Icons.campaign_outlined,
      iconColor: ModuleColors.notices,
      stats: [
        ModuleHeaderStat('$total', 'TOTAL'),
        ModuleHeaderStat('$thisWeek', 'THIS WEEK'),
        ModuleHeaderStat('$withFiles', 'WITH FILES'),
      ],
    );
  }

  // ─── Search + filter chips ──────────────────────────────────────────────────

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: AppColors.textHint,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Search notices...',
                      hintStyle: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 13.5,
                      ),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 13),
                    ),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textHint,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', 'ALL'),
                const SizedBox(width: 8),
                _filterChip('Today', 'TODAY'),
                const SizedBox(width: 8),
                _filterChip('This Week', 'WEEK'),
                const SizedBox(width: 8),
                _filterChip('This Month', 'MONTH'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _rangeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _rangeFilter = value),
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

  // ─── Notice card ────────────────────────────────────────────────────────────

  Widget _buildCard(Notice notice) {
    final hasAttachment =
        notice.attachmentUrl != null && notice.attachmentUrl!.isNotEmpty;
    final isNew = _isNew(notice);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NoticeDetailScreen(notice: notice)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNew
                ? AppColors.accentIndigo.withValues(alpha: 0.35)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar date tile
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentIndigo.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('d').format(notice.createdAt),
                    style: const TextStyle(
                      color: AppColors.accentIndigo,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(notice.createdAt).toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.accentIndigo,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notice.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isNew) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: AppColors.accentGreen,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (notice.description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      notice.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (notice.createdBy != null &&
                          notice.createdBy!.isNotEmpty) ...[
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            notice.createdBy!,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else ...[
                        Text(
                          DateFormat('hh:mm a').format(notice.createdAt),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (hasAttachment)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.attach_file_rounded,
                                size: 11,
                                color: AppColors.accentBlue,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'File',
                                style: TextStyle(
                                  color: AppColors.accentBlue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.accentRed,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _fetch,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, color: AppColors.border, size: 56),
          SizedBox(height: 12),
          Text(
            'No notices found',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Pull down to refresh',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
