import 'package:flutter/material.dart';
import '../../services/billing_payment_service.dart';
import '../../models/billing_payment.dart';
import '../../theme/app_colors.dart';
import '../../widgets/module_page_header.dart';
import '../../widgets/status_widgets.dart';
import 'bill_detail_screen.dart';

class BillsListScreen extends StatefulWidget {
  const BillsListScreen({super.key});

  @override
  State<BillsListScreen> createState() => _BillsListScreenState();
}

class _BillsListScreenState extends State<BillsListScreen> {
  final BillService _billService = BillService();
  final TextEditingController _searchController = TextEditingController();
  List<MemberBill> _bills = [];
  bool _isLoading = true;
  String? _error;
  String _query = '';

  List<MemberBill> get _filteredBills {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _bills;
    return _bills
        .where((b) => (b.billTitle ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchBills();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBills() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final bills = await _billService.getMyBills();
      setState(() {
        _bills = bills;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final due = _bills.where((b) => b.status != 'PAID').length;
    final paid = _bills.where((b) => b.status == 'PAID').length;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Column(
        children: [
          ModulePageHeader(
            title: 'My Bills',
            description: 'Your dues & payment history',
            icon: Icons.receipt_long_outlined,
            iconColor: ModuleColors.bills,
            stats: [
              ModuleHeaderStat('$due', 'DUE'),
              ModuleHeaderStat('$paid', 'PAID'),
            ],
            showSearch: true,
            searchHint: 'Search bills...',
            searchController: _searchController,
            onSearchChanged: (v) => setState(() => _query = v),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _error != null
                ? ErrorWidgetView(message: _error!, onRetry: _fetchBills)
                : _filteredBills.isEmpty
                ? const EmptyWidget(
                    message: 'No bills found',
                    icon: Icons.receipt_long_outlined,
                  )
                : RefreshIndicator(
              onRefresh: _fetchBills,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredBills.length,
                itemBuilder: (context, index) {
                  final bill = _filteredBills[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        bill.billTitle ?? 'Unknown Bill',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Amount: ₹${bill.amount} | Status: ${bill.status}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BillDetailScreen(bill: bill),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
