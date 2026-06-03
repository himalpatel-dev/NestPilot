import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notice_complaint.dart';
import '../../services/notice_complaint_service.dart';
import '../../theme/app_colors.dart';
import '../member/complaint_detail_screen.dart';

class ComplaintManageScreen extends StatefulWidget {
  const ComplaintManageScreen({super.key});

  @override
  State<ComplaintManageScreen> createState() => _ComplaintManageScreenState();
}

class _ComplaintManageScreenState extends State<ComplaintManageScreen> {
  final ComplaintService _service = ComplaintService();
  List<Complaint> _all = [];
  String _filter = 'ALL';
  bool _isLoading = true;

  static const _statuses = ['ALL', 'OPEN', 'IN_PROGRESS', 'RESOLVED', 'REJECTED'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final list = await _service.getComplaints();
      if (mounted) setState(() => _all = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Complaint> get _filtered => _filter == 'ALL'
      ? _all
      : _all.where((c) => c.status == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Complaints',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          // ── Filter chips ────────────────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _statuses.length,
              separatorBuilder: (_, i) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = _statuses[i];
                final selected = _filter == s;
                return GestureDetector(
                  onTap: () => setState(() => _filter = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      s == 'IN_PROGRESS' ? 'In Progress' : _cap(s),
                      style: TextStyle(
                        color: selected ? AppColors.white : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // ── List ────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.white,
                        backgroundColor: AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, i) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _ComplaintTile(
                            complaint: _filtered[i],
                            onTap: () => _openDetail(_filtered[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _openDetail(Complaint c) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaint: c)),
    ).then((_) => _load());
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.report_problem_outlined,
                size: 52, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              _filter == 'ALL'
                  ? 'No complaints yet'
                  : 'No ${_cap(_filter).toLowerCase()} complaints',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );

  String _cap(String s) =>
      s.isEmpty ? s : '${s[0]}${s.substring(1).toLowerCase()}';
}

// ── Complaint tile ───────────────────────────────────────────────────────────

class _ComplaintTile extends StatelessWidget {
  final Complaint complaint;
  final VoidCallback onTap;
  const _ComplaintTile({required this.complaint, required this.onTap});

  Color get _statusColor {
    switch (complaint.status) {
      case 'OPEN':        return AppColors.accentRed;
      case 'IN_PROGRESS': return AppColors.accentAmber;
      case 'RESOLVED':    return AppColors.accentGreen;
      case 'REJECTED':    return AppColors.textSecondary;
      default:            return AppColors.primary;
    }
  }

  String get _statusLabel {
    switch (complaint.status) {
      case 'IN_PROGRESS': return 'In Progress';
      default:
        final s = complaint.status;
        return s.isEmpty ? s : '${s[0]}${s.substring(1).toLowerCase()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM, h:mm a').format(complaint.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.report_problem_outlined,
                  color: _statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          complaint.category,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _statusLabel,
                          style: TextStyle(
                            color: _statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    complaint.description,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dateStr,
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}
