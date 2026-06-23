import 'package:flutter/material.dart';
import '../../theme/nest_loader.dart';
import '../../theme/app_colors.dart';
import '../../services/society_service.dart';
import '../../models/society_structure.dart';
import '../../widgets/app_field_card.dart';
import '../../widgets/app_page_header.dart';
import 'flat_create_screen.dart';

class FlatsListScreen extends StatefulWidget {
  const FlatsListScreen({super.key});

  @override
  State<FlatsListScreen> createState() => _FlatsListScreenState();
}

class _FlatsListScreenState extends State<FlatsListScreen> {
  final SocietyService _societyService = SocietyService();
  final TextEditingController _searchController = TextEditingController();

  List<Society> _societies = [];
  List<Building> _buildings = [];
  List<Flat> _flats = [];
  List<Flat> _filteredFlats = [];

  Society? _selectedSociety;
  Building? _selectedBuilding;

  bool _isLoadingSocieties = true;
  bool _isLoadingBuildings = false;
  bool _isLoadingFlats = false;
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
      _flats = [];
      _filteredFlats = [];
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

  Future<void> _loadFlats(String buildingId) async {
    setState(() {
      _isLoadingFlats = true;
      _flats = [];
      _filteredFlats = [];
    });

    try {
      final list = await _societyService.getFlats(buildingId);
      setState(() {
        _flats = list;
        _filteredFlats = _applyFilter(list, _searchQuery);
        _isLoadingFlats = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load flats/units: $e')),
        );
      }
      setState(() => _isLoadingFlats = false);
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filteredFlats = _applyFilter(_flats, _searchQuery);
    });
  }

  List<Flat> _applyFilter(List<Flat> list, String query) {
    if (query.trim().isEmpty) return list;
    final lower = query.toLowerCase();
    return list.where((f) {
      final numberMatch = f.number.toLowerCase().contains(lower);
      final wingMatch =
          f.wing != null && f.wing!.toLowerCase().contains(lower);
      final floorMatch =
          f.floor != null && f.floor!.toLowerCase().contains(lower);
      final typeMatch = f.unitType.toLowerCase().contains(lower);
      return numberMatch || wingMatch || floorMatch || typeMatch;
    }).toList();
  }

  IconData _getUnitIcon(String type) {
    switch (type.toUpperCase()) {
      case 'ROW_HOUSE':
      case 'VILLA':
      case 'TENEMENT':
        return Icons.home_outlined;
      case 'SHOP':
        return Icons.storefront_outlined;
      case 'OFFICE':
        return Icons.work_outline;
      case 'FLAT':
      default:
        return Icons.apartment_outlined;
    }
  }

  Color _getUnitColor(String type) {
    switch (type.toUpperCase()) {
      case 'ROW_HOUSE':
      case 'VILLA':
      case 'TENEMENT':
        return AppColors.accentGreen;
      case 'SHOP':
        return AppColors.accentPurple;
      case 'OFFICE':
        return AppColors.accentOrange;
      case 'FLAT':
      default:
        return AppColors.accentBlue;
    }
  }

  Future<void> _openEditPage(Flat flat) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FlatCreateScreen(
          flat: flat,
          building: _selectedBuilding,
          society: _selectedSociety,
        ),
      ),
    );
    if (saved == true && _selectedBuilding != null) {
      _loadFlats(_selectedBuilding!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isRowHouse = _selectedSociety != null &&
        (_selectedSociety!.societyType == 'ROW_HOUSE' ||
            _selectedSociety!.societyType == 'TENEMENT');

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
            title: 'Society Units Directory',
            subtitle: 'Browse flats, houses, shops and offices',
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
                                if (value != null) {
                                  _loadBuildings(value.id);
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(
                                  isRowHouse
                                      ? 'No sectors/lanes created yet.'
                                      : 'No buildings/blocks created yet.',
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
                                    if (value != null) {
                                      _loadFlats(value.id);
                                    }
                                  });
                                },
                              ),
                            ),
                        ],
                        if (_selectedBuilding != null) ...[
                          const SizedBox(height: 24),
                          AppSearchField(
                            controller: _searchController,
                            hint: isRowHouse
                                ? 'Search House No'
                                : 'Search Flat, Wing, or Floor',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Found ${_filteredFlats.length} units',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Expanded(
                          child: _selectedBuilding == null
                              ? const AppListPlaceholder(
                                  'Select society and building/sector above.',
                                )
                              : _isLoadingFlats
                                  ? const Center(child: NestLoader())
                                  : _filteredFlats.isEmpty
                                      ? AppListEmpty(
                                          icon: Icons.door_sliding_outlined,
                                          message: _searchQuery.isNotEmpty
                                              ? 'No search matches'
                                              : 'No units created yet',
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.only(
                                            bottom: 24,
                                          ),
                                          itemCount: _filteredFlats.length,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          itemBuilder: (context, index) {
                                            final flat = _filteredFlats[index];
                                            final Color typeColor =
                                                _getUnitColor(flat.unitType);

                                            return AppListCard(
                                              accentColor: typeColor,
                                              icon: _getUnitIcon(flat.unitType),
                                              title: flat.number,
                                              badgeText: flat.unitType,
                                              subtitleChips: [
                                                if (flat.wing != null &&
                                                    flat.wing!.isNotEmpty)
                                                  'Wing ${flat.wing}',
                                                if (flat.floor != null &&
                                                    flat.floor != '0')
                                                  'Floor ${flat.floor}',
                                                if (flat.areaSqft != null &&
                                                    flat.areaSqft != '0.00' &&
                                                    flat.areaSqft != '0')
                                                  '${flat.areaSqft} sqft',
                                              ],
                                              trailing: IconButton(
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                                tooltip: 'Edit unit',
                                                onPressed: () =>
                                                    _openEditPage(flat),
                                              ),
                                            );
                                          },
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
