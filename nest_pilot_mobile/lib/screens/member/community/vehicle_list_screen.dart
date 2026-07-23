import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import '../../../theme/app_colors.dart';
import '../../../theme/nest_loader.dart';
import '../../../models/community_models.dart';
import '../../../services/community_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/permission_service.dart';
import '../../../config/modules.dart';
import '../../../widgets/module_page_header.dart';
import '../../../widgets/app_field_card.dart';
import '../../../widgets/app_form_sheet.dart';
import '../../../widgets/glare_button.dart';
import 'vehicle_detail_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final CommunityService _service = CommunityService();
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final vehicles = await _service.getAllVehicles();
      if (mounted)
        setState(() {
          _vehicles = vehicles;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  IconData _vehicleIcon(String type) {
    switch (type) {
      case 'BIKE':
        return Icons.two_wheeler_rounded;
      case 'CAR':
        return Icons.directions_car_rounded;
      default:
        return Icons.commute_rounded;
    }
  }

  Color _vehicleColor(String type) {
    switch (type) {
      case 'BIKE':
        return AppColors.accentOrange;
      case 'CAR':
        return AppColors.accentBlue;
      default:
        return AppColors.accentPurple;
    }
  }

  void _openAddSheet() {
    showAppFormSheet(
      context: context,
      builder: (ctx) => _VehicleFormSheet(
        onSaved: () {
          Navigator.pop(ctx);
          _fetch();
        },
      ),
    );
  }

  void _openEditSheet(Vehicle v) {
    showAppFormSheet(
      context: context,
      builder: (ctx) => _VehicleFormSheet(
        editing: v,
        onSaved: () {
          Navigator.pop(ctx);
          _fetch();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final canManage = PermissionService().canManage(ModuleCodes.vehicles);
    final total = _vehicles.length;
    final carCount = _vehicles.where((v) => v.type == 'CAR').length;
    final bikeCount = _vehicles.where((v) => v.type == 'BIKE').length;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: AppColors.white,
        backgroundColor: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: ModulePageHeader(
                title: 'Vehicles',
                description: 'Registered vehicles & parking stickers',
                icon: Icons.directions_car_rounded,
                iconColor: ModuleColors.vehicles,
                stats: [
                  ModuleHeaderStat('$carCount', 'CARS'),
                  ModuleHeaderStat('$bikeCount', 'BIKES'),
                  ModuleHeaderStat('$total', 'TOTAL'),
                ],
                showSearch: false,
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(child: NestLoader())
            else if (_vehicles.isEmpty)
              SliverFillRemaining(child: _buildEmpty(canManage))
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad + 90),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildCard(_vehicles[i], canManage),
                    childCount: _vehicles.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      // Adding a vehicle is a manage-only action — the list itself is
      // shared with view-only roles.
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: _openAddSheet,
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildCard(Vehicle v, bool canManage) {
    final color = _vehicleColor(v.type);
    final icon = _vehicleIcon(v.type);
    final displayName = [
      v.model,
      v.brand,
    ].where((s) => s != null && s.isNotEmpty).join(' · ');

    return GestureDetector(
      onTap: () async {
        // Detail pops `true` when it deleted the vehicle — refetch so the
        // row it just removed doesn't linger in the list.
        final deleted = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: v)),
        );
        if (deleted == true) _fetch();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // Vehicle type icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            v.vehicleNumber,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: color.withValues(alpha: 0.30),
                            ),
                          ),
                          child: Text(
                            v.type,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (displayName.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (v.flatNumber != null && v.flatNumber!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.home_rounded,
                            size: 11,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Flat ${v.flatNumber}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          if (v.userName != null && v.userName!.isNotEmpty) ...[
                            const Text(
                              '  Â·  ',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                v.userName!,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    if (v.stickerNumber != null &&
                        v.stickerNumber!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.confirmation_number_outlined,
                            size: 11,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sticker: ${v.stickerNumber}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Edit button — delete lives on the detail screen now.
              if (canManage) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _openEditSheet(v),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.accentIndigo.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: AppColors.accentIndigo,
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

  Widget _buildEmpty(bool canCreate) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.directions_car_outlined,
            color: AppColors.border,
            size: 56,
          ),
          const SizedBox(height: 12),
          const Text(
            'No vehicles registered',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            canCreate
                ? 'Tap + Add to register your vehicle'
                : 'Pull down to refresh',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Add / edit vehicle sheet ─────────────────────────────────────────────────

class _VehicleFormSheet extends StatefulWidget {
  final VoidCallback onSaved;
  final Vehicle? editing;
  const _VehicleFormSheet({required this.onSaved, this.editing});

  @override
  State<_VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<_VehicleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _numberCtrl = TextEditingController(
    text: widget.editing?.vehicleNumber,
  );
  late final _modelCtrl = TextEditingController(text: widget.editing?.model);
  late String _selectedType = widget.editing?.type ?? 'CAR';
  bool _isLoading = false;
  String? _apiError;

  bool get _isEditing => widget.editing != null;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _apiError = null;
    });
    try {
      if (_isEditing) {
        await CommunityService().updateVehicle(widget.editing!.id, {
          'vehicle_number': _numberCtrl.text.trim().toUpperCase(),
          'model': _modelCtrl.text.trim(),
          'type': _selectedType,
        });
      } else {
        final user = await AuthService().getMe();
        if (user == null) throw Exception('Could not load your profile');
        final stickerNumber =
            '${user.flatNumber ?? 'N/A'}-${user.societyId ?? 'N/A'}-${user.id}';
        await CommunityService().addVehicle({
          'vehicle_number': _numberCtrl.text.trim().toUpperCase(),
          'model': _modelCtrl.text.trim(),
          'type': _selectedType,
          'sticker_number': stickerNumber,
        });
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(
          () => _apiError = e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      accentColor: ModuleColors.vehicles,
      icon: _isEditing ? Icons.edit_rounded : Icons.directions_car_rounded,
      title: _isEditing ? 'Edit Vehicle' : 'Add Vehicle',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader('Vehicle Details'),
            const SizedBox(height: 14),
            AppFieldCard(
              icon: Icons.pin_outlined,
              label: 'Vehicle Number',
              field: AppBorderlessField(
                controller: _numberCtrl,
                hint: 'e.g. GJ01AB1234',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                ],
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
            const SizedBox(height: 12),
            AppFieldCard(
              icon: Icons.directions_car_outlined,
              label: 'Model (optional)',
              field: AppBorderlessField(
                controller: _modelCtrl,
                hint: 'e.g. Honda City',
              ),
            ),
            const SizedBox(height: 12),
            AppFieldCard(
              icon: Icons.category_outlined,
              label: 'Type',
              field: AppCardDropdown<String>(
                value: _selectedType,
                items: const ['CAR', 'BIKE', 'OTHER'],
                itemLabel: (t) => t == 'CAR'
                    ? 'Car'
                    : t == 'BIKE'
                    ? 'Bike / Two-Wheeler'
                    : 'Other',
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
            ),
            if (_apiError != null) ...[
              const SizedBox(height: 18),
              AppSheetErrorBanner(_apiError!),
            ],
            const SizedBox(height: 26),
            GlarePrimaryButton(
              text: _isEditing ? 'Update Vehicle' : 'Add Vehicle',
              trailingIcon: Icons.check_rounded,
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
