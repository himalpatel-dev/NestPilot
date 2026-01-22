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
  final TextEditingController _regNumController = TextEditingController();

  final SocietyService _societyService = SocietyService();
  bool _isLoading = false;

  Future<void> _createSociety() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final success = await _societyService.createSociety(
        _nameController.text,
        _addressController.text,
        _regNumController.text.isNotEmpty ? _regNumController.text : null,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Society created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Society')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Society Name',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _addressController,
                label: 'Address',
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _regNumController,
                label: 'Registration Number (Optional)',
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
