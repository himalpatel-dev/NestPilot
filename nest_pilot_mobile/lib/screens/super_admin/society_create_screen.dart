import 'package:flutter/material.dart';
import '../../services/society_service.dart';
import '../../services/permission_service.dart';
import '../../config/modules.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/no_permission_notice.dart';
import '../../widgets/society_icon.dart';

class SocietyCreateScreen extends StatefulWidget {
  const SocietyCreateScreen({super.key});

  @override
  State<SocietyCreateScreen> createState() => _SocietyCreateScreenState();
}

class _SocietyCreateScreenState extends State<SocietyCreateScreen> {
  static const Color _pageBg = AppColors.cardBackground;
  static const Color _iconChipBg = AppColors.cardBackground;
  static const Color _iconColor = AppColors.primary;
  static const Color _fieldLabel = AppColors.textMuted;
  static const Color _accent = AppColors.primary;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  String _selectedSocietyType = 'APARTMENT';
  final List<String> _societyTypes = [
    'APARTMENT',
    'TENEMENT',
    'ROW_HOUSE',
    'COMMERCIAL',
    'MIXED',
  ];

  final SocietyService _societyService = SocietyService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _createSociety() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final success = await _societyService.createSociety(
        name: _nameController.text,
        address: _addressController.text,
        city: _cityController.text,
        state: _stateController.text,
        pincode: _pincodeController.text,
        societyType: _selectedSocietyType,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Society created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: Column(
        children: [
          _buildTopHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionHeader('Basic Information'),
                    const SizedBox(height: 12),
                    _fieldCard(
                      icon: Icons.apartment_rounded,
                      label: 'Society Name',
                      field: _borderlessField(
                        controller: _nameController,
                        hint: 'e.g. Kesharkunj Residency',
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _fieldCard(
                      icon: Icons.map_outlined,
                      label: 'Society Type',
                      field: _societyTypeDropdown(),
                    ),
                    const SizedBox(height: 24),
                    _sectionHeader('Location'),
                    const SizedBox(height: 12),
                    _fieldCard(
                      icon: Icons.place_outlined,
                      label: 'Address',
                      iconAlignment: CrossAxisAlignment.start,
                      field: _borderlessField(
                        controller: _addressController,
                        hint: 'Street, area',
                        maxLines: 3,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _fieldCard(
                            icon: Icons.location_city_outlined,
                            label: 'City',
                            field: _borderlessField(
                              controller: _cityController,
                              hint: 'City',
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _fieldCard(
                            icon: Icons.tag_rounded,
                            label: 'Pincode',
                            field: _borderlessField(
                              controller: _pincodeController,
                              hint: '000000',
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _fieldCard(
                      icon: Icons.public_rounded,
                      label: 'State',
                      field: _borderlessField(
                        controller: _stateController,
                        hint: 'State',
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (PermissionService().canCreate(ModuleCodes.buildings))
                      AppButton(
                        text: 'Create Society',
                        isLoading: _isLoading,
                        onPressed: _createSociety,
                        borderRadius: 28,
                        gradientColors: const [
                          AppColors.primary,
                          AppColors.primaryDark,
                        ],
                      )
                    else
                      const NoPermissionNotice(action: 'create societies'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.55, 1.0],
          colors: [
            AppColors.heroGradientDeep,
            AppColors.primaryDark,
            AppColors.primary,
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        child: Stack(
          children: [
            Positioned(top: -46, right: -34, child: _decorCircle(150, 0.06)),
            Positioned(top: 42, right: 70, child: _decorCircle(26, 0.10)),
            Positioned.fill(
              child: CustomPaint(
                painter: _SkylinePainter(
                  AppColors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.16),
                            ),
                          ),
                          child: const Text(
                            'SOCIETY SETUP',
                            style: TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.16),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const SocietyIcon(
                            size: 28,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add New Society',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tell us about your new community',
                                style: TextStyle(
                                  color: Color(0xB3FFFFFF),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorCircle(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: alpha),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _fieldCard({
    required IconData icon,
    required String label,
    required Widget field,
    CrossAxisAlignment iconAlignment = CrossAxisAlignment.center,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: iconAlignment,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: _iconChipBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: _iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: _fieldLabel,
                  ),
                ),
                const SizedBox(height: 2),
                field,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // The global inputDecorationTheme injects a grey fill and outline border,
  // so every state must be overridden for the card's borderless look.
  Widget _borderlessField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textHint,
        ),
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
      ),
    );
  }

  Widget _societyTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedSocietyType,
      isDense: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textSecondary,
      ),
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      dropdownColor: AppColors.white,
      decoration: const InputDecoration(
        isDense: true,
        filled: false,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
      ),
      items: _societyTypes.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type.replaceAll('_', ' ')),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedSocietyType = val);
      },
    );
  }
}

/// Faint skyline of towers and houses anchored to the bottom of the header.
class _SkylinePainter extends CustomPainter {
  final Color color;

  const _SkylinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint paint = Paint()
      ..color = color
      ..isAntiAlias = true;

    void tower(double x, double tw, double th) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x * w, h - th * h, tw * w, th * h),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        paint,
      );
    }

    void house(double x, double hw, double hh) {
      final double left = x * w;
      final double width = hw * w;
      final double top = h - hh * h;
      final double roofBase = top + hh * h * 0.45;
      final Path path = Path()
        ..moveTo(left, h)
        ..lineTo(left, roofBase)
        ..lineTo(left + width / 2, top)
        ..lineTo(left + width, roofBase)
        ..lineTo(left + width, h)
        ..close();
      canvas.drawPath(path, paint);
    }

    tower(0.02, 0.06, 0.26);
    house(0.10, 0.07, 0.20);
    tower(0.19, 0.05, 0.36);
    tower(0.26, 0.07, 0.22);
    house(0.35, 0.06, 0.18);
    tower(0.43, 0.06, 0.32);
    tower(0.51, 0.05, 0.20);
    house(0.58, 0.07, 0.24);
    tower(0.67, 0.06, 0.38);
    tower(0.75, 0.05, 0.24);
    house(0.82, 0.06, 0.18);
    tower(0.90, 0.06, 0.30);
    tower(0.98, 0.04, 0.20);
  }

  @override
  bool shouldRepaint(_SkylinePainter oldDelegate) =>
      oldDelegate.color != color;
}
