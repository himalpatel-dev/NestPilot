import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/billing_payment.dart';
import '../../services/billing_payment_service.dart';
import '../../services/file_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/nest_loader.dart';
import '../../widgets/module_page_header.dart';
import '../../widgets/status_widgets.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  final PaymentService _paymentService = PaymentService();
  final BillService _billService = BillService();
  final FileService _fileService = FileService();
  final TextEditingController _searchController = TextEditingController();

  List<Payment> _payments = [];
  List<MemberBill> _bills = [];
  bool _isLoading = true;
  String? _error;
  String _query = '';

  // ── Account totals ────────────────────────────────────────────────────────
  // Bills are the debits, payments the credits. MemberBill.amount is the full
  // billed figure and is never decremented as payments come in, so the balance
  // has to be billed − paid rather than a sum over unpaid rows — that is the
  // only form that gets a partially paid bill right.

  double get _totalBilled =>
      _bills.fold(0.0, (sum, b) => sum + b.amount + b.penaltyAmount);

  double get _totalPaid => _payments.fold(0.0, (sum, p) => sum + p.amount);

  double get _outstanding {
    final balance = _totalBilled - _totalPaid;
    return balance > 0 ? balance : 0;
  }

  int get _unpaidCount => _bills.where((b) => b.status != 'PAID').length;

  int get _overdueCount => _bills
      .where((b) => b.status != 'PAID' && b.dueDate.isBefore(DateTime.now()))
      .length;

  List<Payment> get _filteredPayments {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _payments;
    return _payments.where((p) {
      final date = DateFormat('dd MMM yyyy').format(p.paymentDate);
      return p.paymentMode.toLowerCase().contains(q) ||
          p.amount.toString().contains(q) ||
          date.toLowerCase().contains(q) ||
          (p.referenceNo ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchLedger();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLedger() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Both sides of the balance, so the summary can never disagree with the
      // list below it.
      final results = await Future.wait([
        _paymentService.getMyPayments(),
        _billService.getMyBills(),
      ]);
      if (!mounted) return;
      setState(() {
        _payments = results[0] as List<Payment>;
        _bills = results[1] as List<MemberBill>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadReceipt(String paymentId) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Downloading receipt...')));
      await _fileService.downloadAndOpenReceipt(paymentId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  String _money(double value) => NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: value % 1 == 0 ? 0 : 2,
  ).format(value);

  IconData _modeIcon(String mode) {
    switch (mode.toUpperCase()) {
      case 'CHEQUE':
        return Icons.receipt_long_rounded;
      case 'ONLINE':
        return Icons.account_balance_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Column(
        children: [
          ModulePageHeader(
            title: 'Ledger',
            description: 'Your account statement',
            icon: Icons.account_balance_outlined,
            iconColor: ModuleColors.bills,
            stats: [
              ModuleHeaderStat('${_payments.length}', 'PAYMENTS'),
              ModuleHeaderStat('$_unpaidCount', 'PENDING'),
              ModuleHeaderStat('${_bills.length}', 'BILLS'),
            ],
            showSearch: true,
            searchHint: 'Search payments...',
            searchController: _searchController,
            onSearchChanged: (v) => setState(() => _query = v),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: NestLoader())
                : _error != null
                ? ErrorWidgetView(message: _error!, onRetry: _fetchLedger)
                : RefreshIndicator(
                    onRefresh: _fetchLedger,
                    color: AppColors.white,
                    backgroundColor: AppColors.primary,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad + 24),
                      children: [
                        _summaryCard(),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 16,
                              decoration: BoxDecoration(
                                color: ModuleColors.bills,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Payment History',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_filteredPayments.isEmpty)
                          _emptyHistory()
                        else
                          ..._filteredPayments.map(_paymentCard),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Outstanding balance computed from the member's own bills and payments —
  /// the figures the resident is checking the screen for.
  Widget _summaryCard() {
    final settled = _outstanding <= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'TOTAL OUTSTANDING',
                style: TextStyle(
                  color: AppColors.whiteTranslucent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (settled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: AppColors.white,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'All clear',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _money(_outstanding),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: AppColors.dividerOnDark),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _miniStat('Billed', _money(_totalBilled))),
              Container(height: 30, width: 1, color: AppColors.dividerOnDark),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _miniStat('Paid', _money(_totalPaid)),
                ),
              ),
            ],
          ),
          if (_overdueCount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppColors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _overdueCount == 1
                          ? '1 bill is past its due date'
                          : '$_overdueCount bills are past their due date',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.whiteTranslucent,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _paymentCard(Payment payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
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
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Icon(
              _modeIcon(payment.paymentMode),
              size: 19,
              color: AppColors.accentGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _money(payment.amount),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${payment.paymentMode} · '
                  '${DateFormat('dd MMM yyyy').format(payment.paymentDate)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (payment.referenceNo != null &&
                    payment.referenceNo!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Ref: ${payment.referenceNo}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Download receipt',
            icon: const Icon(
              Icons.download_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            onPressed: () => _downloadReceipt(payment.id),
          ),
        ],
      ),
    );
  }

  Widget _emptyHistory() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 56,
            color: AppColors.border,
          ),
          const SizedBox(height: 12),
          Text(
            _query.trim().isEmpty
                ? 'No payments recorded yet'
                : 'No payments match your search',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Payments appear here once the society records them',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
