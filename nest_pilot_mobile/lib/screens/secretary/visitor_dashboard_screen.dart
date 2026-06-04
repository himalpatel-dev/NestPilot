import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/community_models.dart';
import '../../services/community_service.dart';
import '../../theme/app_colors.dart';
import '../common/visitor_report_screen.dart';
import '../security/current_visitors_screen.dart';
import '../security/security_dashboard_screen.dart';

// ─── Status helpers ───────────────────────────────────────────────────────────

String _statusLabel(String status) {
  switch (status) {
    case 'INSIDE':
      return 'Approved';
    case 'WAITING_APPROVAL':
      return 'Pending';
    case 'DENIED':
      return 'Rejected';
    case 'PRE_APPROVED':
      return 'Pre-Approved';
    case 'EXITED':
      return 'Exited';
    default:
      return status.replaceAll('_', ' ');
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'INSIDE':
      return AppColors.accentGreen;
    case 'WAITING_APPROVAL':
      return AppColors.accentOrange;
    case 'DENIED':
      return AppColors.accentRed;
    case 'PRE_APPROVED':
      return AppColors.accentBlue;
    case 'EXITED':
      return AppColors.textSecondary;
    default:
      return AppColors.accentBlue;
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class VisitorDashboardScreen extends StatefulWidget {
  const VisitorDashboardScreen({super.key});

  @override
  State<VisitorDashboardScreen> createState() => _VisitorDashboardScreenState();
}

class _VisitorDashboardScreenState extends State<VisitorDashboardScreen> {
  final CommunityService _service = CommunityService();

  VisitorDashboardData? _data;
  bool _loading = true;
  String? _error;
  int _filterIndex = 0; // 0=All 1=Pending 2=Approved 3=Rejected

  static const _filterLabels = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _service.getVisitorDashboard();
      if (mounted) setState(() { _data = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<VisitorDashboardEntry> get _filtered {
    final all = _data?.todayVisitors ?? [];
    switch (_filterIndex) {
      case 1:
        return all.where((v) => v.status == 'WAITING_APPROVAL').toList();
      case 2:
        return all
            .where((v) => v.status == 'INSIDE' || v.status == 'PRE_APPROVED')
            .toList();
      case 3:
        return all.where((v) => v.status == 'DENIED').toList();
      default:
        return all;
    }
  }

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
        backgroundColor: AppColors.cardBackground,
        body: RefreshIndicator(
          onRefresh: _fetch,
          color: AppColors.white,
          backgroundColor: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.accentRed),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _fetch,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad + 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildQuickActions(context),
                      const SizedBox(height: 16),
                      _buildFilterCard(),
                      const SizedBox(height: 20),
                      _buildSectionHeader(
                        "Today's Visitors",
                        trailingLabel: '${_filtered.length} entries',
                      ),
                      const SizedBox(height: 12),
                      _buildVisitorList(),
                      const SizedBox(height: 20),
                      _buildHistorySection(context),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Hero header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    final screenW = MediaQuery.of(context).size.width;
    final heroH = safeTop + 185.0;
    final stats = _data;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: SizedBox(
        height: heroH,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.6, 1.0],
                  colors: [
                    AppColors.heroGradientDeep,
                    AppColors.primaryDark,
                    AppColors.primary,
                  ],
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 40,
              top: -10,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: screenW * 0.48,
              child: ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: const [0.0, 0.40, 1.0],
                  colors: [
                    AppColors.transparent,
                    AppColors.white.withValues(alpha: 0.20),
                    AppColors.white.withValues(alpha: 0.45),
                  ],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/dash2.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (Navigator.canPop(context))
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    const Spacer(),
                    const Text(
                      'Visitor Dashboard',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Monitor society visitor activity',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.70),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _HeroStatChip(
                            value: _loading ? '—' : '${stats?.insideCount ?? 0}',
                            label: 'Visitors\nInside',
                            color: AppColors.accentGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _HeroStatChip(
                            value: _loading ? '—' : '${stats?.pendingCount ?? 0}',
                            label: 'Pending\nApprovals',
                            color: AppColors.accentOrange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _HeroStatChip(
                            value: _loading ? '—' : '${stats?.todayCount ?? 0}',
                            label: "Today's\nEntries",
                            color: AppColors.accentBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Quick actions ────────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return _LightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Quick Actions'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.how_to_reg_outlined,
                  label: 'Log\nEntry',
                  color: AppColors.accentGreen,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SecurityDashboardScreen(),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _ActionTile(
                  icon: Icons.groups_outlined,
                  label: 'Inside\nNow',
                  color: AppColors.accentBlue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CurrentVisitorsScreen(),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _ActionTile(
                  icon: Icons.history_rounded,
                  label: 'View\nLogs',
                  color: AppColors.accentPurple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VisitorReportScreen(),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _ActionTile(
                  icon: Icons.notifications_active_outlined,
                  label: 'Send\nAlert',
                  color: AppColors.accentAmber,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alert sent to residents')),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Filter card (pill segments) ──────────────────────────────────────────────

  Widget _buildFilterCard() {
    return _LightCard(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: List.generate(_filterLabels.length, (i) {
          final selected = i == _filterIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _filterIndex = i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _filterLabels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? AppColors.white : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Today's visitor list ──────────────────────────────────────────────────────

  Widget _buildVisitorList() {
    final visitors = _filtered;

    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (visitors.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 40,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 10),
            const Text(
              'No visitors found',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < visitors.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _VisitorTile(entry: visitors[i]),
        ],
      ],
    );
  }

  // ─── History section ──────────────────────────────────────────────────────────

  Widget _buildHistorySection(BuildContext context) {
    final d = _data;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionLabel(text: 'Visitor History'),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VisitorReportScreen()),
              ),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _HistoryStatTile(
                icon: Icons.today_outlined,
                color: AppColors.accentOrange,
                count: _loading ? 0 : (d?.yesterdayCount ?? 0),
                label: 'Yesterday',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HistoryStatTile(
                icon: Icons.date_range_outlined,
                color: AppColors.accentBlue,
                count: _loading ? 0 : (d?.weekCount ?? 0),
                label: 'This Week',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HistoryStatTile(
                icon: Icons.calendar_month_outlined,
                color: AppColors.accentPurple,
                count: _loading ? 0 : (d?.monthCount ?? 0),
                label: 'This Month',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Section header row ───────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, {String? trailingLabel}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SectionLabel(text: title),
        if (trailingLabel != null)
          Text(
            trailingLabel,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

// ─── Hero stat chip ───────────────────────────────────────────────────────────

class _HeroStatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _HeroStatChip({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.75),
              fontSize: 9,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Light card container ─────────────────────────────────────────────────────

class _LightCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _LightCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Section label (accent bar + bold text) ───────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ─── Quick-action tile ────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Visitor tile (resident-card style) ──────────────────────────────────────

class _VisitorTile extends StatelessWidget {
  final VisitorDashboardEntry entry;
  const _VisitorTile({required this.entry});

  static const _avatarColors = [
    AppColors.accentBlue,
    AppColors.accentGreen,
    AppColors.accentPurple,
    AppColors.accentAmber,
    AppColors.accentOrange,
  ];

  @override
  Widget build(BuildContext context) {
    final name = entry.visitorName;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final avatarColor = _avatarColors[name.length % _avatarColors.length];
    final statusColor = _statusColor(entry.status);
    final flatLabel = (entry.flatNo != null && entry.flatNo!.isNotEmpty)
        ? entry.flatNo!
        : '—';
    final timeStr = entry.entryTime != null
        ? DateFormat('hh:mm a').format(entry.entryTime!.toLocal())
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: avatarColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                color: avatarColor,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + flat
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      flatLabel,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(entry.status),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                if (timeStr.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
            size: 20,
          ),
        ],
      ),
    );
  }
}

// ─── History stat tile (matches member list stats style) ─────────────────────

class _HistoryStatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final String label;
  const _HistoryStatTile({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.0,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 1),
          Text(
            'Visitors',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}
