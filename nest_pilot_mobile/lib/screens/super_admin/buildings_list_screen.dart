import 'package:flutter/material.dart';
import '../../theme/nest_loader.dart';
import '../../theme/app_colors.dart';
import '../../services/society_service.dart';
import '../../models/society_structure.dart';
import '../../widgets/app_field_card.dart';
import '../../widgets/app_page_header.dart';
import 'building_create_screen.dart';

class BuildingsListScreen extends StatefulWidget {
  /// When opened from the societies list, the society is already chosen.
  /// When opened from the dashboard, the user picks one from the dropdown.
  final Society? society;
  const BuildingsListScreen({super.key, this.society});

  @override
  State<BuildingsListScreen> createState() => _BuildingsListScreenState();
}

class _BuildingsListScreenState extends State<BuildingsListScreen> {
  final SocietyService _societyService = SocietyService();
  final TextEditingController _searchController = TextEditingController();

  List<Society> _societies = [];
  List<Building> _buildings = [];
  List<Building> _filteredBuildings = [];

  Society? _selectedSociety;
  bool _isLoadingSocieties = true;
  bool _isLoadingBuildings = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    if (widget.society != null) {
      _selectedSociety = widget.society;
      _isLoadingSocieties = false;
      _loadBuildings(widget.society!.id);
    } else {
      _loadSocieties();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSocieties() async {
    try {
      final list = await _societyService.getSocieties();
      if (!mounted) return;
      setState(() {
        _societies = list;
        _isLoadingSocieties = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load societies: $e')));
        setState(() => _isLoadingSocieties = false);
      }
    }
  }

  Future<void> _loadBuildings(String societyId) async {
    setState(() {
      _isLoadingBuildings = true;
      _buildings = [];
      _filteredBuildings = [];
    });

    try {
      final list = await _societyService.getBuildings(societyId);
      if (!mounted) return;
      setState(() {
        _buildings = list;
        _filteredBuildings = _applyFilter(list, _searchQuery);
        _isLoadingBuildings = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load buildings/sectors: $e')),
        );
        setState(() => _isLoadingBuildings = false);
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filteredBuildings = _applyFilter(_buildings, _searchQuery);
    });
  }

  List<Building> _applyFilter(List<Building> list, String query) {
    if (query.trim().isEmpty) return list;
    final lower = query.toLowerCase();
    return list.where((b) {
      return b.name.toLowerCase().contains(lower) ||
          (b.blocks ?? '').toLowerCase().contains(lower) ||
          (b.wings ?? '').toLowerCase().contains(lower);
    }).toList();
  }

  bool get _isRowHouse =>
      _selectedSociety != null &&
      (_selectedSociety!.societyType == 'ROW_HOUSE' ||
          _selectedSociety!.societyType == 'TENEMENT');

  Future<void> _openEditPage(Building building) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BuildingCreateScreen(building: building, society: _selectedSociety),
      ),
    );
    if (saved == true && _selectedSociety != null) {
      _loadBuildings(_selectedSociety!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Column(
        children: [
          AppPageHeader(
            icon: const Icon(
              Icons.business_rounded,
              color: AppColors.white,
              size: 28,
            ),
            title: widget.society != null
                ? '${widget.society!.name} Buildings'
                : 'All Buildings',
            subtitle: 'Browse buildings, blocks, sectors and lanes',
          ),
          Expanded(
            child: _isLoadingSocieties
                ? const Center(child: NestLoader())
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        if (widget.society == null) ...[
                          const AppSectionHeader('Select Society'),
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
                                setState(() => _selectedSociety = value);
                                if (value != null) _loadBuildings(value.id);
                              },
                            ),
                          ),
                        ],
                        if (_selectedSociety != null) ...[
                          const SizedBox(height: 24),
                          AppSearchField(
                            controller: _searchController,
                            hint: _isRowHouse
                                ? 'Search Sector / Lane'
                                : 'Search Building / Block',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Found ${_filteredBuildings.length} ${_isRowHouse ? 'sectors' : 'buildings'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Expanded(
                          child: _selectedSociety == null
                              ? const AppListPlaceholder(
                                  'Please select a society above.',
                                )
                              : _isLoadingBuildings
                              ? const Center(child: NestLoader())
                              : _filteredBuildings.isEmpty
                              ? AppListEmpty(
                                  icon: Icons.apartment_outlined,
                                  message: _searchQuery.isNotEmpty
                                      ? 'No search matches'
                                      : (_isRowHouse
                                            ? 'No sectors/lanes created yet'
                                            : 'No buildings/blocks created yet'),
                                )
                              : RefreshIndicator(
                                  onRefresh: () =>
                                      _loadBuildings(_selectedSociety!.id),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    itemCount: _filteredBuildings.length,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(
                                          parent: BouncingScrollPhysics(),
                                        ),
                                    itemBuilder: (context, index) {
                                      final building =
                                          _filteredBuildings[index];

                                      return AppListCard(
                                        accentColor: AppColors.accentBlue,
                                        icon: _isRowHouse
                                            ? Icons.home_outlined
                                            : Icons.apartment_outlined,
                                        title: building.name,
                                        subtitleChips: [
                                          if ((building.blocks ?? '')
                                              .isNotEmpty)
                                            'Blocks: ${building.blocks}',
                                          if ((building.wings ?? '').isNotEmpty)
                                            'Wings: ${building.wings}',
                                          if (building.floorsCount > 0)
                                            'Floors: ${building.floorsCount}',
                                        ],
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: AppColors.textSecondary,
                                          ),
                                          tooltip: 'Edit building',
                                          onPressed: () =>
                                              _openEditPage(building),
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
