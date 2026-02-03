import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/billing_payment_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class BillCreateScreen extends StatefulWidget {
  const BillCreateScreen({super.key});

  @override
  State<BillCreateScreen> createState() => _BillCreateScreenState();
}

class _BillCreateScreenState extends State<BillCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();

  final BillService _billService = BillService();
  DateTime? _selectedDueDate;
  String _selectedMonth = DateFormat('MMMM').format(DateTime.now());
  final String _selectedYear = DateTime.now().year.toString();
  bool _isLoading = false;

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
        _dueDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _createBill() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDueDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select due date')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await _billService.createBill({
        'title': _titleController.text,
        'amountTotal': double.parse(_amountController.text),
        'billType': 'MAINTENANCE',
        'description': 'Bill for $_selectedMonth $_selectedYear',
        'dueDate': _selectedDueDate!.toIso8601String(),
        'applyTo': 'ALL',
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill created successfully')),
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
      appBar: AppBar(title: const Text('Create Bill')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _titleController,
                label: 'Bill Title',
                hint: 'e.g. Maintenance Jan 2024',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedMonth,
                      decoration: const InputDecoration(
                        labelText: 'Month',
                        border: OutlineInputBorder(),
                      ),
                      items: _months
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedMonth = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: TextEditingController(text: _selectedYear),
                      label: 'Year',
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _amountController,
                label: 'Amount',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.currency_rupee,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: IgnorePointer(
                  child: AppTextField(
                    controller: _dueDateController,
                    label: 'Due Date',
                    prefixIcon: Icons.calendar_today,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Create Bill',
                isLoading: _isLoading,
                onPressed: _createBill,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
