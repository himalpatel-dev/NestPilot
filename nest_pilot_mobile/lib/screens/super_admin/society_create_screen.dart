import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import '../../services/society_service.dart';
import '../../services/permission_service.dart';
import '../../config/modules.dart';
import '../../models/society_structure.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glare_button.dart';
import '../../widgets/no_permission_notice.dart';
import '../../widgets/society_icon.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/app_field_card.dart';

class SocietyCreateScreen extends StatefulWidget {
  /// Pass [society] to open in edit mode.
  final Society? society;

  const SocietyCreateScreen({super.key, this.society});

  bool get isEditing => society != null;

  @override
  State<SocietyCreateScreen> createState() => _SocietyCreateScreenState();
}

class _SocietyCreateScreenState extends State<SocietyCreateScreen> {
  static const Color _pageBg = AppColors.cardBackground;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;

  late String _selectedSocietyType;

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
  void initState() {
    super.initState();
    final s = widget.society;
    _nameController = TextEditingController(text: s?.name ?? '');
    _addressController = TextEditingController(text: s?.address ?? '');
    _cityController = TextEditingController(text: s?.city ?? '');
    _stateController = TextEditingController(text: s?.state ?? '');
    _pincodeController = TextEditingController(text: s?.pincode ?? '');
    _selectedSocietyType =
        (s != null && _societyTypes.contains(s.societyType))
            ? s.societyType
            : 'APARTMENT';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      bool success;
      if (widget.isEditing) {
        success = await _societyService.updateSociety(
          id: widget.society!.id,
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
          societyType: _selectedSocietyType,
        );
      } else {
        success = await _societyService.createSociety(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
          societyType: _selectedSocietyType,
        );
      }

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Society updated successfully'
                  : 'Society created successfully',
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Failed to update society'
                  : 'Failed to create society',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
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
          AppPageHeader(
            icon: const SocietyIcon(size: 28, color: AppColors.white),
            title: widget.isEditing ? 'Edit Society' : 'Add New Society',
            subtitle: widget.isEditing
                ? 'Update the details below'
                : 'Tell us about your new community',
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
                              maxLength: 6,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (v) {
                                final val = (v ?? '').trim();
                                if (val.isEmpty) return 'Required';
                                if (val.length != 6) return '6 digits required';
                                return null;
                              },
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
                    if (widget.isEditing
                        ? PermissionService().canUpdate(ModuleCodes.buildings)
                        : PermissionService().canCreate(ModuleCodes.buildings))
                      GlarePrimaryButton(
                        text: widget.isEditing
                            ? 'Save Society'
                            : 'Create Society',
                        trailingIcon: Icons.arrow_forward_rounded,
                        isLoading: _isLoading,
                        onPressed: _save,
                        showGlare: false,
                      )
                    else
                      NoPermissionNotice(
                        action: widget.isEditing
                            ? 'update societies'
                            : 'create societies',
                      ),
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
