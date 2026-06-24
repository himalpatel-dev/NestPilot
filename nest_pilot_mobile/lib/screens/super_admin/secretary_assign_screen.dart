import 'package:flutter/material.dart';
import '../../models/society_structure.dart';
import '../../services/secretary_building_service.dart';
import '../../services/society_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/nest_loader.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/glare_button.dart';

class SecretaryAssignScreen extends StatefulWidget {
  final SecretaryAdmin admin;

  const SecretaryAssignScreen({super.key, required this.admin});

  @override
  State<SecretaryAssignScreen> createState() => _SecretaryAssignScreenState();
}

class _SecretaryAssignScreenState extends State<SecretaryAssignScreen> {
  final SecretaryBuildingService _service = SecretaryBuildingService();
  final SocietyService _societyService = SocietyService();

  List<Building> _buildings = [];
  late Set<int> _selectedIds;
  bool _isLoading = true;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = {...widget.admin.buildings.map((b) => b.id)};
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    if (widget.admin.societyId == null) {
      setState(() {
        _error = 'This secretary is not linked to a society.';
        _isLoading = false;
      });
      return;
    }
    try {
      final list =
          await _societyService.getBuildings(widget.admin.societyId.toString());
      if (mounted) setState(() { _buildings = list; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final ok = await _service.setAssignments(
        widget.admin.id,
        _selectedIds.toList(),
      );
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignments updated successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update assignments')),
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
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Column(
        children: [
          AppPageHeader(
            icon: const Icon(
              Icons.apartment_outlined,
              color: AppColors.white,
              size: 28,
            ),
            title: 'Assign Buildings',
            subtitle: widget.admin.fullName,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: NestLoader())
                : _error != null
                    ? _buildError()
                    : _buildings.isEmpty
                        ? _buildEmpty()
                        : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.accentIndigo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accentIndigo.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accentIndigo.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.accentIndigo,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.admin.societyName ?? 'Society',
                        style: const TextStyle(
                          color: AppColors.accentIndigo,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_selectedIds.length} of ${_buildings.length} buildings selected',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Building chips grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _buildings.map((b) {
              final bid = int.tryParse(b.id);
              if (bid == null) return const SizedBox.shrink();
              final selected = _selectedIds.contains(bid);
              return GestureDetector(
                onTap: () => setState(() {
                  selected ? _selectedIds.remove(bid) : _selectedIds.add(bid);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accentIndigo.withValues(alpha: 0.12)
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppColors.accentIndigo
                          : AppColors.border,
                      width: selected ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: selected
                            ? AppColors.accentIndigo
                            : AppColors.textHint,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        b.name,
                        style: TextStyle(
                          color: selected
                              ? AppColors.accentIndigo
                              : AppColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          GlarePrimaryButton(
            text: 'Save Assignments',
            trailingIcon: Icons.check_rounded,
            isLoading: _isSaving,
            onPressed: _save,
            showGlare: false,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.accentRed, size: 48),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: _loadBuildings, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apartment_outlined,
                color: AppColors.border, size: 56),
            const SizedBox(height: 12),
            const Text(
              'No buildings in this society yet.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Add buildings to the society first, then assign them here.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
