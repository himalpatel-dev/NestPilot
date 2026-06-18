import 'package:flutter/material.dart';
import '../../theme/nest_loader.dart';
import '../../services/billing_payment_service.dart';
import '../../services/admin_service.dart';
import '../../services/permission_service.dart';
import '../../config/modules.dart';
import '../../models/user_model.dart';
import '../../models/billing_payment.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_field_card.dart';
import '../../widgets/status_widgets.dart';
import '../../widgets/no_permission_notice.dart';

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
                    AppFieldCard(
                      icon: Icons.person_rounded,
                      label: 'Select Member',
                      field: AppCardDropdown<UserModel>(
                        value: _selectedUser,
                        hintText: 'Select a member',
                        items: _members,
                        itemLabel: (u) => '${u.fullName} (${u.mobile})',
                        validator: (v) => v == null ? 'Required' : null,
                        onChanged: (u) {
                          setState(() {
                            _selectedUser = u;
                            _selectedBill = null;
                            _userBills = [];
                          });
                          if (u != null) _fetchUserBills(u.id);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_selectedUser != null) ...[
                      if (_isFetchingBills)
                        const Center(child: NestLoader())
                      else if (_userBills.isEmpty)
                        const Text(
                          'No pending bills for this member',
                          style: TextStyle(color: Colors.red),
                        )
                      else
                        AppFieldCard(
                          icon: Icons.receipt_long_rounded,
                          label: 'Select Pending Bill',
                          field: AppCardDropdown<MemberBill>(
                            value: _selectedBill,
                            hintText: 'Select a bill',
                            items: _userBills,
                            itemLabel: (b) =>
                                '${b.billTitle ?? 'Bill'} - ₹${b.amount}',
                            validator: (v) => v == null ? 'Required' : null,
                            onChanged: (b) {
                              setState(() {
                                _selectedBill = b;
                                if (b != null) {
                                  _amountController.text =
                                      b.amount.toString();
                                }
                              });
                            },
                          ),
                        ),
                    ],
                    const SizedBox(height: 24),
                    if (_selectedBill != null) ...[
                      const Divider(),
                      const SizedBox(height: 16),
                      AppFieldCard(
                        icon: Icons.payments_rounded,
                        label: 'Payment Mode',
                        field: AppCardDropdown<String>(
                          value: _selectedMode,
                          hintText: 'Select payment mode',
                          items: const ['CASH', 'CHEQUE', 'ONLINE'],
                          itemLabel: (m) => m,
                          onChanged: (v) =>
                              setState(() => _selectedMode = v!),
                        ),
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
                      if (PermissionService().canUpdate(ModuleCodes.bills))
                        AppButton(
                          text: 'Record Payment',
                          isLoading: _isLoading,
                          onPressed: _markPayment,
                        )
                      else
                        const NoPermissionNotice(action: 'record payments'),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
