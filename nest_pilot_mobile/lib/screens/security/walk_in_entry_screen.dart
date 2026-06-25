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

class WalkInEntryScreen extends StatefulWidget {
  const WalkInEntryScreen({super.key});

  @override
  State<WalkInEntryScreen> createState() => _WalkInEntryScreenState();
}

class _WalkInEntryScreenState extends State<WalkInEntryScreen> {
  final CommunityService _service = CommunityService();

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  String? _selectedHouse;
  String? _selectedVisitorType;
  List<String> _houseNumbers = [];
  bool _loadingHouses = true;
  bool _logging = false;

  static const _visitorTypes = [
    'Guest',
    'Delivery',
    'Contractor / Repair',
    'Cab / Taxi',
    'Vendor',
    'Domestic Help',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _fetchHouses();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _vehicleCtrl.dispose();
    _purposeCtrl.dispose();
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

  Future<void> _logWalkIn() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a flat')),
      );
      return;
    }
    if (_selectedVisitorType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a visitor type')),
      );
      return;
    }

    final purpose = _purposeCtrl.text.trim();

    final result = await _showConfirmDialog(
      name: _nameCtrl.text.trim(),
      mobile: _mobileCtrl.text.trim(),
      visiting: _selectedHouse!,
      visitorType: _selectedVisitorType!,
      purpose: purpose.isNotEmpty ? purpose : null,
    );
    if (result == null) return;

    setState(() => _logging = true);
    try {
      await _service.logVisitorEntry({
        'name': _nameCtrl.text.trim(),
        'mobile': _mobileCtrl.text.trim(),
        'house_no': _selectedHouse,
        'vehicle_number': _vehicleCtrl.text.trim(),
        'visitor_type': _selectedVisitorType,
        if (_purposeCtrl.text.trim().isNotEmpty)
          'purpose': _purposeCtrl.text.trim(),
        'type': 'WALK_IN',
        'gate': 'Main Gate',
        'status': result,
      });
      if (mounted) {
        _nameCtrl.clear();
        _mobileCtrl.clear();
        _vehicleCtrl.clear();
        _purposeCtrl.clear();
        setState(() {
          _selectedHouse = null;
          _selectedVisitorType = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result == 'INSIDE' ? 'Entry logged' : 'Entry denied',
            ),
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

  Future<String?> _showConfirmDialog({
    required String name,
    required String mobile,
    required String visiting,
    required String visitorType,
    String? purpose,
  }) {
    return showDialog<String>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        child: _WalkInCard(
          name: name,
          mobile: mobile,
          visiting: visiting,
          visitorType: visitorType,
          purpose: purpose,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = PermissionService().canCreate(ModuleCodes.visitors);

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Column(
        children: [
          AppPageHeader(
            icon: const Icon(
              Icons.directions_walk_rounded,
              color: AppColors.white,
              size: 28,
            ),
            title: 'Walk-in / Delivery',
            subtitle: 'Log an unannounced visitor or delivery',
          ),
          Expanded(
            child: canCreate
                ? _loadingHouses
                    ? const Center(child: NestLoader())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.accentBlue
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.accentBlue
                                        .withValues(alpha: 0.22),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.accentBlue
                                            .withValues(alpha: 0.15),
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
                                      (v == null || v.trim().isEmpty)
                                          ? 'Required'
                                          : null,
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
                                  validator: (v) =>
                                      v == null ? 'Please select a flat' : null,
                                  onChanged: (v) =>
                                      setState(() => _selectedHouse = v),
                                ),
                              ),
                              const SizedBox(height: 14),
                              AppFieldCard(
                                icon: Icons.category_outlined,
                                label: 'Visitor Type',
                                field: AppCardDropdown<String>(
                                  value: _selectedVisitorType,
                                  hintText: 'Select type',
                                  items: _visitorTypes,
                                  itemLabel: (v) => v,
                                  validator: (v) =>
                                      v == null ? 'Please select a visitor type' : null,
                                  onChanged: (v) =>
                                      setState(() => _selectedVisitorType = v),
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
                              const SizedBox(height: 14),
                              AppFieldCard(
                                icon: Icons.notes_rounded,
                                label: 'Purpose (optional)',
                                field: AppBorderlessField(
                                  controller: _purposeCtrl,
                                  hint: 'e.g. Delivery, Meeting, Repair...',
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
                      )
                : Center(
                    child: NoPermissionNotice(action: 'log visitor entries'),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Walk-in confirm card ─────────────────────────────────────────────────────

class _WalkInCard extends StatelessWidget {
  final String name;
  final String mobile;
  final String visiting;
  final String visitorType;
  final String? purpose;

  const _WalkInCard({
    required this.name,
    required this.mobile,
    required this.visiting,
    required this.visitorType,
    this.purpose,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'V';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.80),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.40),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.directions_walk_rounded,
                            color: AppColors.white.withValues(alpha: 0.70),
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Walk-in Visitor',
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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

          // ── Detail rows ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.phone_outlined,
                  color: AppColors.accentBlue,
                  label: 'Mobile',
                  value: mobile,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: AppColors.border),
                ),
                _DetailRow(
                  icon: Icons.category_outlined,
                  color: AppColors.accentAmber,
                  label: 'Visitor Type',
                  value: visitorType,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: AppColors.border),
                ),
                _DetailRow(
                  icon: Icons.home_outlined,
                  color: AppColors.accentGreen,
                  label: 'Visiting Flat',
                  value: visiting,
                ),
                if (purpose != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: AppColors.border),
                  ),
                  _DetailRow(
                    icon: Icons.notes_rounded,
                    color: AppColors.accentAmber,
                    label: 'Purpose',
                    value: purpose!,
                  ),
                ],
              ],
            ),
          ),

          // ── Confirm button ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context, 'INSIDE'),
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.login_rounded,
                            color: AppColors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Confirm & Log Entry',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
