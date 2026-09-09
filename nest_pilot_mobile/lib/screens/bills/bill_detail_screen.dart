import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/modules.dart';
import '../../models/billing_payment.dart';
import '../../services/billing_payment_service.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_page_header.dart';

/// Read-only view of a society bill. Editing and deleting stay on the list
/// screen — the only action offered here is publishing a draft, which pops
/// `true` so the list knows to refetch.
class BillDetailScreen extends StatefulWidget {
  final Bill bill;

  const BillDetailScreen({super.key, required this.bill});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  final BillService _service = BillService();
  bool _publishing = false;

  Bill get _bill => widget.bill;

  Color get _statusColor {
    switch (_bill.status) {
      case 'PUBLISHED':
        return AppColors.accentGreen;
      case 'DRAFT':
        return AppColors.accentAmber;
      case 'CANCELLED':
        return AppColors.accentRed;
      default:
        return AppColors.primary;
    }
  }

  IconData get _statusIcon {
    switch (_bill.status) {
      case 'PUBLISHED':
        return Icons.check_circle_outline_rounded;
      case 'CANCELLED':
        return Icons.cancel_outlined;
      default:
        return Icons.edit_note_rounded;
    }
  }

  String _money(double value) => NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: value % 1 == 0 ? 0 : 2,
  ).format(value);

  Future<void> _publish() async {
    setState(() => _publishing = true);
    try {
      final success = await _service.publishBill(_bill.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bill published successfully'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
        Navigator.pop(context, true);
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
    if (mounted) setState(() => _publishing = false);
  }

  @override
  Widget build(BuildContext context) {
    final bill = _bill;
    final canPublish =
        bill.status == 'DRAFT' &&
        PermissionService().canManage(ModuleCodes.bills);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isOverdue =
        bill.status == 'PUBLISHED' && bill.dueDate.isBefore(DateTime.now());
    final dueColor = isOverdue ? AppColors.accentRed : AppColors.accentBlue;
    final hasNotes = bill.description != null && bill.description!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Stack(
        children: [
          Column(
            children: [
              AppPageHeader(
                icon: Icons.receipt_long_outlined,
                title: 'Bill',
                accentColor: ModuleColors.bills,
                subtitle: bill.billType,
              ),

              // Sits outside the scroll view so the gap under the fixed header
              // survives scrolling instead of collapsing with the content.
              const SizedBox(height: 14),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    bottomPad + (canPublish ? 116 : 40),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Summary card ───────────────────────────────────
                      _card(
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _statusColor.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _statusIcon,
                                    size: 13,
                                    color: _statusColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    bill.status,
                                    style: TextStyle(
                                      color: _statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              bill.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                            if (hasNotes) ...[
                              const SizedBox(height: 10),
                              Text(
                                bill.description!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13.5,
                                  height: 1.5,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            // Amount banner
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                16,
                                18,
                                16,
                              ),
                              decoration: BoxDecoration(
                                color: ModuleColors.bills.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: ModuleColors.bills.withValues(
                                    alpha: 0.20,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TOTAL AMOUNT',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _money(bill.amountTotal),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            _infoRow(
                              icon: Icons.event_outlined,
                              color: dueColor,
                              label: isOverdue ? 'Overdue since' : 'Due date',
                              value: DateFormat(
                                'EEE, dd MMM yyyy',
                              ).format(bill.dueDate),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Details card ───────────────────────────────────
                      _card(
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionLabel('Bill Details'),
                            const SizedBox(height: 18),
                            _infoRow(
                              icon: Icons.category_outlined,
                              color: AppColors.accentAmber,
                              label: 'Bill type',
                              value: bill.billType,
                            ),
                            const SizedBox(height: 16),
                            _infoRow(
                              icon: Icons.home_work_outlined,
                              color: AppColors.accentIndigo,
                              label: 'Applies to',
                              value: bill.applyTo == 'ALL'
                                  ? 'All flats'
                                  : 'Selected flats',
                            ),
                            if (bill.penaltyValue > 0) ...[
                              const SizedBox(height: 16),
                              _infoRow(
                                icon: Icons.warning_amber_rounded,
                                color: AppColors.accentRed,
                                label: 'Late penalty',
                                value: bill.penaltyType == 'PERCENT'
                                    ? '${bill.penaltyValue}% of the bill'
                                    : _money(bill.penaltyValue),
                              ),
                            ],
                            if (bill.createdAt != null) ...[
                              const SizedBox(height: 16),
                              _infoRow(
                                icon: Icons.schedule_rounded,
                                color: AppColors.primary,
                                label: 'Created on',
                                value: DateFormat(
                                  'dd MMM yyyy · hh:mm a',
                                ).format(bill.createdAt!),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Explains why no action button is offered below.
                      if (bill.status == 'PUBLISHED') ...[
                        const SizedBox(height: 14),
                        _noticeCard(
                          icon: Icons.info_outline_rounded,
                          color: AppColors.accentGreen,
                          message:
                              'This bill is live. Member bills have been '
                              'generated and residents were notified, so it '
                              'can no longer be edited or removed.',
                        ),
                      ] else if (bill.status == 'CANCELLED') ...[
                        const SizedBox(height: 14),
                        _noticeCard(
                          icon: Icons.cancel_outlined,
                          color: AppColors.accentRed,
                          message:
                              'This bill was cancelled and can no longer be '
                              'published. Nothing was sent to members.',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Publish action ─────────────────────────────────────────────
          if (canPublish) ...[
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: bottomPad + 104,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.cardBackground.withValues(alpha: 0),
                        AppColors.cardBackground.withValues(alpha: 0.9),
                        AppColors.cardBackground,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomPad + 16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _publishing ? null : _publish,
                    icon: _publishing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 20),
                    label: Text(_publishing ? 'Publishing…' : 'Publish Bill'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor: AppColors.primaryDark.withValues(
                        alpha: 0.6,
                      ),
                      disabledForegroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: ModuleColors.bills,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
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

  Widget _noticeCard({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsets? padding,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
