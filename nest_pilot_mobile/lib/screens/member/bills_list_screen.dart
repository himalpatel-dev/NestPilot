import 'package:flutter/material.dart';
import '../../services/billing_payment_service.dart';
import '../../models/billing_payment.dart';
import '../../widgets/status_widgets.dart';
import 'bill_detail_screen.dart';

class BillsListScreen extends StatefulWidget {
  const BillsListScreen({super.key});

  @override
  State<BillsListScreen> createState() => _BillsListScreenState();
}

class _BillsListScreenState extends State<BillsListScreen> {
  final BillService _billService = BillService();
  List<MemberBill> _bills = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBills();
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
    return Scaffold(
      appBar: AppBar(title: const Text('My Bills')),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
          ? ErrorWidgetView(message: _error!, onRetry: _fetchBills)
          : _bills.isEmpty
          ? const EmptyWidget(
              message: 'No bills found',
              icon: Icons.receipt_long_outlined,
            )
          : RefreshIndicator(
              onRefresh: _fetchBills,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _bills.length,
                itemBuilder: (context, index) {
                  final bill = _bills[index];
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
    );
  }
}
