import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/modules.dart';
import '../../models/billing_payment.dart';
import '../../services/billing_payment_service.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_field_card.dart';
import '../../widgets/app_form_sheet.dart';
import '../../widgets/glare_button.dart';
import '../../widgets/no_permission_notice.dart';

/// Opens the bill form. Pass [editing] to edit an existing draft instead of
/// creating a new bill — [onCreated] fires on a successful save either way.
Future<void> showCreateBillSheet(
  BuildContext context, {
  VoidCallback? onCreated,
  Bill? editing,
}) {
  return showAppFormSheet(
    context: context,
    builder: (ctx) =>
        _CreateBillSheetContent(onCreated: onCreated, editing: editing),
  );
}

class _CreateBillSheetContent extends StatefulWidget {
  final VoidCallback? onCreated;
  final Bill? editing;
  const _CreateBillSheetContent({this.onCreated, this.editing});

  @override
  State<_CreateBillSheetContent> createState() =>
      _CreateBillSheetContentState();
}

class _CreateBillSheetContentState extends State<_CreateBillSheetContent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final BillService _billService = BillService();
  DateTime? _selectedDueDate;
  String _selectedBillType = 'MAINTENANCE';
  bool _isLoading = false;
  bool _dateErr = false;

  // Inline error state — modal sheets hide snackbars behind them, so API
  // failures are surfaced in the sheet instead.
  String? _apiError;

  /// Keys must stay in step with the bill_type enum in bill.model.js —
  /// anything not in that enum is rejected by Postgres on save.
  static const Map<String, String> _billTypes = {
    'MAINTENANCE': 'Maintenance',
    'UTILITY': 'Utility',
    'SPECIAL': 'Special Assessment',
    'EVENT': 'Event Fee',
    'OTHER': 'Other',
  };

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final bill = widget.editing;
    if (bill != null) {
      _titleController.text = bill.title;
      _amountController.text = bill.amountTotal % 1 == 0
          ? bill.amountTotal.toStringAsFixed(0)
          : bill.amountTotal.toString();
      _descriptionController.text = bill.description ?? '';
      _selectedBillType = bill.billType;
      _selectedDueDate = bill.dueDate;
      return;
    }

    _selectedDueDate = DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial =
        _selectedDueDate ?? DateTime.now().add(const Duration(days: 7));
    // An existing draft may already carry a due date in the past — the picker
    // asserts if that falls before firstDate, so open the range wide enough.
    final firstDate = initial.isBefore(DateTime.now())
        ? initial
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: appPickerTheme,
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
        _dateErr = false;
      });
    }
  }

  Future<void> _submit() async {
    final validForm = _formKey.currentState!.validate();
    final hasDate = _selectedDueDate != null;
    setState(() => _dateErr = !hasDate);
    if (!validForm || !hasDate) return;

    setState(() {
      _isLoading = true;
      _apiError = null;
    });
    try {
      final payload = {
        'title': _titleController.text.trim(),
        'amountTotal': double.parse(_amountController.text.trim()),
        'billType': _selectedBillType,
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : 'Bill for ${DateFormat('MMMM yyyy').format(DateTime.now())}',
        'dueDate': _selectedDueDate!.toIso8601String(),
        'applyTo': 'ALL',
      };

      final success = _isEditing
          ? await _billService.updateBill(widget.editing!.id, payload)
          : await _billService.createBill(payload);

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Bill updated successfully'
                  : 'Bill created successfully',
            ),
            backgroundColor: AppColors.accentGreen,
          ),
        );
        widget.onCreated?.call();
        return;
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _apiError = e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final canManage = PermissionService().canManage(ModuleCodes.bills);

    return AppFormSheet(
      accentColor: ModuleColors.bills,
      icon: _isEditing ? Icons.edit_rounded : Icons.receipt_long_rounded,
      title: _isEditing ? 'Edit Bill' : 'New Bill',
      child: !canManage
          ? NoPermissionNotice(
              action: _isEditing ? 'edit bills' : 'create bills',
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSectionHeader('Bill Details'),
                  const SizedBox(height: 14),
                  AppFieldCard(
                    icon: Icons.title_rounded,
                    label: 'Title',
                    field: AppBorderlessField(
                      controller: _titleController,
                      hint: 'e.g. Maintenance Charges — August 2026',
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Title is required'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppFieldCard(
                    icon: Icons.category_outlined,
                    label: 'Bill Category',
                    field: AppCardDropdown<String>(
                      value: _selectedBillType,
                      items: _billTypes.keys.toList(),
                      itemLabel: (code) => _billTypes[code] ?? code,
                      onChanged: (v) => setState(() => _selectedBillType = v!),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppFieldCard(
                    icon: Icons.description_outlined,
                    label: 'Description',
                    iconAlignment: CrossAxisAlignment.start,
                    field: AppBorderlessField(
                      controller: _descriptionController,
                      hint: 'Optional notes shown to residents…',
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const AppSectionHeader('Amount & Due Date'),
                  const SizedBox(height: 14),
                  AppFieldCard(
                    icon: Icons.currency_rupee_rounded,
                    label: 'Amount',
                    field: AppBorderlessField(
                      controller: _amountController,
                      hint: 'e.g. 2500',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Amount is required';
                        }
                        final amount = double.tryParse(v.trim());
                        if (amount == null) return 'Enter a valid amount';
                        if (amount <= 0) return 'Amount must be more than 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppPickerCard(
                    icon: Icons.calendar_month_rounded,
                    label: 'Due Date',
                    value: _selectedDueDate != null
                        ? DateFormat(
                            'EEE, d MMM yyyy',
                          ).format(_selectedDueDate!)
                        : null,
                    hint: 'Select due date',
                    error: _dateErr,
                    onTap: _pickDate,
                  ),
                  if (_apiError != null) ...[
                    const SizedBox(height: 18),
                    AppSheetErrorBanner(_apiError!),
                  ],
                  const SizedBox(height: 26),
                  GlarePrimaryButton(
                    text: _isEditing ? 'Save Changes' : 'Generate Bill',
                    trailingIcon: Icons.check_rounded,
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
    );
  }
}
