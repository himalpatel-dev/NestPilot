import 'package:flutter/material.dart';
import '../../theme/nest_loader.dart';
import '../../services/society_service.dart';
import '../../models/society_structure.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class BuildingCreateScreen extends StatefulWidget {
  const BuildingCreateScreen({super.key});

  @override
  State<BuildingCreateScreen> createState() => _BuildingCreateScreenState();
}

class _BuildingCreateScreenState extends State<BuildingCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _floorsController = TextEditingController(text: '0');
  final TextEditingController _wingsController = TextEditingController();

  final SocietyService _societyService = SocietyService();
  
  List<Society> _societies = [];
  Society? _selectedSociety;
  
  bool _isLoadingSocieties = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSocieties();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _floorsController.dispose();
    _wingsController.dispose();
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

  Future<void> _saveBuilding() async {
    if (_selectedSociety == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a society first')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final String societyId = _selectedSociety!.id;
      final String type = _selectedSociety!.societyType;

      bool success = false;
      if (type == 'ROW_HOUSE' || type == 'TENEMENT') {
        success = await _societyService.createBuilding(
          societyId: societyId,
          name: _nameController.text.trim(),
          blocks: '1',
          wings: 'All',
          floorsCount: 0,
        );
      } else {
        final int floors = int.tryParse(_floorsController.text.trim()) ?? 0;
        success = await _societyService.createBuilding(
          societyId: societyId,
          name: _nameController.text.trim(),
          wings: _wingsController.text.trim().isNotEmpty ? _wingsController.text.trim() : null,
          floorsCount: floors,
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Building/Sector added successfully')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create building/sector')),
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
    final bool isRowHouseOrTenement = _selectedSociety != null &&
        (_selectedSociety!.societyType == 'ROW_HOUSE' ||
            _selectedSociety!.societyType == 'TENEMENT');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Building / Sector'),
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
                        const Icon(Icons.business_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No Societies Available',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please onboard a new society first before adding buildings or sectors.',
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
                                  'Select Target Society',
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
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    fillColor: Colors.grey.shade50,
                                    filled: true,
                                  ),
                                  items: _societies.map((soc) {
                                    return DropdownMenuItem<Society>(
                                      value: soc,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              soc.name,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              soc.societyType,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.blue.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (Society? value) {
                                    setState(() {
                                      _selectedSociety = value;
                                      if (value != null) {
                                        if (value.societyType == 'ROW_HOUSE' ||
                                            value.societyType == 'TENEMENT') {
                                          _floorsController.text = '0';
                                          _wingsController.clear();
                                        } else {
                                          _floorsController.text = '1';
                                        }
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_selectedSociety != null) ...[
                          Text(
                            isRowHouseOrTenement ? 'Sector / Lane Details' : 'Building / Block Details',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _nameController,
                            label: isRowHouseOrTenement
                                ? 'Sector / Lane / Block Name (e.g., Sector 1, Lane A)'
                                : 'Building / Tower / Block Name (e.g., Tower A, Block B)',
                            prefixIcon: isRowHouseOrTenement
                                ? Icons.location_on_outlined
                                : Icons.apartment_outlined,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          if (!isRowHouseOrTenement) ...[
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _floorsController,
                              label: 'Number of Floors',
                              prefixIcon: Icons.layers_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                final val = int.tryParse(v.trim());
                                if (val == null || val < 0) {
                                  return 'Enter a valid non-negative number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _wingsController,
                              label: 'Wings (optional, comma separated e.g. A, B, C)',
                              prefixIcon: Icons.grid_view_outlined,
                              validator: (_) => null,
                            ),
                          ],
                          const SizedBox(height: 32),
                          AppButton(
                            text: isRowHouseOrTenement ? 'Add Sector / Lane' : 'Create Building',
                            isLoading: _isSaving,
                            onPressed: _saveBuilding,
                          ),
                        ] else ...[
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Text(
                                'Select a society above to configure building details.',
                                style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
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
