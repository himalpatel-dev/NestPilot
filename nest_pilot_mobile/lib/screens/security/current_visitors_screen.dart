import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/community_service.dart';
import '../../services/permission_service.dart';
import '../../config/modules.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dashboard_header.dart';
import '../../theme/nest_loader.dart';

class CurrentVisitorsScreen extends StatefulWidget {
  const CurrentVisitorsScreen({super.key});

  @override
  State<CurrentVisitorsScreen> createState() => _CurrentVisitorsScreenState();
}

class _CurrentVisitorsScreenState extends State<CurrentVisitorsScreen> {
  final CommunityService _service = CommunityService();
  List<dynamic> _visitors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getInsideVisitors();
      if (mounted) setState(() { _visitors = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markExit(int logId) async {
    try {
      await _service.logVisitorExit({
        'visitor_log_id': logId,
        'gate': 'Main Gate',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visitor marked as exited')),
        );
        _fetch();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final canExit = PermissionService().canUpdate(ModuleCodes.visitors);

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: AppColors.white,
        backgroundColor: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AppDashboardHeader(
                leftAction: appHeaderBackButton(context),
                title: 'Inside Now',
                subtitle: 'Visitors currently on the premises',
                stats: [
                  AppHeaderStat(
                    value: '${_visitors.length}',
                    label: 'Inside',
                    color: AppColors.accentGreen,
                    icon: Icons.groups_outlined,
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(child: NestLoader())
            else if (_visitors.isEmpty)
              SliverFillRemaining(child: _buildEmpty())
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad + 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildCard(_visitors[i], canExit),
                    childCount: _visitors.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(dynamic log, bool canExit) {
    final visitor = log['Visitor'] as Map<String, dynamic>? ?? {};
    final house = log['House'] as Map<String, dynamic>?;
    final name = visitor['name'] as String? ?? 'Unknown';
    final mobile = visitor['mobile'] as String? ?? '—';
    final houseNo = house?['house_no'] as String? ?? '—';
    final logId = log['id'] as int?;

    String entryTime = '—';
    try {
      final t = DateTime.parse(log['entry_time'] as String);
      entryTime = DateFormat('hh:mm a').format(t);
    } catch (_) {}

    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'V';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.accentGreen,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      mobile,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.home_outlined,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      houseNo,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.login_outlined,
                        size: 12, color: AppColors.accentGreen),
                    const SizedBox(width: 4),
                    Text(
                      'Entered $entryTime',
                      style: const TextStyle(
                        color: AppColors.accentGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (canExit && logId != null) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _markExit(logId),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.accentRed.withValues(alpha: 0.25),
                  ),
                ),
                child: const Text(
                  'Exit',
                  style: TextStyle(
                    color: AppColors.accentRed,
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

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_outlined, color: AppColors.border, size: 56),
          SizedBox(height: 12),
          Text(
            'No visitors inside right now',
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
