import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/billing_payment_service.dart';
import '../../services/permission_service.dart';
import '../../config/modules.dart';
import '../../models/billing_payment.dart';
import '../../theme/app_colors.dart';
import '../../widgets/module_page_header.dart';
import '../../widgets/status_widgets.dart';
import 'bill_create_screen.dart';

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
    final canPublish = PermissionService().canManage(ModuleCodes.bills);
    final draft = _bills.where((b) => b.status == 'DRAFT').length;
    final published = _bills.where((b) => b.status == 'PUBLISHED').length;
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Column(
        children: [
          ModulePageHeader(
            title: 'Bills',
            description: 'Create & publish maintenance bills',
            icon: Icons.receipt_long_outlined,
            iconColor: ModuleColors.bills,
            stats: [
              ModuleHeaderStat('$draft', 'DRAFT'),
              ModuleHeaderStat('$published', 'PUBLISHED'),
              ModuleHeaderStat('${_bills.length}', 'TOTAL'),
            ],
          ),
          Expanded(
            child: _isLoading
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
                                ? (canPublish
                                    ? ElevatedButton(
                                        onPressed: () => _publishBill(bill.id),
                                        child: const Text('Publish'),
                                      )
                                    : const Icon(Icons.edit_note_outlined,
                                        color: Colors.orange))
                                : const Icon(Icons.check_circle,
                                    color: Colors.green),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      // Creating a bill is a manage-only action — the list itself is
      // shared with view-only roles.
      floatingActionButton: canPublish
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BillCreateScreen()),
              ).then((_) => _fetchBills()),
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
