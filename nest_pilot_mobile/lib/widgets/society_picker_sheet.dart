import 'dart:async';

import 'package:flutter/material.dart';

import '../models/society_structure.dart';
import '../services/society_service.dart';
import '../theme/app_colors.dart';
import '../theme/nest_loader.dart';
import 'app_field_card.dart';

/// Icon for a society type. Shared by the societies directory and the
/// society picker so a type reads the same everywhere.
IconData societyTypeIcon(String type) {
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

/// Accent colour for a society type (see [societyTypeIcon]).
Color societyTypeColor(String type) {
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

/// Opens a searchable, paged society picker and resolves to the chosen
/// society (null when dismissed). Search and paging run on the server, so it
/// stays quick with hundreds of societies where a plain dropdown would not.
Future<Society?> showSocietyPicker(
  BuildContext context, {
  String? selectedId,
}) {
  return showModalBottomSheet<Society>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _SocietyPickerSheet(selectedId: selectedId),
  );
}

class _SocietyPickerSheet extends StatefulWidget {
  final String? selectedId;

  const _SocietyPickerSheet({this.selectedId});

  @override
  State<_SocietyPickerSheet> createState() => _SocietyPickerSheetState();
}

class _SocietyPickerSheetState extends State<_SocietyPickerSheet> {
  final SocietyService _service = SocietyService();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  final List<SocietyOverview> _items = [];
  String _query = '';
  int _page = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  String? _error;

  // Bumped on every fresh search so a late response for an older query is
  // dropped instead of mixing into the new results.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {}); // AppSearchField derives its clear button from the text
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final q = _searchCtrl.text.trim();
      if (q == _query) return;
      _query = q;
      _load(reset: true);
    });
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      _requestId++;
      _items.clear();
      _page = 0;
      _hasMore = true;
    } else if (_isLoading || !_hasMore || _error != null) {
      return;
    }
    final requestId = _requestId;
    final page = _page + 1;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _service.getSocietyDirectory(
        page: page,
        search: _query,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _items.addAll(result.items);
        _page = page;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _retry() {
    setState(() => _error = null);
    _load(reset: _items.isEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Fill most of the screen but stay clear of the keyboard and status bar.
    final height =
        (media.size.height -
                media.viewInsets.bottom -
                media.padding.top -
                24)
            .clamp(260.0, media.size.height * 0.85);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: AppSearchField(
                controller: _searchCtrl,
                hint: 'Search name, city or pincode',
              ),
            ),
            Expanded(child: _buildList(media.padding.bottom)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: ModuleColors.buildings.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.location_city_outlined,
              color: Color.lerp(ModuleColors.buildings, AppColors.black, 0.25),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Select Society',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.accentRed,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(double bottomPad) {
    if (_items.isEmpty) {
      if (_isLoading) {
        return const Center(child: NestLoader(size: 48, showDots: false));
      }
      if (_error != null) return _buildRetry(_error!);
      return AppListEmpty(
        icon: Icons.location_city_outlined,
        message: _query.isEmpty
            ? 'No societies yet'
            : 'No societies match "$_query"',
      );
    }

    final showFooter = _hasMore || _error != null;
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 20),
      itemCount: _items.length + (showFooter ? 1 : 0),
      itemBuilder: (context, i) {
        if (i >= _items.length) {
          if (_error != null) return _buildRetry(_error!);
          // Reaching the footer pulls the next page — this also covers a
          // first page too short to scroll.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _load();
          });
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: NestLoader(size: 28, showDots: false)),
          );
        }

        final overview = _items[i];
        final society = overview.society;
        final selected = society.id == widget.selectedId;
        return AppListCard(
          accentColor: overview.isInactive
              ? AppColors.grey
              : societyTypeColor(society.societyType),
          icon: societyTypeIcon(society.societyType),
          title: society.name,
          badgeText: overview.isInactive ? 'INACTIVE' : null,
          subtitleChips: [
            if ((society.city ?? '').isNotEmpty) society.city!,
            '${overview.activeUsers} users',
            '${overview.flats} flats',
          ],
          trailing: selected
              ? const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                )
              : null,
          onTap: () => Navigator.pop(context, society),
        );
      },
    );
  }

  Widget _buildRetry(String message) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          TextButton(onPressed: _retry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
