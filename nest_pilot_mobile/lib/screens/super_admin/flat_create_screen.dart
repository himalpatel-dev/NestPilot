import 'package:flutter/material.dart';
import '../../theme/nest_loader.dart';
import '../../services/society_service.dart';
import '../../models/society_structure.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class FlatCreateScreen extends StatefulWidget {
  const FlatCreateScreen({super.key});

  @override
  State<FlatCreateScreen> createState() => _FlatCreateScreenState();
}

class _FlatCreateScreenState extends State<FlatCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _floorController = TextEditingController(text: '0');
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load societies: $e')),
        );
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
        const SnackBar(content: Text('Please select society and building/sector')),
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
        wing: _wingController.text.trim().isNotEmpty ? _wingController.text.trim() : null,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String societyType = _selectedSociety?.societyType ?? 'APARTMENT';
    final bool isRowHouse = societyType == 'ROW_HOUSE' || societyType == 'TENEMENT';
    final bool isCommercial = societyType == 'COMMERCIAL';

    // Set appropriate dynamic labels
    String unitLabel = 'Flat / Unit Number';
    if (isRowHouse) unitLabel = 'House Number (e.g. A-10, B-5)';
    if (isCommercial) unitLabel = 'Shop / Office Number';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Flat / Unit'),
        elevation: 0,
      ),
      body: _isLoadingSocieties
          ? const Center(child: NestLoader())
          : _societies.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.door_front_door_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No Societies Available',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please onboarding a society and create buildings first.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
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
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select Society & Building',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<Society>(
                                  value: _selectedSociety,
                                  hint: const Text('Choose Society'),
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    fillColor: Colors.grey.shade50,
                                    filled: true,
                                  ),
                                  items: _societies.map((soc) {
                                    return DropdownMenuItem<Society>(
                                      value: soc,
                                      child: Text(soc.name),
                                    );
                                  }).toList(),
                                  onChanged: (Society? value) {
                                    setState(() {
                                      _selectedSociety = value;
                                      _selectedBuilding = null;
                                      if (value != null) {
                                        _loadBuildings(value.id);
                                        // Adjust default unit types
                                        if (value.societyType == 'ROW_HOUSE') {
                                          _selectedUnitType = 'ROW_HOUSE';
                                        } else if (value.societyType == 'TENEMENT') {
                                          _selectedUnitType = 'ROW_HOUSE'; // maps to row house / tenement
                                        } else if (value.societyType == 'COMMERCIAL') {
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
                                const SizedBox(height: 16),
                                if (_selectedSociety != null) ...[
                                  _isLoadingBuildings
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(vertical: 8.0),
                                            child: NestLoader(size: 32, showDots: false),
                                          ),
                                        )
                                      : _buildings.isEmpty
                                          ? Center(
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                                child: Text(
                                                  isRowHouse
                                                      ? 'No sectors/lanes created for this society yet.'
                                                      : 'No buildings/blocks created for this society yet.',
                                                  style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
                                                ),
                                              ),
                                            )
                                          : DropdownButtonFormField<Building>(
                                              value: _selectedBuilding,
                                              hint: Text(isRowHouse ? 'Choose Sector / Lane' : 'Choose Building / Block'),
                                              isExpanded: true,
                                              decoration: InputDecoration(
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                fillColor: Colors.grey.shade50,
                                                filled: true,
                                              ),
                                              items: _buildings.map((bld) {
                                                return DropdownMenuItem<Building>(
                                                  value: bld,
                                                  child: Text(bld.name),
                                                );
                                              }).toList(),
                                              onChanged: (Building? value) {
                                                setState(() {
                                                  _selectedBuilding = value;
                                                });
                                              },
                                            ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_selectedSociety != null && _selectedBuilding != null) ...[
                          Text(
                            'Unit Configurations',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _numberController,
                            label: unitLabel,
                            prefixIcon: Icons.tag,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedUnitType,
                            decoration: InputDecoration(
                              labelText: 'Unit Type',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              fillColor: Colors.grey.shade50,
                              filled: true,
                            ),
                            items: [
                              if (!isCommercial && !isRowHouse)
                                const DropdownMenuItem(value: 'FLAT', child: Text('Flat / Apartment')),
                              if (isRowHouse) ...[
                                const DropdownMenuItem(value: 'ROW_HOUSE', child: Text('Row House')),
                                const DropdownMenuItem(value: 'VILLA', child: Text('Villa')),
                              ],
                              if (isCommercial || societyType == 'MIXED') ...[
                                const DropdownMenuItem(value: 'SHOP', child: Text('Shop')),
                                const DropdownMenuItem(value: 'OFFICE', child: Text('Office')),
                              ],
                            ].toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedUnitType = val);
                            },
                          ),
                          if (!isRowHouse) ...[
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _floorController,
                              label: 'Floor Number',
                              prefixIcon: Icons.layers_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                final val = int.tryParse(v.trim());
                                if (val == null) {
                                  return 'Enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ],
                          if (societyType == 'APARTMENT' || societyType == 'MIXED') ...[
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _wingController,
                              label: 'Wing / Block (optional, e.g. A, B)',
                              prefixIcon: Icons.grid_view_outlined,
                              validator: (_) => null,
                            ),
                          ],
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _areaController,
                            label: 'Area in Sq. Ft. (optional)',
                            prefixIcon: Icons.square_foot_outlined,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                          const SizedBox(height: 32),
                          AppButton(
                            text: 'Add Flat / Unit',
                            isLoading: _isSaving,
                            onPressed: _saveFlat,
                          ),
                        ] else ...[
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Text(
                                'Select society and building/sector above to configure unit details.',
                                style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }
}
