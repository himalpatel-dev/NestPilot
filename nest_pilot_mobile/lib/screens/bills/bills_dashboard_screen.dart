import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/billing_payment.dart';
import '../../services/billing_payment_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/module_page_header.dart';
import 'bill_report_widgets.dart';
import 'bills_manage_screen.dart';
import 'pending_bills_screen.dart';
import 'recent_payments_screen.dart';

class BillsDashboardScreen extends StatefulWidget {
  const BillsDashboardScreen({super.key});

  @override
  State<BillsDashboardScreen> createState() => _BillsDashboardScreenState();
}

class _BillsDashboardScreenState extends State<BillsDashboardScreen> {
  /// How many rows each section previews before handing off to its own page —
  /// the dashboard is a summary, not a list.
  static const int _pendingPreview = 3;
  static const int _paymentsPreview = 5;

  final BillService _service = BillService();

  BillsDashboardData? _data;
  bool _loading = true;
  String? _error;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  /// The month on screen, spelled out for the pages this dashboard hands off
  /// to — they show the same data, just without the month picker.
  String get _monthLabel => DateFormat('MMMM yyyy').format(_month);

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
      if (mounted) {
        setState(() {
          _data = result;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
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
        child: ConstrainedBox(
          // Twelve rows plus the header run past the bottom of a short screen,
          // so the list scrolls inside a capped sheet instead of overflowing.
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
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
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  itemCount: months.length,
                  itemBuilder: (_, i) {
                    final m = months[i];
                    final selected =
                        m.month == _month.month && m.year == _month.year;
                    return GestureDetector(
                      onTap: () => Navigator.pop(ctx, m),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? ModuleColors.bills.withValues(alpha: 0.12)
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? ModuleColors.bills
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              DateFormat('MMMM yyyy').format(m),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            if (selected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: ModuleColors.bills,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null &&
        (picked.month != _month.month || picked.year != _month.year)) {
      setState(() => _month = picked);
      _fetch();
    }
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
          child: Column(
            children: [
              ModulePageHeader(
                title: 'Bills Dashboard',
                description: 'Collections at a glance',
                icon: Icons.donut_large_outlined,
                iconColor: ModuleColors.bills,
                showSearch: false,
                stats: [
                  ModuleHeaderStat(
                    _loading ? '—' : formatBillAmount(stats?.totalPending ?? 0),
                    'PENDING DUES',
                  ),
                  ModuleHeaderStat(
                    _loading
                        ? '—'
                        : formatBillAmount(stats?.totalCollected ?? 0),
                    'COLLECTED',
                  ),
                  ModuleHeaderStat(
                    _loading ? '—' : '${stats?.pendingBillsCount ?? 0}',
                    'PENDING BILLS',
                  ),
                ],
              ),
              Expanded(
                child: _error != null
                    ? _errorState()
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          bottomPad + 28,
                        ),
                        children: [
                          _buildCollectionOverview(stats),
                          const SizedBox(height: 16),
                          _buildPendingReport(),
                          const SizedBox(height: 16),
                          _buildRecentPayments(context),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.accentRed,
            ),
            const SizedBox(height: 14),
            const Text(
              "Couldn't load the dashboard",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetch,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: AppColors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
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
                      value: formatBillAmount(collected),
                      label:
                          'Collected · ${DateFormat('MMM yyyy').format(_month)}',
                    ),
                    const SizedBox(height: 22),
                    _LegendRow(
                      color: AppColors.accentRed,
                      value: formatBillAmount(pending),
                      label: 'Pending · all time',
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

  // ─── Bill-wise pending report ─────────────────────────────────────────────

  /// One expandable card per unpaid bill, tapping through to the members who
  /// still owe on it. Deliberately not the flat single-card row list that
  /// Recent Payments uses — this is a report you drill into, not a feed.
  Widget _buildPendingReport() {
    final bills = _data?.pendingByBill ?? [];

    if (_loading) {
      return const _Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (bills.isEmpty) {
      return _Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 36,
                  color: AppColors.accentGreen.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Every bill is settled',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final totalPending = bills.fold<double>(
      0,
      (sum, b) => sum + b.pendingAmount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Row(
            children: [
              const _SectionLabel(text: 'Bill-wise Pending'),
              const Spacer(),
              Text(
                '${formatBillAmount(totalPending)} across ${bills.length} '
                '${bills.length == 1 ? 'bill' : 'bills'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        for (final bill in bills.take(_pendingPreview))
          PendingBillCard(bill: bill, format: formatBillAmount),
        if (bills.length > _pendingPreview)
          _ShowAllRow(
            boxed: true,
            label: 'Show all ${bills.length} bills',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PendingBillsScreen(bills: bills, monthLabel: _monthLabel),
              ),
            ),
          ),
      ],
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
                  'All Bills',
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
          else ...[
            Column(
              children: [
                for (
                  int i = 0;
                  i < payments.length && i < _paymentsPreview;
                  i++
                ) ...[
                  if (i > 0) const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  PaymentRow(payment: payments[i]),
                ],
              ],
            ),
            if (payments.length > _paymentsPreview) ...[
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              _ShowAllRow(
                label: 'Show all ${payments.length} payments',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecentPaymentsScreen(
                      payments: payments,
                      monthLabel: _monthLabel,
                    ),
                  ),
                ),
              ),
            ],
          ],
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
            color: ModuleColors.bills,
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

// ─── "Show all" hand-off row ──────────────────────────────────────────────────

/// Tap-through to a section's own page once the dashboard has capped it.
class _ShowAllRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  /// A standalone row (one that isn't already inside a [_Card]) draws its own
  /// white surface so it reads as part of the section above it.
  final bool boxed;

  const _ShowAllRow({
    required this.label,
    required this.onTap,
    this.boxed = false,
  });

  @override
  Widget build(BuildContext context) {
    final row = Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );

    if (!boxed) return row;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: row,
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
