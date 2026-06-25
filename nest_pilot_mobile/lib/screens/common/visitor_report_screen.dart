import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/nest_loader.dart';
import '../../services/community_service.dart';
import '../../widgets/app_page_header.dart';

class VisitorReportScreen extends StatefulWidget {
  const VisitorReportScreen({super.key});

  @override
  State<VisitorReportScreen> createState() => _VisitorReportScreenState();
}

class _VisitorReportScreenState extends State<VisitorReportScreen> {
  final CommunityService _service = CommunityService();
  List<dynamic> _allVisitors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getAllSocietyVisitors();
      if (mounted) setState(() { _allVisitors = data; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'INSIDE':           return AppColors.accentGreen;
      case 'WAITING_APPROVAL': return AppColors.accentAmber;
      case 'DENIED':           return AppColors.accentRed;
      case 'PRE_APPROVED':     return AppColors.accentBlue;
      case 'EXITED':
      default:                 return AppColors.textMuted;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'INSIDE':           return 'Inside';
      case 'WAITING_APPROVAL': return 'Waiting';
      case 'DENIED':           return 'Denied';
      case 'PRE_APPROVED':     return 'Pre-Approved';
      case 'EXITED':           return 'Exited';
      default:                 return status.replaceAll('_', ' ');
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'INSIDE':           return Icons.login_rounded;
      case 'WAITING_APPROVAL': return Icons.hourglass_empty_rounded;
      case 'DENIED':           return Icons.block_rounded;
      case 'PRE_APPROVED':     return Icons.check_circle_outline_rounded;
      case 'EXITED':           return Icons.logout_rounded;
      default:                 return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: RefreshIndicator(
        onRefresh: _fetchReport,
        color: AppColors.white,
        backgroundColor: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AppPageHeader(
                icon: const Icon(
                  Icons.assignment_outlined,
                  color: AppColors.white,
                  size: 28,
                ),
                title: 'Visitor Logs',
                subtitle: _isLoading
                    ? 'Loading records…'
                    : '${_allVisitors.length} total visitor record${_allVisitors.length == 1 ? '' : 's'}',
                trailing: GestureDetector(
                  onTap: _fetchReport,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(child: NestLoader())
            else if (_allVisitors.isEmpty)
              SliverFillRemaining(child: _buildEmpty())
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad + 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildCard(_allVisitors[i]),
                    childCount: _allVisitors.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(dynamic log) {
    final visitor = log['Visitor'] as Map<String, dynamic>? ?? {};
    final house = log['House'] as Map<String, dynamic>?;
    final approver = log['approver'] as Map<String, dynamic>?;

    final name = visitor['name'] as String? ?? 'Unknown';
    final mobile = visitor['mobile'] as String? ?? '—';
    final visitorType = visitor['type'] as String?;
    final houseNo = house?['house_no'] as String? ?? '—';
    final status = log['status'] as String? ?? '';
    final purpose = log['purpose'] as String?;
    final vehicle = log['vehicle_number'] as String?;
    final approverName = approver?['full_name'] as String?;

    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'V';
    final color = _statusColor(status);

    String entryTime = 'Not recorded';
    String exitTime = '—';
    try {
      if (log['entry_time'] != null) {
        entryTime = DateFormat('dd MMM · hh:mm a').format(DateTime.parse(log['entry_time'] as String));
      }
    } catch (_) {}
    try {
      if (log['exit_time'] != null) {
        exitTime = DateFormat('dd MMM · hh:mm a').format(DateTime.parse(log['exit_time'] as String));
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: AppColors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.30)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(status), size: 10, color: color),
                    const SizedBox(width: 4),
                    Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.home_rounded, size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Flat $houseNo',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (visitorType != null && visitorType.isNotEmpty) ...[
                      const Text(
                        '  ·  ',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      Text(
                        visitorType,
                        style: const TextStyle(
                          color: AppColors.accentAmber,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entryTime,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          children: [
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                children: [
                  _detailRow(Icons.phone_outlined, 'Mobile', mobile, AppColors.accentBlue),
                  if (purpose != null && purpose.isNotEmpty)
                    _detailRow(Icons.notes_rounded, 'Purpose', purpose, AppColors.accentPurple),
                  _detailRow(Icons.login_rounded, 'Entry', entryTime, AppColors.accentGreen),
                  if (log['exit_time'] != null)
                    _detailRow(Icons.logout_rounded, 'Exit', exitTime, AppColors.accentRed),
                  if (approverName != null)
                    _detailRow(Icons.verified_user_outlined, 'Approved By', approverName, AppColors.accentIndigo),
                  if (vehicle != null && vehicle.isNotEmpty)
                    _detailRow(Icons.directions_car_outlined, 'Vehicle', vehicle, AppColors.textSecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, color: AppColors.border, size: 56),
          SizedBox(height: 12),
          Text(
            'No visitor records found',
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
