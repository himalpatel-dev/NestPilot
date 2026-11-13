import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/modules.dart';
import '../../services/community_service.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/nest_loader.dart';
import '../../widgets/app_field_card.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/glare_button.dart';
import '../../widgets/no_permission_notice.dart';

/// Unified Security Gate Terminal combining:
/// 1. Passcode Verification (Invited Guests)
/// 2. Walk-In / Delivery Logging
/// 3. Inside Now (Exit Control)
class GateControlScreen extends StatefulWidget {
  final int initialTabIndex;
  const GateControlScreen({super.key, this.initialTabIndex = 0});

  @override
  State<GateControlScreen> createState() => _GateControlScreenState();
}

class _GateControlScreenState extends State<GateControlScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canManage =
        PermissionService().canManage(ModuleCodes.gateControl) ||
        PermissionService().canManage(ModuleCodes.visitors);

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Column(
        children: [
          AppPageHeader(
            icon: Icons.security_rounded,
            title: 'Gate Control',
            accentColor: ModuleColors.verifyCode,
            subtitle: 'Manage visitor entries, passcodes & exits at the gate',
          ),
          if (!canManage)
            const Expanded(
              child: Center(
                child: NoPermissionNotice(action: 'manage gate security'),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: _buildTabBar(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _VerifyCodeTab(),
                  _WalkInEntryTab(),
                  _InsideNowTab(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Segmented tab bar: a white track (same border as the header's search
  /// field) with a dark pill that slides under the active tab and follows
  /// the page swipe.
  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      // Keeps the pill's shadow inside the track.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        dividerColor: AppColors.transparent,
        overlayColor: const WidgetStatePropertyAll(AppColors.transparent),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          _tab(Icons.vpn_key_rounded, 'Verify Code'),
          _tab(Icons.directions_walk_rounded, 'Walk-In'),
          _tab(Icons.groups_outlined, 'Inside Now'),
        ],
      ),
    );
  }

  Widget _tab(IconData icon, String label) {
    return Tab(
      height: 40,
      // Shrinks the label a touch on narrow phones instead of clipping it.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}

// ─── TAB 1: PASSCODE VERIFICATION ───────────────────────────────────────────

class _VerifyCodeTab extends StatefulWidget {
  const _VerifyCodeTab();

  @override
  State<_VerifyCodeTab> createState() => _VerifyCodeTabState();
}

class _VerifyCodeTabState extends State<_VerifyCodeTab> {
  final CommunityService _service = CommunityService();
  final _codeCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  bool _verifying = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _vehicleCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyEntry() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a 6-digit pass code')),
      );
      return;
    }
    setState(() => _verifying = true);
    try {
      final data = await _service.verifyPassCode(code);
      final visitor = data['Visitor'] as Map<String, dynamic>? ?? {};
      final house = data['House'] as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() => _verifying = false);

      final purpose = (data['purpose'] as String?)?.trim() ?? '';

      final result = await showDialog<String>(
        context: context,
        barrierColor: AppColors.black.withValues(alpha: 0.55),
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 36),
          child: _GuestCard(
            name: visitor['name'] as String? ?? 'Guest',
            mobile: visitor['mobile'] as String? ?? '—',
            visiting: house?['house_no'] as String? ?? '—',
            purpose: purpose.isNotEmpty ? purpose : null,
          ),
        ),
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
                result == 'INSIDE'
                    ? 'Visitor entry logged successfully'
                    : 'Entry denied',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: 20),
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
          const SizedBox(height: 24),
          GlarePrimaryButton(
            text: 'Verify & Log Entry',
            trailingIcon: Icons.check_circle_outline_rounded,
            isLoading: _verifying,
            onPressed: _verifyEntry,
            showGlare: true,
          ),
        ],
      ),
    );
  }
}

// ─── TAB 2: WALK-IN ENTRY ──────────────────────────────────────────────────

class _WalkInEntryTab extends StatefulWidget {
  const _WalkInEntryTab();

  @override
  State<_WalkInEntryTab> createState() => _WalkInEntryTabState();
}

class _WalkInEntryTabState extends State<_WalkInEntryTab> {
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
        final nums =
            houses.map<String>((h) => h['house_no'].toString()).toList()
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a flat')));
      return;
    }
    if (_selectedVisitorType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a visitor type')),
      );
      return;
    }

    final purpose = _purposeCtrl.text.trim();

    final result = await showDialog<String>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        child: _WalkInCard(
          name: _nameCtrl.text.trim(),
          mobile: _mobileCtrl.text.trim(),
          visiting: _selectedHouse!,
          visitorType: _selectedVisitorType!,
          purpose: purpose.isNotEmpty ? purpose : null,
        ),
      ),
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
              result == 'INSIDE' ? 'Entry logged successfully' : 'Entry denied',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _logging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingHouses) return const Center(child: NestLoader());

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const SizedBox(height: 20),
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
              icon: Icons.category_outlined,
              label: 'Visitor Type',
              field: AppCardDropdown<String>(
                value: _selectedVisitorType,
                hintText: 'Select type',
                items: _visitorTypes,
                itemLabel: (v) => v,
                validator: (v) =>
                    v == null ? 'Please select a visitor type' : null,
                onChanged: (v) => setState(() => _selectedVisitorType = v),
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
            const SizedBox(height: 24),
            GlarePrimaryButton(
              text: 'Log Entry',
              trailingIcon: Icons.login_rounded,
              isLoading: _logging,
              onPressed: _logWalkIn,
              showGlare: true,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TAB 3: INSIDE NOW (EXIT CONTROL) ───────────────────────────────────────

class _InsideNowTab extends StatefulWidget {
  const _InsideNowTab();

  @override
  State<_InsideNowTab> createState() => _InsideNowTabState();
}

class _InsideNowTabState extends State<_InsideNowTab> {
  final CommunityService _service = CommunityService();
  List<dynamic> _visitors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getInsideVisitors();
      if (mounted) {
        setState(() {
          _visitors = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmExit(int logId, String name) async {
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
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.40),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Mark Exit?',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.80),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  children: [
                    const Text(
                      'This will log the visitor as exited from the premises.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx, false),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentRed.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Mark Exit',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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

    if (confirmed == true) _markExit(logId);
  }

  Future<void> _markExit(int logId) async {
    try {
      await _service.logVisitorExit({
        'visitor_log_id': logId,
        'gate': 'Main Gate',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visitor marked as exited')),
        );
        _fetch();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: NestLoader());

    if (_visitors.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetch,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: 350,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.groups_outlined, color: AppColors.border, size: 56),
                SizedBox(height: 12),
                Text(
                  'No visitors inside right now',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pull down to refresh',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      color: AppColors.white,
      backgroundColor: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _visitors.length,
        itemBuilder: (ctx, i) {
          final log = _visitors[i];
          final visitor = log['Visitor'] as Map<String, dynamic>? ?? {};
          final house = log['House'] as Map<String, dynamic>?;
          final name = visitor['name'] as String? ?? 'Unknown';
          final mobile = visitor['mobile'] as String? ?? '—';
          final houseNo = house?['house_no'] as String? ?? '—';
          final logId = log['id'] as int?;
          final visitorType =
              (visitor['type'] ?? log['visitor_type']) as String?;
          final purpose = log['purpose'] as String?;

          String entryTime = '—';
          try {
            final t = DateTime.parse(log['entry_time'] as String);
            entryTime = DateFormat('hh:mm a').format(t);
          } catch (_) {}

          final initial = name.isNotEmpty ? name[0].toUpperCase() : 'V';

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (visitorType != null &&
                                visitorType.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentAmber.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.accentAmber.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  visitorType,
                                  style: const TextStyle(
                                    color: AppColors.accentAmber,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          purpose != null && purpose.isNotEmpty
                              ? 'Flat $houseNo · $purpose'
                              : 'Flat $houseNo',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$mobile  ·  Entry: $entryTime',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (logId != null)
                    GestureDetector(
                      onTap: () => _confirmExit(logId, name),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentRed,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentRed.withValues(
                                alpha: 0.28,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Mark Exit',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── DIALOG CARDS FOR VERIFY / WALK-IN ───────────────────────────────────────

class _GuestCard extends StatelessWidget {
  final String name;
  final String mobile;
  final String visiting;
  final String? purpose;

  const _GuestCard({
    required this.name,
    required this.mobile,
    required this.visiting,
    this.purpose,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'G';

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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
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
                            Icons.verified_user_outlined,
                            color: AppColors.white.withValues(alpha: 0.70),
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Invited Guest',
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Allow this visitor through the gate?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, 'DENIED'),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.accentRed.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accentRed.withValues(alpha: 0.30),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.block_rounded,
                            color: AppColors.accentRed,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Deny',
                            style: TextStyle(
                              color: AppColors.accentRed,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, 'INSIDE'),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentGreen.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Allow',
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: GestureDetector(
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
                    Icon(Icons.login_rounded, color: AppColors.white, size: 18),
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
