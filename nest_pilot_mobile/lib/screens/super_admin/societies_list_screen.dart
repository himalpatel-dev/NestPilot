import 'package:flutter/material.dart';
import '../../theme/nest_loader.dart';
import '../../theme/app_colors.dart';
import '../../services/society_service.dart';
import '../../models/society_structure.dart';
import '../../widgets/app_field_card.dart';
import '../../widgets/app_page_header.dart';
import 'buildings_list_screen.dart';

class SocietiesListScreen extends StatefulWidget {
  const SocietiesListScreen({super.key});

  @override
  State<SocietiesListScreen> createState() => _SocietiesListScreenState();
}

class _SocietiesListScreenState extends State<SocietiesListScreen> {
  final SocietyService _societyService = SocietyService();
  final TextEditingController _searchController = TextEditingController();

  List<Society> _societies = [];
  List<Society> _filteredSocieties = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSocieties();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSocieties() async {
    setState(() => _isLoading = true);
    try {
      final list = await _societyService.getSocieties();
      if (!mounted) return;
      setState(() {
        _societies = list;
        _filteredSocieties = _applyFilter(list, _searchQuery);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load societies: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filteredSocieties = _applyFilter(_societies, _searchQuery);
    });
  }

  List<Society> _applyFilter(List<Society> list, String query) {
    if (query.trim().isEmpty) return list;
    final lower = query.toLowerCase();
    return list.where((s) {
      return s.name.toLowerCase().contains(lower) ||
          s.address.toLowerCase().contains(lower) ||
          (s.city ?? '').toLowerCase().contains(lower) ||
          s.societyType.toLowerCase().contains(lower);
    }).toList();
  }

  IconData _getTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'ROW_HOUSE':
      case 'TENEMENT':
        return Icons.home_outlined;
      case 'COMMERCIAL':
        return Icons.storefront_outlined;
      case 'MIXED':
        return Icons.domain_outlined;
      case 'APARTMENT':
      default:
        return Icons.business_outlined;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'ROW_HOUSE':
      case 'TENEMENT':
        return AppColors.accentGreen;
      case 'COMMERCIAL':
        return AppColors.accentPurple;
      case 'MIXED':
        return AppColors.accentOrange;
      case 'APARTMENT':
      default:
        return AppColors.accentBlue;
    }
  }

  Future<void> _openEditSheet(Society society) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SocietyEditSheet(society: society),
    );
    if (saved == true) _loadSocieties();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Column(
        children: [
          const AppPageHeader(
            icon: Icon(
              Icons.domain_rounded,
              color: AppColors.white,
              size: 28,
            ),
            title: 'All Societies',
            subtitle: 'Browse and manage onboarded societies',
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: NestLoader())
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        AppSearchField(
                          controller: _searchController,
                          hint: 'Search by name, city, or type',
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Found ${_filteredSocieties.length} societies',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _filteredSocieties.isEmpty
                              ? AppListEmpty(
                                  icon: Icons.business_outlined,
                                  message: _searchQuery.isNotEmpty
                                      ? 'No search matches'
                                      : 'No societies created yet',
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadSocieties,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    itemCount: _filteredSocieties.length,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(
                                      parent: BouncingScrollPhysics(),
                                    ),
                                    itemBuilder: (context, index) {
                                      final society =
                                          _filteredSocieties[index];
                                      final Color typeColor = _getTypeColor(
                                        society.societyType,
                                      );

                                      return AppListCard(
                                        accentColor: typeColor,
                                        icon: _getTypeIcon(
                                          society.societyType,
                                        ),
                                        title: society.name,
                                        badgeText: society.societyType,
                                        subtitleChips: [
                                          [
                                            society.address,
                                            if ((society.city ?? '').isNotEmpty)
                                              society.city!,
                                          ].join(', '),
                                        ],
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BuildingsListScreen(
                                              society: society,
                                            ),
                                          ),
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: AppColors.textSecondary,
                                          ),
                                          tooltip: 'Edit society',
                                          onPressed: () =>
                                              _openEditSheet(society),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Edit bottom sheet ─────────────────────────────────────────────────────────

class _SocietyEditSheet extends StatefulWidget {
  final Society society;
  const _SocietyEditSheet({required this.society});

  @override
  State<_SocietyEditSheet> createState() => _SocietyEditSheetState();
}

class _SocietyEditSheetState extends State<_SocietyEditSheet> {
  final _formKey = GlobalKey<FormState>();
  final SocietyService _societyService = SocietyService();

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;
  late String _selectedSocietyType;
  bool _isSaving = false;

  final List<String> _societyTypes = [
    'APARTMENT',
    'TENEMENT',
    'ROW_HOUSE',
    'COMMERCIAL',
    'MIXED',
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.society;
    _nameController = TextEditingController(text: s.name);
    _addressController = TextEditingController(text: s.address);
    _cityController = TextEditingController(text: s.city ?? '');
    _stateController = TextEditingController(text: s.state ?? '');
    _pincodeController = TextEditingController(text: s.pincode ?? '');
    _selectedSocietyType =
        _societyTypes.contains(s.societyType) ? s.societyType : 'APARTMENT';
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
    setState(() => _isSaving = true);
    try {
      final success = await _societyService.updateSociety(
        id: widget.society.id,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        societyType: _selectedSocietyType,
      );
      if (!mounted) return;
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update society')),
        );
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update society: $e')),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Edit Society',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Society Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Address is required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pincodeController,
                decoration: const InputDecoration(
                  labelText: 'Pincode',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Pincode is required' : null,
              ),
              const SizedBox(height: 12),
              AppFieldCard(
                icon: Icons.category_rounded,
                label: 'Society Type',
                field: AppCardDropdown<String>(
                  value: _selectedSocietyType,
                  items: _societyTypes,
                  itemLabel: (type) => type,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSocietyType = val);
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
