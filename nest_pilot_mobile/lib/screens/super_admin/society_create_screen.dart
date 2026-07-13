import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import '../../services/society_service.dart';
import '../../services/location_service.dart';
import '../../services/permission_service.dart';
import '../../config/modules.dart';
import '../../models/society_structure.dart';
import '../../models/location_model.dart';
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
  late final TextEditingController _pincodeController;

  late String _selectedSocietyType;

  final LocationService _locationService = LocationService();
  List<StateModel> _states = [];
  StateModel? _selectedState;
  bool _isLoadingStates = true;

  List<DistrictModel> _districts = [];
  DistrictModel? _selectedDistrict;
  bool _isLoadingDistricts = false;

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
    _pincodeController = TextEditingController(text: s?.pincode ?? '');
    _selectedSocietyType =
        (s != null && _societyTypes.contains(s.societyType))
            ? s.societyType
            : 'APARTMENT';

    _loadStates();
  }

  /// Loads all states; in edit mode preselects the society's saved state and
  /// then loads + preselects its saved district.
  Future<void> _loadStates() async {
    try {
      final states = await _locationService.getStates();
      if (!mounted) return;

      StateModel? preselect;
      final existing = widget.society?.state?.trim();
      if (existing != null && existing.isNotEmpty) {
        for (final st in states) {
          if (st.name.toLowerCase() == existing.toLowerCase()) {
            preselect = st;
            break;
          }
        }
      }

      setState(() {
        _states = states;
        _selectedState = preselect;
        _isLoadingStates = false;
      });

      if (preselect != null) {
        await _loadDistricts(
          preselect.id,
          preselectName: widget.society?.district,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingStates = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load states: $e')),
      );
    }
  }

  /// Loads districts for [stateId]; optionally preselects one by name.
  Future<void> _loadDistricts(int stateId, {String? preselectName}) async {
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
    });
    try {
      final districts = await _locationService.getDistricts(stateId);
      if (!mounted) return;

      DistrictModel? preselect;
      final target = preselectName?.trim();
      if (target != null && target.isNotEmpty) {
        for (final d in districts) {
          if (d.name.toLowerCase() == target.toLowerCase()) {
            preselect = d;
            break;
          }
        }
      }

      setState(() {
        _districts = districts;
        _selectedDistrict = preselect;
        _isLoadingDistricts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingDistricts = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load districts: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
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
          state: _selectedState!.name,
          district: _selectedDistrict?.name,
          pincode: _pincodeController.text.trim(),
          societyType: _selectedSocietyType,
        );
      } else {
        success = await _societyService.createSociety(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          state: _selectedState!.name,
          district: _selectedDistrict?.name,
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
            iconWidget: const SocietyIcon(size: 28, color: AppColors.white),
            title: widget.isEditing ? 'Edit Society' : 'Add New Society',
            accentColor: ModuleColors.buildings,
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
                    AppFieldCard(
                      icon: Icons.public_rounded,
                      label: 'State',
                      field: AppCardDropdown<StateModel>(
                        value: _selectedState,
                        items: _states,
                        enabled: !_isLoadingStates,
                        hintText:
                            _isLoadingStates ? 'Loading states…' : 'Select state',
                        itemLabel: (st) => st.name,
                        onChanged: (StateModel? val) {
                          if (val == null || val == _selectedState) return;
                          setState(() {
                            _selectedState = val;
                            _selectedDistrict = null;
                            _districts = [];
                          });
                          _loadDistricts(val.id);
                        },
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppFieldCard(
                      icon: Icons.map_outlined,
                      label: 'District',
                      field: AppCardDropdown<DistrictModel>(
                        value: _selectedDistrict,
                        items: _districts,
                        enabled: _selectedState != null && !_isLoadingDistricts,
                        hintText: _selectedState == null
                            ? 'Select a state first'
                            : (_isLoadingDistricts
                                ? 'Loading districts…'
                                : 'Select district'),
                        itemLabel: (d) => d.name,
                        onChanged: (DistrictModel? val) {
                          setState(() => _selectedDistrict = val);
                        },
                        validator: (v) => v == null ? 'Required' : null,
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
                    const SizedBox(height: 28),
                    if (PermissionService().canManage(ModuleCodes.buildings))
                      GlarePrimaryButton(
                        text: widget.isEditing
                            ? 'Save Society'
                            : 'Create Society',
                        trailingIcon: Icons.arrow_forward_rounded,
                        isLoading: _isLoading,
                        onPressed: _save,
                        showGlare: true,
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
