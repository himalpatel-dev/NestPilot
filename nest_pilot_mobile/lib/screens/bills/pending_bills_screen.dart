import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/billing_payment.dart';
import '../../theme/app_colors.dart';
import '../../widgets/module_page_header.dart';
import 'bill_report_widgets.dart';

/// Every bill that still has dues. The dashboard previews the first few and
/// hands the full report over here, so it stays a summary instead of growing
/// into an endless page.
class PendingBillsScreen extends StatefulWidget {
  final List<PendingBillReport> bills;

  /// The month the dashboard was showing, e.g. 'September 2026'.
  final String monthLabel;

  const PendingBillsScreen({
    super.key,
    required this.bills,
    required this.monthLabel,
  });

  @override
  State<PendingBillsScreen> createState() => _PendingBillsScreenState();
}

class _PendingBillsScreenState extends State<PendingBillsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PendingBillReport> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.bills;
    return widget.bills
        .where(
          (b) =>
              b.title.toLowerCase().contains(q) ||
              b.billType.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final bills = _filtered;
    final totalPending = widget.bills.fold<double>(
      0,
      (sum, b) => sum + b.pendingAmount,
    );
    final unpaidMembers = widget.bills.fold<int>(
      0,
      (sum, b) => sum + b.pendingCount,
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
              title: 'Bill-wise Pending',
              description: widget.monthLabel,
              icon: Icons.receipt_long_outlined,
              iconColor: ModuleColors.bills,
              stats: [
                ModuleHeaderStat(formatBillAmount(totalPending), 'PENDING'),
                ModuleHeaderStat('${widget.bills.length}', 'BILLS'),
                ModuleHeaderStat('$unpaidMembers', 'UNPAID'),
              ],
              showSearch: true,
              searchHint: 'Search bills...',
              searchController: _searchController,
              onSearchChanged: (v) => setState(() => _query = v),
            ),
            Expanded(
              child: bills.isEmpty
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
                            'No bills match that search.',
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
                      itemCount: bills.length,
                      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 24),
                      itemBuilder: (context, index) => PendingBillCard(
                        bill: bills[index],
                        format: formatBillAmount,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
