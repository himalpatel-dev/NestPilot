import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import '../../../theme/app_colors.dart';
import '../../../theme/nest_loader.dart';
import '../../../models/community_models.dart';
import '../../../services/community_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/permission_service.dart';
import '../../../config/modules.dart';
import '../../../widgets/app_page_header.dart';
import '../../../widgets/app_field_card.dart';
import '../../../widgets/glare_button.dart';

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
      if (mounted) setState(() { _vehicles = vehicles; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  IconData _vehicleIcon(String type) {
    switch (type) {
      case 'BIKE': return Icons.two_wheeler_rounded;
      case 'CAR':  return Icons.directions_car_rounded;
      default:     return Icons.commute_rounded;
    }
  }

  Color _vehicleColor(String type) {
    switch (type) {
      case 'BIKE': return AppColors.accentOrange;
      case 'CAR':  return AppColors.accentBlue;
      default:     return AppColors.accentPurple;
    }
  }

  Future<void> _confirmDelete(Vehicle v) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                decoration: const BoxDecoration(
                  color: AppColors.accentRed,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white.withValues(alpha: 0.40), width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.white, size: 24),
                    ),
                    const SizedBox(height: 12),
                    const Text('Remove Vehicle?', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(v.vehicleNumber, style: TextStyle(color: AppColors.white.withValues(alpha: 0.80), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  children: [
                    const Text(
                      'This vehicle will be removed from the society registry.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx, false),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                              alignment: Alignment.center,
                              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx, true),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.accentRed,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: AppColors.accentRed.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              alignment: Alignment.center,
                              child: const Text('Remove', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteVehicle(v.id);
        if (mounted) _fetch();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showAddSheet() async {
    final formKey = GlobalKey<FormState>();
    final numberCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    String selectedType = 'CAR';
    bool saving = false;

    final user = await AuthService().getMe();
    if (user == null || !mounted) return;

    final stickerNumber = '${user.flatNumber ?? 'N/A'}-${user.societyId ?? 'N/A'}-${user.id}';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Add Vehicle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Register a vehicle to the society',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                AppFieldCard(
                  icon: Icons.pin_outlined,
                  label: 'Vehicle Number',
                  field: AppBorderlessField(
                    controller: numberCtrl,
                    hint: 'e.g. GJ01AB1234',
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]'))],
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 12),
                AppFieldCard(
                  icon: Icons.directions_car_outlined,
                  label: 'Model (optional)',
                  field: AppBorderlessField(controller: modelCtrl, hint: 'e.g. Honda City'),
                ),
                const SizedBox(height: 12),
                AppFieldCard(
                  icon: Icons.category_outlined,
                  label: 'Type',
                  field: AppCardDropdown<String>(
                    value: selectedType,
                    items: const ['CAR', 'BIKE', 'OTHER'],
                    itemLabel: (t) => t == 'CAR' ? 'Car' : t == 'BIKE' ? 'Bike / Two-Wheeler' : 'Other',
                    onChanged: (v) { if (v != null) setSheet(() => selectedType = v); },
                  ),
                ),
                const SizedBox(height: 24),
                GlarePrimaryButton(
                  text: 'Add Vehicle',
                  trailingIcon: Icons.check_rounded,
                  isLoading: saving,
                  showGlare: false,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    setSheet(() => saving = true);
                    try {
                      await _service.addVehicle({
                        'vehicle_number': numberCtrl.text.trim().toUpperCase(),
                        'model': modelCtrl.text.trim(),
                        'type': selectedType,
                        'sticker_number': stickerNumber,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _fetch();
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    } finally {
                      if (ctx.mounted) setSheet(() => saving = false);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final canCreate = PermissionService().canCreate(ModuleCodes.vehicles);
    final canDelete = PermissionService().canDelete(ModuleCodes.vehicles);

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
              child: AppPageHeader(
                icon: const Icon(Icons.directions_car_rounded, color: AppColors.white, size: 28),
                title: 'Vehicles',
                subtitle: _isLoading
                    ? 'Loading vehicles…'
                    : '${_vehicles.length} vehicle${_vehicles.length == 1 ? '' : 's'} registered',
                trailing: canCreate
                    ? GestureDetector(
                        onTap: _showAddSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.white.withValues(alpha: 0.30)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, color: AppColors.white, size: 16),
                              SizedBox(width: 5),
                              Text('Add', style: TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(child: NestLoader())
            else if (_vehicles.isEmpty)
              SliverFillRemaining(child: _buildEmpty(canCreate))
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad + 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildCard(_vehicles[i], canDelete),
                    childCount: _vehicles.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Vehicle v, bool canDelete) {
    final color = _vehicleColor(v.type);
    final icon = _vehicleIcon(v.type);
    final displayName = [v.model, v.brand].where((s) => s != null && s.isNotEmpty).join(' · ');

    return Container(
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withValues(alpha: 0.30)),
                        ),
                        child: Text(
                          v.type,
                          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  if (displayName.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(displayName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                  if (v.flatNumber != null && v.flatNumber!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.home_rounded, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text('Flat ${v.flatNumber}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        if (v.userName != null && v.userName!.isNotEmpty) ...[
                          const Text('  ·  ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          Flexible(child: Text(v.userName!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12), overflow: TextOverflow.ellipsis)),
                        ],
                      ],
                    ),
                  ],
                  if (v.stickerNumber != null && v.stickerNumber!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.confirmation_number_outlined, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text('Sticker: ${v.stickerNumber}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Delete button
            if (canDelete) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _confirmDelete(v),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRed, size: 18),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool canCreate) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_car_outlined, color: AppColors.border, size: 56),
          const SizedBox(height: 12),
          const Text(
            'No vehicles registered',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            canCreate ? 'Tap + Add to register your vehicle' : 'Pull down to refresh',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
