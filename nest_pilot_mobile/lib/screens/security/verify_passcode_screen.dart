import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import '../../services/permission_service.dart';
import '../../config/modules.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_field_card.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/glare_button.dart';
import '../../widgets/no_permission_notice.dart';

class VerifyPasscodeScreen extends StatefulWidget {
  const VerifyPasscodeScreen({super.key});

  @override
  State<VerifyPasscodeScreen> createState() => _VerifyPasscodeScreenState();
}

class _VerifyPasscodeScreenState extends State<VerifyPasscodeScreen> {
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

      final purpose = (data['purpose'] as String?)?.trim() ?? '';

      final result = await _showConfirmDialog(
        name: visitor['name'] ?? '—',
        mobile: visitor['mobile'] ?? '—',
        visiting: house?['house_no'] ?? '—',
        purpose: purpose.isNotEmpty ? purpose : null,
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

  Future<String?> _showConfirmDialog({
    required String name,
    required String mobile,
    required String visiting,
    String? purpose,
  }) {
    return showDialog<String>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        child: _GuestCard(
          name: name,
          mobile: mobile,
          visiting: visiting,
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
              Icons.vpn_key_rounded,
              color: AppColors.white,
              size: 28,
            ),
            title: 'Verify Pass Code',
            subtitle: 'Check a resident\'s pre-approved invite',
          ),
          Expanded(
            child: canCreate
                ? SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  AppColors.accentGreen.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.accentGreen
                                      .withValues(alpha: 0.15),
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

// ─── Visiting-card guest sheet ────────────────────────────────────────────────

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
          // ── Card header ──────────────────────────────────────────────────
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              children: [
                // Avatar
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

          // ── Detail rows ──────────────────────────────────────────────────
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

          // ── Prompt text ──────────────────────────────────────────────────
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

          // ── Action buttons ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              children: [
                // Deny
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
                          Icon(Icons.block_rounded,
                              color: AppColors.accentRed, size: 18),
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
                // Allow
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
                            color: AppColors.accentGreen.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle_outline_rounded,
                              color: AppColors.white, size: 18),
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
