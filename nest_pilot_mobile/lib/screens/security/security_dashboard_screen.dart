import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import '../../services/permission_service.dart';
import '../../config/modules.dart';
import '../../theme/app_colors.dart';
import '../../theme/nest_loader.dart';
import '../../widgets/app_field_card.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/glare_button.dart';
import '../../widgets/no_permission_notice.dart';

enum GateMode { verify, walkIn }

class SecurityDashboardScreen extends StatefulWidget {
  final GateMode mode;
  const SecurityDashboardScreen({super.key, this.mode = GateMode.verify});

  @override
  State<SecurityDashboardScreen> createState() =>
      _SecurityDashboardScreenState();
}

class _SecurityDashboardScreenState extends State<SecurityDashboardScreen>
    with SingleTickerProviderStateMixin {
  final CommunityService _service = CommunityService();

  late TabController _tabCtrl;

  // Verify mode
  final _codeCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  bool _verifying = false;

  // Walk-in mode
  final _walkFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _walkVehicleCtrl = TextEditingController();
  String? _selectedHouse;
  List<String> _houseNumbers = [];
  bool _loadingHouses = true;
  bool _logging = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.mode == GateMode.walkIn ? 1 : 0,
    );
    _fetchHouses();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _codeCtrl.dispose();
    _vehicleCtrl.dispose();
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _walkVehicleCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchHouses() async {
    try {
      final houses = await _service.getAllHouses();
      if (mounted) {
        final nums = houses
            .map<String>((h) => h['house_no'].toString())
            .toList()
          ..sort();
        setState(() {
          _houseNumbers = nums;
          _loadingHouses = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingHouses = false);
    }
  }

  // ─── Verify pass code ───────────────────────────────────────────────────────

  Future<void> _verifyEntry() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a pass code')),
      );
      return;
    }
    setState(() => _verifying = true);
    try {
      final data = await _service.verifyPassCode(code);
      final visitor = data['Visitor'];
      final house = data['House'];
      if (!mounted) return;
      setState(() => _verifying = false);

      final result = await _showConfirmDialog(
        title: 'Verify Guest',
        name: visitor['name'] ?? '—',
        mobile: visitor['mobile'] ?? '—',
        visiting: house?['house_no'] ?? '—',
      );

      if (result != null) {
        setState(() => _verifying = true);
        await _service.logVisitorEntry({
          'pass_code': code,
          'vehicle_number': _vehicleCtrl.text.trim(),
          'gate': 'Main Gate',
          'status': result,
        });
        if (mounted) {
          _codeCtrl.clear();
          _vehicleCtrl.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result == 'INSIDE' ? 'Visitor entry logged' : 'Entry denied',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  // ─── Walk-in entry ──────────────────────────────────────────────────────────

  Future<void> _logWalkIn() async {
    if (!_walkFormKey.currentState!.validate()) return;
    if (_selectedHouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a flat')),
      );
      return;
    }

    final result = await _showConfirmDialog(
      title: 'Log Walk-in',
      name: _nameCtrl.text.trim(),
      mobile: _mobileCtrl.text.trim(),
      visiting: _selectedHouse!,
    );
    if (result == null) return;

    setState(() => _logging = true);
    try {
      await _service.logVisitorEntry({
        'name': _nameCtrl.text.trim(),
        'mobile': _mobileCtrl.text.trim(),
        'house_no': _selectedHouse,
        'vehicle_number': _walkVehicleCtrl.text.trim(),
        'type': 'WALK_IN',
        'gate': 'Main Gate',
        'status': result,
      });
      if (mounted) {
        _nameCtrl.clear();
        _mobileCtrl.clear();
        _walkVehicleCtrl.clear();
        setState(() => _selectedHouse = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result == 'INSIDE' ? 'Entry logged' : 'Entry denied'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _logging = false);
    }
  }

  // ─── Confirm dialog ─────────────────────────────────────────────────────────

  Future<String?> _showConfirmDialog({
    required String title,
    required String name,
    required String mobile,
    required String visiting,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoRow(Icons.person_outline_rounded, 'Name', name),
            const SizedBox(height: 10),
            _infoRow(Icons.phone_outlined, 'Mobile', mobile),
            const SizedBox(height: 10),
            _infoRow(Icons.home_outlined, 'Visiting', visiting),
            const SizedBox(height: 16),
            const Text(
              'Allow or deny entry?',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'DENIED'),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
            child: const Text('Deny'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'INSIDE'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canCreate = PermissionService().canCreate(ModuleCodes.visitors);

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Column(
        children: [
          AppPageHeader(
            icon: const Icon(
              Icons.security_rounded,
              color: AppColors.white,
              size: 28,
            ),
            title: 'Gate Control',
            subtitle: 'Verify invited guests or log walk-in visitors',
            bottom: canCreate
                ? TabBar(
                    controller: _tabCtrl,
                    labelColor: AppColors.white,
                    unselectedLabelColor:
                        AppColors.white.withValues(alpha: 0.55),
                    indicatorColor: AppColors.white,
                    indicatorWeight: 2.5,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(text: 'Verify Pass Code'),
                      Tab(text: 'Walk-in / Delivery'),
                    ],
                  )
                : null,
          ),
          Expanded(
            child: canCreate
                ? TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildVerifyTab(),
                      _buildWalkInTab(),
                    ],
                  )
                : Center(
                    child: NoPermissionNotice(action: 'log visitor entries'),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Verify tab ─────────────────────────────────────────────────────────────

  Widget _buildVerifyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instruction card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accentGreen.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.accentGreen,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Ask the visitor to show their 6-digit pass code sent by the resident.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppFieldCard(
            icon: Icons.vpn_key_rounded,
            label: 'Pass Code',
            field: AppBorderlessField(
              controller: _codeCtrl,
              hint: '6-digit code',
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
          ),
          const SizedBox(height: 14),
          AppFieldCard(
            icon: Icons.directions_car_outlined,
            label: 'Vehicle Number (optional)',
            field: AppBorderlessField(
              controller: _vehicleCtrl,
              hint: 'e.g. GJ01AB1234',
            ),
          ),
          const SizedBox(height: 28),
          GlarePrimaryButton(
            text: 'Verify & Log Entry',
            trailingIcon: Icons.check_circle_outline_rounded,
            isLoading: _verifying,
            onPressed: _verifyEntry,
            showGlare: false,
          ),
        ],
      ),
    );
  }

  // ─── Walk-in tab ────────────────────────────────────────────────────────────

  Widget _buildWalkInTab() {
    if (_loadingHouses) {
      return const Center(child: NestLoader());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      child: Form(
        key: _walkFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instruction card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accentBlue.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.accentBlue,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'For unannounced visitors, deliveries, or guests without a pass code.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppFieldCard(
              icon: Icons.person_outline_rounded,
              label: 'Visitor Name',
              field: AppBorderlessField(
                controller: _nameCtrl,
                hint: 'Full name',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
            const SizedBox(height: 14),
            AppFieldCard(
              icon: Icons.phone_outlined,
              label: 'Mobile Number',
              field: AppBorderlessField(
                controller: _mobileCtrl,
                hint: '10-digit mobile',
                keyboardType: TextInputType.phone,
                validator: (v) {
                  final val = (v ?? '').trim();
                  if (val.isEmpty) return 'Required';
                  if (!RegExp(r'^\d{10}$').hasMatch(val)) {
                    return 'Enter a valid 10-digit number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),
            AppFieldCard(
              icon: Icons.home_outlined,
              label: 'Visiting Flat',
              field: AppCardDropdown<String>(
                value: _selectedHouse,
                hintText: 'Select flat',
                items: _houseNumbers,
                itemLabel: (v) => v,
                validator: (v) => v == null ? 'Please select a flat' : null,
                onChanged: (v) => setState(() => _selectedHouse = v),
              ),
            ),
            const SizedBox(height: 14),
            AppFieldCard(
              icon: Icons.directions_car_outlined,
              label: 'Vehicle Number (optional)',
              field: AppBorderlessField(
                controller: _walkVehicleCtrl,
                hint: 'e.g. GJ01AB1234',
              ),
            ),
            const SizedBox(height: 28),
            GlarePrimaryButton(
              text: 'Log Entry',
              trailingIcon: Icons.login_rounded,
              isLoading: _logging,
              onPressed: _logWalkIn,
              showGlare: false,
            ),
          ],
        ),
      ),
    );
  }
}
