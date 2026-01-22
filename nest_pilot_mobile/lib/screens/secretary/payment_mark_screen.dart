import 'package:flutter/material.dart';
import '../../services/billing_payment_service.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../models/billing_payment.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/status_widgets.dart';

class PaymentMarkScreen extends StatefulWidget {
  const PaymentMarkScreen({super.key});

  @override
  State<PaymentMarkScreen> createState() => _PaymentMarkScreenState();
}

class _PaymentMarkScreenState extends State<PaymentMarkScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _refController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final PaymentService _paymentService = PaymentService();
  final AdminService _adminService = AdminService();
  final BillService _billService = BillService();

  List<UserModel> _members = [];
  List<MemberBill> _userBills = [];
  UserModel? _selectedUser;
  MemberBill? _selectedBill;

  String _selectedMode = 'CASH';
  final DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isFetchingMembers = true;
  bool _isFetchingBills = false;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() => _isFetchingMembers = true);
    try {
      final members = await _adminService.getSocietyMembers();
      setState(() {
        _members = members;
        _isFetchingMembers = false;
      });
    } catch (e) {
      setState(() => _isFetchingMembers = false);
    }
  }

  Future<void> _fetchUserBills(String userId) async {
    setState(() => _isFetchingBills = true);
    try {
      final bills = await _billService.getUserBills(userId);
      setState(() {
        _userBills = bills.where((b) => b.status != 'PAID').toList();
        _isFetchingBills = false;
      });
    } catch (e) {
      setState(() => _isFetchingBills = false);
    }
  }

  Future<void> _markPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBill == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a bill')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await _paymentService.markPaymentReceived({
        'memberBillId': _selectedBill!.id,
        'amount': double.parse(_amountController.text),
        'paymentMode': _selectedMode,
        'paymentDate': _selectedDate.toIso8601String(),
        'referenceNo': _refController.text,
        'note': _noteController.text,
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Offline Payment')),
      body: _isFetchingMembers
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Member',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<UserModel>(
                      value: _selectedUser,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select a member',
                      ),
                      items: _members.map((u) {
                        return DropdownMenuItem(
                          value: u,
                          child: Text('${u.fullName} (${u.mobile})'),
                        );
                      }).toList(),
                      onChanged: (u) {
                        setState(() {
                          _selectedUser = u;
                          _selectedBill = null;
                          _userBills = [];
                        });
                        if (u != null) _fetchUserBills(u.id);
                      },
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    if (_selectedUser != null) ...[
                      const Text(
                        'Select Pending Bill',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_isFetchingBills)
                        const Center(child: CircularProgressIndicator())
                      else if (_userBills.isEmpty)
                        const Text(
                          'No pending bills for this member',
                          style: TextStyle(color: Colors.red),
                        )
                      else
                        DropdownButtonFormField<MemberBill>(
                          value: _selectedBill,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Select a bill',
                          ),
                          items: _userBills.map((b) {
                            return DropdownMenuItem(
                              value: b,
                              child: Text(
                                '${b.billTitle ?? 'Bill'} - ₹${b.amount}',
                              ),
                            );
                          }).toList(),
                          onChanged: (b) {
                            setState(() {
                              _selectedBill = b;
                              if (b != null) {
                                _amountController.text = b.amount.toString();
                              }
                            });
                          },
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                    ],
                    const SizedBox(height: 24),
                    if (_selectedBill != null) ...[
                      const Divider(),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedMode,
                        decoration: const InputDecoration(
                          labelText: 'Payment Mode',
                          border: OutlineInputBorder(),
                        ),
                        items: ['CASH', 'CHEQUE', 'ONLINE']
                            .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedMode = v!),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _amountController,
                        label: 'Amount Received',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.currency_rupee,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _refController,
                        label: 'Reference No / Cheque No',
                        hint: 'Optional',
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _noteController,
                        label: 'Note',
                        maxLines: 2,
                        hint: 'Optional',
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        text: 'Record Payment',
                        isLoading: _isLoading,
                        onPressed: _markPayment,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
