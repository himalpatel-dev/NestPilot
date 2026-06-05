import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/billing_payment.dart';
import '../../services/billing_payment_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dashboard_header.dart';
import '../../theme/app_icons.dart';
import '../notification_list_screen.dart';
import 'bill_create_screen.dart';
import 'bills_manage_screen.dart';
import 'payment_mark_screen.dart';

class BillsDashboardScreen extends StatefulWidget {
  const BillsDashboardScreen({super.key});

  @override
  State<BillsDashboardScreen> createState() => _BillsDashboardScreenState();
}

class _BillsDashboardScreenState extends State<BillsDashboardScreen> {
  final BillService _service = BillService();

  BillsDashboardData? _data;
  bool _loading = true;
  String? _error;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.getDashboardData(
        month: DateFormat('yyyy-MM').format(_month),
      );
      if (mounted)
        setState(() {
          _data = result;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final months = List.generate(12, (i) => DateTime(now.year, now.month - i));
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Select Month',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...months.map(
              (m) => ListTile(
                title: Text(DateFormat('MMMM yyyy').format(m)),
                trailing: m.month == _month.month && m.year == _month.year
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, m),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null &&
        (picked.month != _month.month || picked.year != _month.year)) {
      setState(() => _month = picked);
      _fetch();
    }
  }

  String _fmt(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final stats = _data?.stats;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
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
              SliverToBoxAdapter(
                child: AppDashboardHeader(
                  title: 'Bills Dashboard',
                  subtitle: 'Manage society collections',
                  onNotificationTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationListScreen(),
                    ),
                  ),
                  stats: [
                    AppHeaderStat(
                      value: _loading ? '—' : _fmt(stats?.totalPending ?? 0),
                      label: 'Pending Dues',
                      color: AppColors.accentRed,
                      icon: Icons.receipt_long_rounded,
                    ),
                    AppHeaderStat(
                      value: _loading ? '—' : _fmt(stats?.totalCollected ?? 0),
                      label: 'Collected',
                      color: AppColors.accentGreen,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                    AppHeaderStat(
                      value: _loading
                          ? '—'
                          : '${stats?.pendingBillsCount ?? 0}',
                      label: 'Pending Bills',
                      color: AppColors.accentAmber,
                      icon: Icons.pending_outlined,
                    ),
                  ],
                ),
              ),
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
                      _buildCollectionOverview(stats),
                      const SizedBox(height: 16),
                      _buildRecentPayments(context),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Quick actions ────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Quick Actions'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BillCreateScreen()),
                  ),
                  child: const AppIconTile(
                    icon: Icons.add_card_outlined,
                    label: 'Create Bills',
                    color: AppColors.accentGreen,
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaymentMarkScreen(),
                    ),
                  ),
                  child: const AppIconTile(
                    icon: Icons.payments_outlined,
                    label: 'Payment',
                    color: AppColors.accentBlue,
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reminders sent to pending members'),
                    ),
                  ),
                  child: const AppIconTile(
                    icon: Icons.notifications_active_outlined,
                    label: 'Send Reminder',
                    color: AppColors.accentAmber,
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report download coming soon'),
                    ),
                  ),
                  child: const AppIconTile(
                    icon: Icons.download_outlined,
                    label: 'Download Report',
                    color: AppColors.accentPurple,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Collection overview ──────────────────────────────────────────────────

  Widget _buildCollectionOverview(BillDashboardStats? stats) {
    final collected = stats?.totalCollected ?? 0;
    final pending = stats?.totalPending ?? 0;
    final total = collected + pending;
    final fraction = total > 0 ? (collected / total).clamp(0.0, 1.0) : 0.0;
    final pct = (fraction * 100).round();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel(text: 'Collection Overview'),
              GestureDetector(
                onTap: _pickMonth,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('MMM yyyy').format(_month),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(130, 130),
                      painter: _DonutPainter(fraction: fraction),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$pct%',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Text(
                          'Collected',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendRow(
                      color: AppColors.accentGreen,
                      value: _fmt(collected),
                      label: 'Collected',
                    ),
                    const SizedBox(height: 22),
                    _LegendRow(
                      color: AppColors.accentRed,
                      value: _fmt(pending),
                      label: 'Pending',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Recent payments ──────────────────────────────────────────────────────

  Widget _buildRecentPayments(BuildContext context) {
    final payments = _data?.recentPayments ?? [];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel(text: 'Recent Payments'),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BillsManageScreen()),
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
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (payments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 36,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No payments this month',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < payments.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  _PaymentRow(payment: payments[i]),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

// ─── White card container ─────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ─── Legend row (donut chart) ─────────────────────────────────────────────────

class _LegendRow extends StatelessWidget {
  final Color color;
  final String value;
  final String label;
  const _LegendRow({
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Payment row ──────────────────────────────────────────────────────────────

class _PaymentRow extends StatelessWidget {
  final DashboardPayment payment;
  const _PaymentRow({required this.payment});

  static const _avatarColors = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];

  @override
  Widget build(BuildContext context) {
    final name = payment.memberName ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final avatarColor = _avatarColors[name.length % _avatarColors.length];
    final fmt = NumberFormat('#,##,###');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: avatarColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                color: avatarColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (payment.flatNo != null &&
                        payment.flatNo!.isNotEmpty) ...[
                      Text(
                        payment.flatNo!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        ' | ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    Flexible(
                      child: Text(
                        name.isNotEmpty ? name : 'Unknown',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat(
                    'd MMM, hh:mm a',
                  ).format(payment.paymentDate.toLocal()),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${fmt.format(payment.amount)}',
                style: const TextStyle(
                  color: AppColors.accentGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Paid',
                  style: TextStyle(
                    color: AppColors.accentGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Donut chart painter ──────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final double fraction;
  const _DonutPainter({required this.fraction});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 12;
    const strokeW = 14.0;
    const startAngle = -math.pi / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..color = const Color(0xFFE5E7EB),
    );

    if (fraction > 0.005) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * fraction.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round
          ..color = AppColors.accentGreen,
      );
    }

    if (fraction < 0.995) {
      final gap = fraction > 0.005 ? 0.06 : 0.0;
      final sweep = (2 * math.pi * (1 - fraction) - gap).clamp(
        0.0,
        2 * math.pi,
      );
      if (sweep > 0.01) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle + 2 * math.pi * fraction + gap,
          sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFFFCA5A5),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.fraction != fraction;
}
