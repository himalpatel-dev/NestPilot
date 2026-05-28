import 'package:flutter/material.dart';
import '../../services/society_service.dart';
import '../../models/society_structure.dart';

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
      final wingMatch = f.wing != null && f.wing!.toLowerCase().contains(lower);
      final floorMatch = f.floor != null && f.floor!.toLowerCase().contains(lower);
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
        return Colors.green.shade600;
      case 'SHOP':
        return Colors.purple.shade600;
      case 'OFFICE':
        return Colors.orange.shade700;
      case 'FLAT':
      default:
        return Colors.blue.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isRowHouse = _selectedSociety != null &&
        (_selectedSociety!.societyType == 'ROW_HOUSE' ||
            _selectedSociety!.societyType == 'TENEMENT');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Society Units Directory'),
        elevation: 0,
      ),
      body: _isLoadingSocieties
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // Dropdowns card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          DropdownButtonFormField<Society>(
                            value: _selectedSociety,
                            hint: const Text('Choose Society'),
                            isExpanded: true,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(),
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
                                if (value != null) {
                                  _loadBuildings(value.id);
                                }
                              });
                            },
                          ),
                          if (_selectedSociety != null) ...[
                            const SizedBox(height: 12),
                            _isLoadingBuildings
                                ? const Center(child: LinearProgressIndicator())
                                : _buildings.isEmpty
                                    ? Center(
                                        child: Text(
                                          isRowHouse
                                              ? 'No sectors/lanes created yet.'
                                              : 'No buildings/blocks created yet.',
                                          style: const TextStyle(color: Colors.red, fontSize: 13),
                                        ),
                                      )
                                    : DropdownButtonFormField<Building>(
                                        value: _selectedBuilding,
                                        hint: Text(isRowHouse ? 'Choose Sector / Lane' : 'Choose Building / Block'),
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          border: OutlineInputBorder(),
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
                                            if (value != null) {
                                              _loadFlats(value.id);
                                            }
                                          });
                                        },
                                      ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Search & Results header
                  if (_selectedBuilding != null) ...[
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: isRowHouse ? 'Search House No' : 'Search Flat, Wing, or Floor',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Found ${_filteredFlats.length} units',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Flats List
                  Expanded(
                    child: _selectedBuilding == null
                        ? Center(
                            child: Text(
                              'Please select society and building/sector above.',
                              style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : _isLoadingFlats
                            ? const Center(child: CircularProgressIndicator())
                            : _filteredFlats.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.door_sliding_outlined, size: 48, color: Colors.grey),
                                        const SizedBox(height: 12),
                                        Text(
                                          _searchQuery.isNotEmpty ? 'No search matches' : 'No units created yet',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _filteredFlats.length,
                                    physics: const BouncingScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final flat = _filteredFlats[index];
                                      final Color typeColor = _getUnitColor(flat.unitType);

                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(color: Colors.grey.shade200),
                                        ),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: typeColor.withOpacity(0.1),
                                            child: Icon(_getUnitIcon(flat.unitType), color: typeColor),
                                          ),
                                          title: Text(
                                            flat.number,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          subtitle: Wrap(
                                            spacing: 12,
                                            children: [
                                              if (flat.wing != null && flat.wing!.isNotEmpty)
                                                Text('Wing: ${flat.wing}'),
                                              if (flat.floor != null && flat.floor != '0')
                                                Text('Floor: ${flat.floor}'),
                                              if (flat.areaSqft != null && flat.areaSqft != '0.00' && flat.areaSqft != '0')
                                                Text('${flat.areaSqft} sqft'),
                                            ],
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: typeColor.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              flat.unitType,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: typeColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
            ),
    );
  }
}
