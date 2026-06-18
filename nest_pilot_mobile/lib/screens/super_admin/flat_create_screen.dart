import 'package:flutter/material.dart';
import '../../theme/nest_loader.dart';
import '../../services/society_service.dart';
import '../../services/permission_service.dart';
import '../../config/modules.dart';
import '../../models/society_structure.dart';
import '../../widgets/glare_button.dart';
import '../../widgets/no_permission_notice.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/app_field_card.dart';
import '../../theme/app_colors.dart';

class FlatCreateScreen extends StatefulWidget {
  const FlatCreateScreen({super.key});

  @override
  State<FlatCreateScreen> createState() => _FlatCreateScreenState();
}

class _FlatCreateScreenState extends State<FlatCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _floorController = TextEditingController(
    text: '0',
  );
  final TextEditingController _wingController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();

  final SocietyService _societyService = SocietyService();

  List<Society> _societies = [];
  List<Building> _buildings = [];

  Society? _selectedSociety;
  Building? _selectedBuilding;
  String _selectedUnitType = 'FLAT';

  bool _isLoadingSocieties = true;
  bool _isLoadingBuildings = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSocieties();
  }

  @override
  void dispose() {
    _numberController.dispose();
    _floorController.dispose();
    _wingController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _loadSocieties() async {
    try {
      final list = await _societyService.getSocieties();
      setState(() {
        _societies = list;
        _isLoadingSocieties = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load societies: $e')));
      }
      setState(() => _isLoadingSocieties = false);
    }
  }

  Future<void> _loadBuildings(String societyId) async {
    setState(() {
      _isLoadingBuildings = true;
      _buildings = [];
      _selectedBuilding = null;
    });

    try {
      final list = await _societyService.getBuildings(societyId);
      setState(() {
        _buildings = list;
        _isLoadingBuildings = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load buildings/sectors: $e')),
        );
      }
      setState(() => _isLoadingBuildings = false);
    }
  }

  Future<void> _saveFlat() async {
    if (_selectedSociety == null || _selectedBuilding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select society and building/sector'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final double? area = double.tryParse(_areaController.text.trim());

      final bool success = await _societyService.createFlat(
        buildingId: _selectedBuilding!.id,
        number: _numberController.text.trim(),
        floor: int.tryParse(_floorController.text.trim()) ?? 0,
        wing: _wingController.text.trim().isNotEmpty
            ? _wingController.text.trim()
            : null,
        unitType: _selectedUnitType,
        areaSqft: area,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flat/Unit created successfully')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create flat/unit')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String societyType = _selectedSociety?.societyType ?? 'APARTMENT';
    final bool isRowHouse =
        societyType == 'ROW_HOUSE' || societyType == 'TENEMENT';
    final bool isCommercial = societyType == 'COMMERCIAL';

    // Set appropriate dynamic labels
    String unitLabel = 'Flat / Unit Number';
    if (isRowHouse) unitLabel = 'House Number (e.g. A-10, B-5)';
    if (isCommercial) unitLabel = 'Shop / Office Number';

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Column(
        children: [
          const AppPageHeader(
            icon: Icon(
              Icons.door_front_door_rounded,
              color: AppColors.white,
              size: 28,
            ),
            title: 'Add Flat / Unit',
            subtitle: 'Add a flat, house, shop or office to a building',
          ),
          Expanded(
            child: _isLoadingSocieties
                ? const Center(child: NestLoader())
                : _societies.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.door_front_door_outlined,
                            size: 64,
                            color: AppColors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Societies Available',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please onboard a society and create buildings first.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AppSectionHeader('Select Society & Building'),
                          const SizedBox(height: 12),
                          AppFieldCard(
                            icon: Icons.apartment_rounded,
                            label: 'Society',
                            field: AppCardDropdown<Society>(
                              value: _selectedSociety,
                              hint: const Text(
                                'Choose Society',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textHint,
                                ),
                              ),
                              items: _societies,
                              itemLabel: (soc) => soc.name,
                              onChanged: (Society? value) {
                                setState(() {
                                  _selectedSociety = value;
                                  _selectedBuilding = null;
                                  if (value != null) {
                                    _loadBuildings(value.id);
                                    // Adjust default unit types
                                    if (value.societyType == 'ROW_HOUSE') {
                                      _selectedUnitType = 'ROW_HOUSE';
                                    } else if (value.societyType ==
                                        'TENEMENT') {
                                      _selectedUnitType =
                                          'ROW_HOUSE'; // maps to row house / tenement
                                    } else if (value.societyType ==
                                        'COMMERCIAL') {
                                      _selectedUnitType = 'SHOP';
                                    } else {
                                      _selectedUnitType = 'FLAT';
                                    }
                                    _wingController.clear();
                                    _floorController.text = '0';
                                  }
                                });
                              },
                            ),
                          ),
                          if (_selectedSociety != null) ...[
                            const SizedBox(height: 14),
                            if (_isLoadingBuildings)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: NestLoader(size: 32, showDots: false),
                                ),
                              )
                            else if (_buildings.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                  ),
                                  child: Text(
                                    isRowHouse
                                        ? 'No sectors/lanes created for this society yet.'
                                        : 'No buildings/blocks created for this society yet.',
                                    style: const TextStyle(
                                      color: AppColors.accentRed,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              )
                            else
                              AppFieldCard(
                                icon: Icons.business_rounded,
                                label: isRowHouse
                                    ? 'Sector / Lane'
                                    : 'Building / Block',
                                field: AppCardDropdown<Building>(
                                  value: _selectedBuilding,
                                  hint: Text(
                                    isRowHouse
                                        ? 'Choose Sector / Lane'
                                        : 'Choose Building / Block',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                  items: _buildings,
                                  itemLabel: (bld) => bld.name,
                                  onChanged: (Building? value) {
                                    setState(() {
                                      _selectedBuilding = value;
                                    });
                                  },
                                ),
                              ),
                          ],
                          const SizedBox(height: 24),
                          if (_selectedSociety != null &&
                              _selectedBuilding != null) ...[
                            const AppSectionHeader('Unit Configuration'),
                            const SizedBox(height: 12),
                            AppFieldCard(
                              icon: Icons.tag,
                              label: unitLabel,
                              field: AppBorderlessField(
                                controller: _numberController,
                                hint: 'e.g. 101, A-10',
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 14),
                            AppFieldCard(
                              icon: Icons.home_work_rounded,
                              label: 'Unit Type',
                              field: AppCardDropdown<String>(
                                value: _selectedUnitType,
                                items: [
                                  if (!isCommercial && !isRowHouse) 'FLAT',
                                  if (isRowHouse) ...['ROW_HOUSE', 'VILLA'],
                                  if (isCommercial || societyType == 'MIXED')
                                    ...['SHOP', 'OFFICE'],
                                ],
                                itemLabel: (type) {
                                  switch (type) {
                                    case 'FLAT':
                                      return 'Flat / Apartment';
                                    case 'ROW_HOUSE':
                                      return 'Row House';
                                    case 'VILLA':
                                      return 'Villa';
                                    case 'SHOP':
                                      return 'Shop';
                                    case 'OFFICE':
                                      return 'Office';
                                    default:
                                      return type;
                                  }
                                },
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedUnitType = val);
                                  }
                                },
                              ),
                            ),
                            if (!isRowHouse) ...[
                              const SizedBox(height: 14),
                              AppFieldCard(
                                icon: Icons.layers_outlined,
                                label: 'Floor Number',
                                field: AppBorderlessField(
                                  controller: _floorController,
                                  hint: '0',
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final val = int.tryParse(v.trim());
                                    if (val == null) {
                                      return 'Enter a valid number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                            if (societyType == 'APARTMENT' ||
                                societyType == 'MIXED') ...[
                              const SizedBox(height: 14),
                              AppFieldCard(
                                icon: Icons.grid_view_outlined,
                                label: 'Wing / Block (optional)',
                                field: AppBorderlessField(
                                  controller: _wingController,
                                  hint: 'e.g. A, B',
                                  validator: (_) => null,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            AppFieldCard(
                              icon: Icons.square_foot_outlined,
                              label: 'Area in Sq. Ft. (optional)',
                              field: AppBorderlessField(
                                controller: _areaController,
                                hint: 'e.g. 1200',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (v) {
                                  if (v != null && v.trim().isNotEmpty) {
                                    final val = double.tryParse(v.trim());
                                    if (val == null || val <= 0) {
                                      return 'Enter a valid area';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 32),
                            if (PermissionService().canCreate(
                              ModuleCodes.buildings,
                            ))
                              GlarePrimaryButton(
                                text: 'Add Flat / Unit',
                                trailingIcon: Icons.arrow_forward_rounded,
                                isLoading: _isSaving,
                                onPressed: _saveFlat,
                                showGlare: false,
                              )
                            else
                              const NoPermissionNotice(
                                action: 'create flats / units',
                              ),
                          ] else ...[
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40,
                                ),
                                child: Text(
                                  'Select society and building/sector above to configure unit details.',
                                  style: TextStyle(
                                    color: AppColors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
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
}
