import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/billing_payment.dart';
import '../../services/billing_payment_service.dart';
import '../../theme/app_colors.dart';
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
      if (mounted) setState(() { _data = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final months = List.generate(
      12,
      (i) => DateTime(now.year, now.month - i),
    );
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
              SliverToBoxAdapter(
                child: _buildHeader(context, stats),
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

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, BillDashboardStats? stats) {
    final screenW = MediaQuery.of(context).size.width;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Container(
        decoration: const BoxDecoration(
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
        child: Stack(
          children: [
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                    const SizedBox(height: 14),
                    const Text(
                      'Bills Dashboard',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage society collections',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.70),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _StatChip(
                            value: _loading ? '—' : _fmt(stats?.totalPending ?? 0),
                            label: 'Pending Dues',
                            color: AppColors.accentRed,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatChip(
                            value: _loading ? '—' : _fmt(stats?.totalCollected ?? 0),
                            label: 'Collected',
                            color: AppColors.accentGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatChip(
                            value: _loading ? '—' : '${stats?.pendingBillsCount ?? 0}',
                            label: 'Pending Bills',
                            color: AppColors.accentAmber,
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
                child: _ActionTile(
                  icon: Icons.add_card_outlined,
                  label: 'Generate\nBills',
                  color: AppColors.accentGreen,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BillCreateScreen()),
                  ),
                ),
              ),
              Expanded(
                child: _ActionTile(
                  icon: Icons.payments_outlined,
                  label: 'Record\nPayment',
                  color: AppColors.accentBlue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaymentMarkScreen(),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _ActionTile(
                  icon: Icons.notifications_active_outlined,
                  label: 'Send\nReminder',
                  color: AppColors.accentAmber,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reminders sent to pending members'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _ActionTile(
                  icon: Icons.download_outlined,
                  label: 'Download\nReport',
                  color: AppColors.accentPurple,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report download coming soon'),
                    ),
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
                  if (i > 0)
                    const Divider(
                      height: 1,
                      color: Color(0xFFF3F4F6),
                    ),
                  _PaymentRow(payment: payments[i]),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Stat chip (header strip) ─────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatChip({
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
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.80),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
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
                    if (payment.flatNo != null && payment.flatNo!.isNotEmpty) ...[
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
                  DateFormat('d MMM, hh:mm a').format(payment.paymentDate.toLocal()),
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
      final sweep =
          (2 * math.pi * (1 - fraction) - gap).clamp(0.0, 2 * math.pi);
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
