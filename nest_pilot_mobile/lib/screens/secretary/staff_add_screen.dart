import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import '../../services/permission_service.dart';
import '../../config/modules.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_field_card.dart';
import '../../widgets/no_permission_notice.dart';

class StaffAddScreen extends StatefulWidget {
  const StaffAddScreen({super.key});

  @override
  State<StaffAddScreen> createState() => _StaffAddScreenState();
}

class _StaffAddScreenState extends State<StaffAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();

  String _selectedRole = 'MAID';
  bool _isLoading = false;

  final List<String> _roles = [
    'MAID',
    'DRIVER',
    'COOK',
    'GARDENER',
    'SECURITY',
    'OTHER',
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = CommunityService();
      await service.addStaff({
        'name': _nameController.text,
        'mobile': _mobileController.text,
        'role': _selectedRole,
        'aadhaar_number': _aadhaarController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff added successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Daily Help')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Full Name',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _mobileController,
                label: 'Mobile Number',
                keyboardType: TextInputType.phone,
                validator: (v) => v!.length < 10 ? 'Invalid mobile' : null,
              ),
              const SizedBox(height: 16),
              AppFieldCard(
                icon: Icons.badge_rounded,
                label: 'Role',
                field: AppCardDropdown<String>(
                  value: _selectedRole,
                  hintText: 'Select role',
                  items: _roles,
                  itemLabel: (r) => r,
                  onChanged: (v) => setState(() => _selectedRole = v!),
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _aadhaarController,
                label: 'Aadhaar Number (Optional)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              if (PermissionService().canCreate(ModuleCodes.staff))
                AppButton(
                  text: 'Add Staff',
                  isLoading: _isLoading,
                  onPressed: _submit,
                )
              else
                const NoPermissionNotice(action: 'add staff members'),
            ],
          ),
        ),
      ),
    );
  }
}
