import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/glare_button.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController(
    text: '9999999999',
  );
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _requestOtp() async {
    if (_mobileController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await _authService.requestOtp(
        _mobileController.text,
        'LOGIN',
      );
      if (success && mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, animation, secondaryAnimation) =>
                OtpScreen(mobile: _mobileController.text),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    ),
                    child: child,
                  );
                },
          ),
        );
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
    final size = MediaQuery.of(context).size;
    final topHeight = size.height * 0.65;
    final bottomHeight = size.height * 0.35;
    // Reference design at ~800px tall; scale top overlay text accordingly.
    final ts = (size.height / 800).clamp(0.78, 1.15);

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final cardTop = ((topHeight - 40) - keyboardHeight).clamp(
      safeAreaTop + 40,
      double.infinity,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.cardBackground,
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // Top 70% — background image with overlay text
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                top: -keyboardHeight * 0.6,
                left: 0,
                right: 0,
                height: topHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/login.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(28, 50 * ts, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 148 * ts),
                            Text(
                              'Smart\nNivaas',
                              style: AppTextStyles.brandHeading(ts),
                            ),
                            SizedBox(height: 20 * ts),

                            SizedBox(height: 18 * ts),
                            Text(
                              'Connected Living Made Simple',
                              style: AppTextStyles.brandSubtitle(ts),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom 30% — cream background fill (matches card)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: bottomHeight,
                child: Container(color: AppColors.cardBackground),
              ),
              // Rounded card overlapping the seam
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                top: cardTop,
                left: 0,
                right: 0,
                bottom: keyboardHeight,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const target = 237.0;
                        final available = constraints.maxHeight;
                        final s = (available / target).clamp(0.55, 1.05);
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8 * s,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Spacer(flex: 3),
                              Text(
                                'Let’s get you started',
                                style: AppTextStyles.cardHeading(s),
                              ),
                              const Spacer(flex: 1),
                              Text(
                                'Enter your mobile number to login',
                                style: AppTextStyles.cardSubtext(s),
                              ),
                              const Spacer(flex: 2),
                              _MobileNumberField(
                                controller: _mobileController,
                                scale: s,
                              ),
                              const Spacer(flex: 3),
                              GlarePrimaryButton(
                                text: 'Send OTP',
                                trailingIcon: Icons.send_rounded,
                                isLoading: _isLoading,
                                onPressed: _requestOtp,
                                scale: s,
                              ),
                              const Spacer(flex: 2),
                              Text.rich(
                                TextSpan(
                                  text: 'By continuing, you agree to our ',
                                  style: AppTextStyles.cardSubtext(s * 0.82),
                                  children: [
                                    TextSpan(
                                      text: 'Terms',
                                      style: AppTextStyles.cardSubtext(s * 0.82)
                                          .copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const TextSpan(text: ' & '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: AppTextStyles.cardSubtext(s * 0.82)
                                          .copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8 * s),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Center shield badge sitting on the seam
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                top: cardTop - 25,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      border: Border.all(
                        color: AppColors.cardBackground,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.house,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              // Custom loader overlay
              //   if (_isLoading) const Positioned.fill(child: NestLoadingOverlay()),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileNumberField extends StatelessWidget {
  final TextEditingController controller;
  final double scale;
  const _MobileNumberField({required this.controller, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 5 * s),
      child: Row(
        children: [
          Container(
            width: 38 * s,
            height: 38 * s,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.phone_iphone,
              color: AppColors.white,
              size: 22 * s,
            ),
          ),
          SizedBox(width: 10 * s),
          SizedBox(width: 8 * s),
          Container(width: 1, height: 24 * s, color: AppColors.primary),
          SizedBox(width: 8 * s),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: AppTextStyles.inputText(s),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: '00000 00000',
                hintStyle: AppTextStyles.hintText(s),
                filled: false,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.symmetric(vertical: 10 * s),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
