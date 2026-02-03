import 'package:flutter/material.dart';
import '../../services/society_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class SocietyCreateScreen extends StatefulWidget {
  const SocietyCreateScreen({super.key});

  @override
  State<SocietyCreateScreen> createState() => _SocietyCreateScreenState();
}

class _SocietyCreateScreenState extends State<SocietyCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  String _selectedSocietyType = 'APARTMENT';
  final List<String> _societyTypes = [
    'APARTMENT',
    'TENEMENT',
    'ROW_HOUSE',
    'COMMERCIAL',
    'MIXED',
  ];

  final SocietyService _societyService = SocietyService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _createSociety() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final success = await _societyService.createSociety(
        name: _nameController.text,
        address: _addressController.text,
        city: _cityController.text,
        state: _stateController.text,
        pincode: _pincodeController.text,
        societyType: _selectedSocietyType,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Society created successfully')),
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
      appBar: AppBar(title: const Text('Add New Society')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Society Details',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: _nameController,
                label: 'Society Name',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedSocietyType,
                decoration: const InputDecoration(
                  labelText: 'Society Type',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                items: _societyTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSocietyType = val);
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _addressController,
                label: 'Address',
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _cityController,
                      label: 'City',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _pincodeController,
                      label: 'Pincode',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _stateController,
                label: 'State',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Create Society',
                isLoading: _isLoading,
                onPressed: _createSociety,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
