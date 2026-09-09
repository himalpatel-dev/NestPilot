import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/billing_payment.dart';
import '../../theme/app_colors.dart';
import '../../widgets/module_page_header.dart';
import 'bill_report_widgets.dart';

/// Every payment collected in the selected month. The dashboard previews the
/// latest few and hands the full list over here.
class RecentPaymentsScreen extends StatefulWidget {
  final List<DashboardPayment> payments;

  /// The month the dashboard was showing, e.g. 'September 2026'.
  final String monthLabel;

  const RecentPaymentsScreen({
    super.key,
    required this.payments,
    required this.monthLabel,
  });

  @override
  State<RecentPaymentsScreen> createState() => _RecentPaymentsScreenState();
}

class _RecentPaymentsScreenState extends State<RecentPaymentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DashboardPayment> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.payments;
    return widget.payments
        .where(
          (p) =>
              (p.memberName ?? '').toLowerCase().contains(q) ||
              (p.flatNo ?? '').toLowerCase().contains(q) ||
              p.paymentMode.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final payments = _filtered;
    final totalCollected = widget.payments.fold<double>(
      0,
      (sum, p) => sum + p.amount,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cardBackground,
        body: Column(
          children: [
            ModulePageHeader(
              title: 'Recent Payments',
              description: widget.monthLabel,
              icon: Icons.payments_outlined,
              iconColor: ModuleColors.bills,
              stats: [
                ModuleHeaderStat(formatBillAmount(totalCollected), 'COLLECTED'),
                ModuleHeaderStat('${widget.payments.length}', 'PAYMENTS'),
              ],
              showSearch: true,
              searchHint: 'Search by member or flat...',
              searchController: _searchController,
              onSearchChanged: (v) => setState(() => _query = v),
            ),
            Expanded(
              child: payments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No payments match that search.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: payments.length,
                      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 24),
                      itemBuilder: (context, index) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
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
                        child: PaymentRow(payment: payments[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
