import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/billing_payment_service.dart';
import '../../models/billing_payment.dart';
import '../../widgets/status_widgets.dart';

class BillsManageScreen extends StatefulWidget {
  const BillsManageScreen({super.key});

  @override
  State<BillsManageScreen> createState() => _BillsManageScreenState();
}

class _BillsManageScreenState extends State<BillsManageScreen> {
  final BillService _billService = BillService();
  List<Bill> _bills = [];
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
      final bills = await _billService.getBills();
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

  Future<void> _publishBill(String id) async {
    try {
      final success = await _billService.publishBill(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill published successfully')),
        );
        _fetchBills();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Bills')),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
          ? ErrorWidgetView(message: _error!, onRetry: _fetchBills)
          : _bills.isEmpty
          ? const EmptyWidget(
              message: 'No bills created yet',
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
                        bill.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Amount: ₹${bill.amountTotal}'),
                          Text(
                            'Due: ${DateFormat('dd MMM yyyy').format(bill.dueDate)}',
                          ),
                          Text(
                            'Status: ${bill.status}',
                            style: TextStyle(
                              color: bill.status == 'PUBLISHED'
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: bill.status == 'DRAFT'
                          ? ElevatedButton(
                              onPressed: () => _publishBill(bill.id),
                              child: const Text('Publish'),
                            )
                          : const Icon(Icons.check_circle, color: Colors.green),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
