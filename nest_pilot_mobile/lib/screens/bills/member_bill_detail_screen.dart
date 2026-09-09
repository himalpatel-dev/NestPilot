import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/billing_payment.dart';

class BillDetailScreen extends StatelessWidget {
  final MemberBill bill;
  const BillDetailScreen({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bill Detail')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bill.billTitle ?? 'Unknown Bill',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Total Amount', '₹${bill.amount}'),
            _buildDetailRow('Penalty Amount', '₹${bill.penaltyAmount}'),
            _buildDetailRow(
              'Due Date',
              DateFormat('dd MMM yyyy').format(bill.dueDate),
            ),
            _buildDetailRow(
              'Status',
              bill.status,
              color: bill.status == 'PAID' ? Colors.green : Colors.red,
            ),
            const Spacer(),
            if (bill.status != 'PAID') ...[
              const Text(
                'Note: Online payments are not enabled yet. Please pay by Cash/Cheque to the society admin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
