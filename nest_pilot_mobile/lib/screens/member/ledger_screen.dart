import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/billing_payment_service.dart';
import '../../services/file_service.dart';
import '../../models/billing_payment.dart';
import '../../widgets/status_widgets.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  final PaymentService _paymentService = PaymentService();
  final FileService _fileService = FileService();
  List<Payment> _payments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final payments = await _paymentService.getMyPayments();
      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Ledger')),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
          ? ErrorWidgetView(message: _error!, onRetry: _fetchPayments)
          : Column(
              children: [
                _buildSummaryCard(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Payment History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: _payments.isEmpty
                      ? const EmptyWidget(message: 'No payments recorded yet')
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _payments.length,
                          itemBuilder: (context, index) {
                            final payment = _payments[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(
                                  '₹${payment.amount}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Mode: ${payment.paymentMode} | ${DateFormat('dd MMM yyyy').format(payment.paymentDate)}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.download,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _downloadReceipt(payment.id),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard() {
    // In a real app, we'd calculate this from bills and payments
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Outstanding',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            '₹ 0.00', // Placeholder
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMiniStat('Paid', '₹ 0.00'),
              const SizedBox(width: 24),
              _buildMiniStat('Dues', '₹ 0.00'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
