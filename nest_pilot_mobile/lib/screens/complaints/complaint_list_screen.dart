import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_config.dart';
import '../../config/modules.dart';
import '../../models/notice_complaint.dart';
import '../../services/notice_complaint_service.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/nest_loader.dart';
import '../../widgets/module_page_header.dart';
import '../../widgets/status_widgets.dart';
import '../../widgets/app_form_sheet.dart';
import 'complaint_detail_screen.dart';
import 'complaint_form_sheet.dart';

class ComplaintListScreen extends StatefulWidget {
  const ComplaintListScreen({super.key});

  @override
  State<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends State<ComplaintListScreen> {
  final ComplaintService _complaintService = ComplaintService();
  final TextEditingController _searchController = TextEditingController();

  List<Complaint> _complaints = [];
  bool _isLoading = true;
  String? _error;

  String _query = '';
  String _statusFilter = 'ALL'; // ALL / OPEN / IN_PROGRESS / RESOLVED

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateSheet() {
    showAppFormSheet(
      context: context,
      builder: (ctx) => ComplaintFormSheet(
        onSaved: (_) {
          Navigator.pop(ctx);
          _fetchComplaints();
        },
      ),
    );
  }

  /// Opens the same sheet prefilled for an edit. Category, description and the
  /// photo are all the API accepts — status is changed from the detail page.
  void _openEditSheet(Complaint complaint) {
    showAppFormSheet(
      context: context,
      builder: (ctx) => ComplaintFormSheet(
        complaint: complaint,
        onSaved: (_) {
          Navigator.pop(ctx);
          _fetchComplaints();
        },
      ),
    );
  }

  Future<void> _fetchComplaints() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final complaints = await _complaintService.getComplaints();
      setState(() {
        _complaints = complaints;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Complaint> get _filtered {
    final q = _query.trim().toLowerCase();
    return _complaints.where((c) {
      final matchesStatus = _statusFilter == 'ALL' || c.status == _statusFilter;
      final matchesQuery =
          q.isEmpty ||
          c.description.toLowerCase().contains(q) ||
          c.category.toLowerCase().contains(q);
      return matchesStatus && matchesQuery;
    }).toList();
  }

  // ─── Status / category helpers ──────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'RESOLVED':
        return AppColors.accentGreen;
      case 'IN_PROGRESS':
        return AppColors.accentAmber;
      case 'REJECTED':
        return AppColors.accentRed;
      default: // OPEN
        return AppColors.accentBlue;
    }
  }

  String _statusLabel(String status) => status.replaceAll('_', ' ');

  /// A settled complaint is read-only — the same pair the detail page locks
  /// its comment thread on.
  bool _isClosed(String status) => status == 'RESOLVED' || status == 'REJECTED';

  /// How many tracker steps (RAISED → IN PROGRESS → RESOLVED) are completed
  /// for a given status.
  int _stepsDone(String status) {
    switch (status) {
      case 'RESOLVED':
        return 3;
      case 'IN_PROGRESS':
        return 2;
      default: // OPEN / REJECTED
        return 1;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'PLUMBING':
        return Icons.water_drop_outlined;
      case 'ELECTRICAL':
        return Icons.bolt_outlined;
      case 'CARPENTRY':
        return Icons.handyman_outlined;
      case 'CLEANING':
        return Icons.cleaning_services_outlined;
      case 'SECURITY':
        return Icons.shield_outlined;
      case 'LIFT':
        return Icons.elevator_outlined;
      default:
        return Icons.report_problem_outlined;
    }
  }

  Color _categoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'PLUMBING':
        return AppColors.accentBlue;
      case 'ELECTRICAL':
        return AppColors.accentAmber;
      case 'CARPENTRY':
        return AppColors.accentBrown;
      case 'CLEANING':
        return AppColors.accentTeal;
      case 'SECURITY':
        return AppColors.accentIndigo;
      default:
        return AppColors.accentRed;
    }
  }

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final time = DateFormat('HH:mm').format(d);
    if (day == today) return 'Today · $time';
    if (day == today.subtract(const Duration(days: 1))) {
      return 'Yesterday · $time';
    }
    return '${DateFormat('d MMM').format(d)} · $time';
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canManage = PermissionService().canManage(ModuleCodes.complaints);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      // Header and filter chips stay pinned; only the complaint cards scroll.
      body: Column(
        children: [
          _buildHeader(),
          if (!_isLoading && _error == null) _buildSearchAndFilters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchComplaints,
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
                        onRetry: _fetchComplaints,
                      ),
                    )
                  else if (_filtered.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyWidget(
                        message: 'No complaints found',
                        icon: Icons.report_problem_outlined,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad + 90),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _buildCard(_filtered[i], canManage),
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
      // Add is a manage-only action — the list itself is shared with
      // view-only roles.
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: _openCreateSheet,
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final open = _complaints.where((c) => c.status == 'OPEN').length;
    final inProgress = _complaints
        .where((c) => c.status == 'IN_PROGRESS')
        .length;
    final resolved = _complaints.where((c) => c.status == 'RESOLVED').length;

    return ModulePageHeader(
      title: 'Complaints',
      description: 'Raise & track maintenance issues',
      icon: Icons.report_problem_outlined,
      iconColor: ModuleColors.complaints,
      stats: [
        ModuleHeaderStat('$open', 'OPEN'),
        ModuleHeaderStat('$inProgress', 'IN PROGRESS'),
        ModuleHeaderStat('$resolved', 'RESOLVED'),
      ],
      showSearch: true,
      searchHint: 'Search complaints...',
      searchController: _searchController,
      onSearchChanged: (v) => setState(() => _query = v),
    );
  }

  // ─── Filter chips ───────────────────────────────────────────────────────────

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', 'ALL'),
                const SizedBox(width: 8),
                _filterChip('Open', 'OPEN'),
                const SizedBox(width: 8),
                _filterChip('In Progress', 'IN_PROGRESS'),
                const SizedBox(width: 8),
                _filterChip('Resolved', 'RESOLVED'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
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

  // ─── Complaint card ─────────────────────────────────────────────────────────

  Widget _buildCard(Complaint complaint, bool canManage) {
    final statusColor = _statusColor(complaint.status);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ComplaintDetailScreen(complaint: complaint),
        ),
      ).then((_) => _fetchComplaints()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _thumbnail(complaint),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              complaint.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
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
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _statusLabel(complaint.status),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          // Edit is manage-only, the same gate the API puts on
                          // PUT /complaints/:id. Once a complaint is settled
                          // its details are no longer editable.
                          if (canManage && !_isClosed(complaint.status)) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _openEditSheet(complaint),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: ModuleColors.complaints.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.edit_outlined,
                                  size: 14,
                                  color: ModuleColors.complaints,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${complaint.category} · ${_dateLabel(complaint.createdAt)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                      if (complaint.imagePath != null &&
                          complaint.imagePath!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attachment_rounded,
                              size: 13,
                              color: AppColors.accentIndigo,
                            ),
                            SizedBox(width: 3),
                            Text(
                              '1 photo',
                              style: TextStyle(
                                color: AppColors.accentIndigo,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _progressTracker(complaint.status),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail(Complaint complaint) {
    final color = _categoryColor(complaint.category);
    final icon = _categoryIcon(complaint.category);

    if (complaint.imagePath != null && complaint.imagePath!.isNotEmpty) {
      final url = complaint.imagePath!.startsWith('http')
          ? complaint.imagePath!
          : '${AppConfig.baseUrl}${complaint.imagePath!}';
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _iconThumb(color, icon),
        ),
      );
    }
    return _iconThumb(color, icon);
  }

  Widget _iconThumb(Color color, IconData icon) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 24),
    );
  }

  // ─── Progress tracker: RAISED → IN PROGRESS → RESOLVED ────────────────────

  Widget _progressTracker(String status) {
    const steps = ['RAISED', 'IN PROGRESS', 'RESOLVED'];
    final done = _stepsDone(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 7, left: 3, right: 3),
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: i < done ? AppColors.success : AppColors.border,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            Column(
              children: [
                Icon(
                  i < done
                      ? Icons.check_circle_outline_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: i < done ? AppColors.success : AppColors.textHint,
                ),
                const SizedBox(height: 4),
                Text(
                  steps[i],
                  style: TextStyle(
                    color: i < done ? AppColors.success : AppColors.textHint,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
