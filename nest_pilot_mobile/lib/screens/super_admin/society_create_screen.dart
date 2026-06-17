import 'package:flutter/material.dart';
import '../../services/society_service.dart';
import '../../services/permission_service.dart';
import '../../config/modules.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glare_button.dart';
import '../../widgets/no_permission_notice.dart';
import '../../widgets/society_icon.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/app_field_card.dart';

class SocietyCreateScreen extends StatefulWidget {
  const SocietyCreateScreen({super.key});

  @override
  State<SocietyCreateScreen> createState() => _SocietyCreateScreenState();
}

class _SocietyCreateScreenState extends State<SocietyCreateScreen> {
  static const Color _pageBg = AppColors.cardBackground;

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
      backgroundColor: _pageBg,
      body: Column(
        children: [
          const AppPageHeader(
            icon: SocietyIcon(size: 28, color: AppColors.white),
            title: 'Add New Society',
            subtitle: 'Tell us about your new community',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppSectionHeader('Basic Information'),
                    const SizedBox(height: 12),
                    AppFieldCard(
                      icon: Icons.apartment_rounded,
                      label: 'Society Name',
                      field: AppBorderlessField(
                        controller: _nameController,
                        hint: 'e.g. Kesharkunj Residency',
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppFieldCard(
                      icon: Icons.map_outlined,
                      label: 'Society Type',
                      field: AppCardDropdown<String>(
                        value: _selectedSocietyType,
                        items: _societyTypes,
                        itemLabel: (type) => type.replaceAll('_', ' '),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedSocietyType = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    const AppSectionHeader('Location'),
                    const SizedBox(height: 12),
                    AppFieldCard(
                      icon: Icons.place_outlined,
                      label: 'Address',
                      iconAlignment: CrossAxisAlignment.start,
                      field: AppBorderlessField(
                        controller: _addressController,
                        hint: 'Street, area',
                        maxLines: 3,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppFieldCard(
                            icon: Icons.location_city_outlined,
                            label: 'City',
                            field: AppBorderlessField(
                              controller: _cityController,
                              hint: 'City',
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: AppFieldCard(
                            icon: Icons.tag_rounded,
                            label: 'Pincode',
                            field: AppBorderlessField(
                              controller: _pincodeController,
                              hint: '000000',
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AppFieldCard(
                      icon: Icons.public_rounded,
                      label: 'State',
                      field: AppBorderlessField(
                        controller: _stateController,
                        hint: 'State',
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (PermissionService().canCreate(ModuleCodes.buildings))
                      GlarePrimaryButton(
                        text: 'Create Society',
                        trailingIcon: Icons.arrow_forward_rounded,
                        isLoading: _isLoading,
                        onPressed: _createSociety,
                        showGlare: false,
                      )
                    else
                      const NoPermissionNotice(action: 'create societies'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
