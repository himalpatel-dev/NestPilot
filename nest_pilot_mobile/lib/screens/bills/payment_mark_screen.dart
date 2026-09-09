import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/modules.dart';
import '../../models/billing_payment.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../services/billing_payment_service.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/nest_loader.dart';
import '../../widgets/app_field_card.dart';
import '../../widgets/app_form_sheet.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/glare_button.dart';
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
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isFetchingMembers = true;
  bool _isFetchingBills = false;

  // A failed load here (most often a 403 from the USERS-view permission gate)
  // is indistinguishable from an empty society unless it is surfaced.
  String? _membersError;
  String? _billsError;

  static const Map<String, ({String label, IconData icon})> _modes = {
    'CASH': (label: 'Cash', icon: Icons.payments_rounded),
    'CHEQUE': (label: 'Cheque', icon: Icons.receipt_long_rounded),
    'ONLINE': (label: 'Online', icon: Icons.account_balance_rounded),
  };

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchMembers() async {
    setState(() {
      _isFetchingMembers = true;
      _membersError = null;
    });
    try {
      final members = await _adminService.getMembersLookup();
      if (!mounted) return;
      setState(() {
        _members = members;
        _isFetchingMembers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _membersError = e.toString().replaceFirst('Exception: ', '');
        _isFetchingMembers = false;
      });
    }
  }

  Future<void> _fetchUserBills(String userId) async {
    setState(() {
      _isFetchingBills = true;
      _billsError = null;
    });
    try {
      final bills = await _billService.getUserBills(userId);
      if (!mounted) return;
      setState(() {
        _userBills = bills.where((b) => b.status != 'PAID').toList();
        _isFetchingBills = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _billsError = e.toString().replaceFirst('Exception: ', '');
        _isFetchingBills = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      // Offline payments get entered after the fact, but never ahead of time.
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: appPickerTheme,
    );
    if (picked != null) setState(() => _selectedDate = picked);
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
        'amount': double.parse(_amountController.text.trim()),
        'paymentMode': _selectedMode,
        'paymentDate': _selectedDate.toIso8601String(),
        'referenceNo': _refController.text.trim(),
        'note': _noteController.text.trim(),
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded successfully'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _money(double value) => NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: value % 1 == 0 ? 0 : 2,
  ).format(value);

  /// Plain number for a text field — no symbol, no trailing ".0".
  String _plain(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();

  Color _statusColor(String status) {
    switch (status) {
      case 'PAID':
        return AppColors.accentGreen;
      case 'OVERDUE':
        return AppColors.accentRed;
      case 'PARTIAL':
        return AppColors.accentAmber;
      default:
        return AppColors.accentBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Column(
        children: [
          AppPageHeader(
            icon: Icons.payments_outlined,
            title: 'Record Payment',
            subtitle: 'Log a cash, cheque or online payment received offline',
            accentColor: ModuleColors.bills,
          ),

          // Sits outside the scroll view so the gap under the fixed header
          // survives scrolling instead of collapsing with the content.
          const SizedBox(height: 14),

          Expanded(
            child: _isFetchingMembers
                ? const Center(child: NestLoader())
                : _membersError != null
                ? _loadFailed(_membersError!)
                : _members.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: _notice(
                      icon: Icons.people_outline_rounded,
                      color: AppColors.accentAmber,
                      message:
                          'No active members found in this society, so there '
                          'is nobody to record a payment against.',
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad + 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppSectionHeader('Member & Bill'),
                          const SizedBox(height: 14),
                          AppFieldCard(
                            icon: Icons.person_rounded,
                            label: 'Member',
                            field: AppCardDropdown<UserModel>(
                              value: _selectedUser,
                              hintText: 'Select a member',
                              items: _members,
                              itemLabel: (u) =>
                                  u.flatNumber != null &&
                                      u.flatNumber!.isNotEmpty
                                  ? '${u.fullName} · ${u.flatNumber}'
                                  : '${u.fullName} (${u.mobile})',
                              validator: (v) => v == null ? 'Required' : null,
                              onChanged: (u) {
                                setState(() {
                                  _selectedUser = u;
                                  _selectedBill = null;
                                  _userBills = [];
                                  _amountController.clear();
                                });
                                if (u != null) _fetchUserBills(u.id);
                              },
                            ),
                          ),
                          if (_selectedUser != null) ...[
                            const SizedBox(height: 12),
                            if (_isFetchingBills)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(child: NestLoader()),
                              )
                            else if (_billsError != null)
                              _notice(
                                icon: Icons.error_outline_rounded,
                                color: AppColors.accentRed,
                                message:
                                    "Couldn't load this member's bills. "
                                    '$_billsError',
                              )
                            else if (_userBills.isEmpty)
                              _notice(
                                icon: Icons.check_circle_outline_rounded,
                                color: AppColors.accentGreen,
                                message:
                                    'This member has no pending bills — '
                                    'nothing to record right now.',
                              )
                            else
                              AppFieldCard(
                                icon: Icons.receipt_long_rounded,
                                label: 'Pending Bill',
                                field: AppCardDropdown<MemberBill>(
                                  value: _selectedBill,
                                  hintText: 'Select a bill',
                                  items: _userBills,
                                  itemLabel: (b) =>
                                      '${b.billTitle ?? 'Bill'} · '
                                      '${_money(b.amount + b.penaltyAmount)}',
                                  validator: (v) =>
                                      v == null ? 'Required' : null,
                                  onChanged: (b) {
                                    setState(() {
                                      _selectedBill = b;
                                      if (b != null) {
                                        _amountController.text = _plain(
                                          b.amount + b.penaltyAmount,
                                        );
                                      }
                                    });
                                  },
                                ),
                              ),
                          ],
                          if (_selectedBill != null) ...[
                            const SizedBox(height: 12),
                            _billSummary(_selectedBill!),
                            const SizedBox(height: 24),
                            const AppSectionHeader('Payment'),
                            const SizedBox(height: 14),
                            _modeSelector(),
                            const SizedBox(height: 12),
                            AppFieldCard(
                              icon: Icons.currency_rupee_rounded,
                              label: 'Amount Received',
                              field: AppBorderlessField(
                                controller: _amountController,
                                hint: 'e.g. 2500',
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Amount is required';
                                  }
                                  final amount = double.tryParse(v.trim());
                                  if (amount == null) {
                                    return 'Enter a valid amount';
                                  }
                                  if (amount <= 0) {
                                    return 'Amount must be more than 0';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            AppPickerCard(
                              icon: Icons.calendar_month_rounded,
                              label: 'Payment Date',
                              value: DateFormat(
                                'EEE, d MMM yyyy',
                              ).format(_selectedDate),
                              hint: 'Select payment date',
                              onTap: _pickDate,
                            ),
                            const SizedBox(height: 12),
                            AppFieldCard(
                              icon: Icons.tag_rounded,
                              label: 'Reference / Cheque No',
                              field: AppBorderlessField(
                                controller: _refController,
                                hint: 'Optional',
                              ),
                            ),
                            const SizedBox(height: 12),
                            AppFieldCard(
                              icon: Icons.notes_rounded,
                              label: 'Note',
                              iconAlignment: CrossAxisAlignment.start,
                              field: AppBorderlessField(
                                controller: _noteController,
                                hint: 'Optional',
                                maxLines: 2,
                              ),
                            ),
                            const SizedBox(height: 26),
                            if (PermissionService().canManage(
                              ModuleCodes.bills,
                            ))
                              GlarePrimaryButton(
                                text: 'Record Payment',
                                trailingIcon: Icons.check_rounded,
                                isLoading: _isLoading,
                                onPressed: _markPayment,
                              )
                            else
                              const NoPermissionNotice(
                                action: 'record payments',
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Outstanding at a glance, so the amount above can be checked against what
  /// the bill actually owes before it is recorded.
  Widget _billSummary(MemberBill bill) {
    final statusColor = _statusColor(bill.status);
    final outstanding = bill.amount + bill.penaltyAmount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  bill.billTitle ?? 'Bill',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.30),
                  ),
                ),
                child: Text(
                  bill.status,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _summaryCell(
                  'OUTSTANDING',
                  _money(outstanding),
                  AppColors.textPrimary,
                ),
              ),
              Container(width: 1, height: 34, color: AppColors.border),
              Expanded(
                child: _summaryCell(
                  'DUE DATE',
                  DateFormat('dd MMM yyyy').format(bill.dueDate),
                  AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (bill.penaltyAmount > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 15,
                  color: AppColors.accentRed,
                ),
                const SizedBox(width: 6),
                Text(
                  'Includes ${_money(bill.penaltyAmount)} late penalty',
                  style: const TextStyle(
                    color: AppColors.accentRed,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryCell(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _modeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'PAYMENT MODE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Row(
          children: [
            for (final entry in _modes.entries) ...[
              if (entry.key != _modes.keys.first) const SizedBox(width: 10),
              Expanded(
                child: _modeOption(
                  code: entry.key,
                  label: entry.value.label,
                  icon: entry.value.icon,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _modeOption({
    required String code,
    required String label,
    required IconData icon,
  }) {
    final selected = _selectedMode == code;
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.white : AppColors.primary,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.white : AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shown when the member list can't be loaded at all — without this the
  /// screen renders an empty picker and looks like the society has no members.
  Widget _loadFailed(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.accentRed,
            ),
            const SizedBox(height: 14),
            const Text(
              "Couldn't load members",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 160,
              child: GlarePrimaryButton(
                text: 'Retry',
                trailingIcon: Icons.refresh_rounded,
                onPressed: _fetchMembers,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notice({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
