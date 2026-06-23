import 'package:flutter/material.dart';
import '../../theme/nest_loader.dart';
import '../../theme/app_colors.dart';
import '../../services/society_service.dart';
import '../../models/society_structure.dart';
import '../../widgets/app_field_card.dart';
import '../../widgets/app_page_header.dart';
import 'society_create_screen.dart';

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

  Future<void> _openEditPage(Society society) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SocietyCreateScreen(society: society),
      ),
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
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: AppColors.textSecondary,
                                          ),
                                          tooltip: 'Edit society',
                                          onPressed: () =>
                                              _openEditPage(society),
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
