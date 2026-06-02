import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../config/roles.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'dashboard_screen.dart';
import 'pending_approval_screen.dart';
import 'register_screen.dart';
import 'login_screen.dart';

class OtpScreen extends StatefulWidget {
  final String mobile;
  const OtpScreen({super.key, required this.mobile});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await _authService.verifyOtp(
        widget.mobile,
        _otpController.text,
      );
      if (user != null && mounted) {
        if (user.status == UserStatus.pending) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const PendingApprovalScreen(),
            ),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(user: user),
            ),
            (route) => false,
          );
        }
      } else if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterScreen(mobile: widget.mobile),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        if (errorMsg.contains('Please register') ||
            errorMsg.contains('not found')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP verified. Please register your details.'),
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegisterScreen(mobile: widget.mobile),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMsg)));
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  late final AnimationController _glareCtrl;
  late final Animation<double> _glareAnim;

  @override
  void initState() {
    super.initState();
    _glareCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(min: 0, max: 1);
    _glareAnim = CurvedAnimation(parent: _glareCtrl, curve: Curves.slowMiddle);
  }

  @override
  void dispose() {
    _glareCtrl.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topHeight = size.height * 0.65;
    final bottomHeight = size.height * 0.35;
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
              Positioned(
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
                            SizedBox(height: 182 * ts),
                            Text(
                              'Smart\nNivaas',
                              style: AppTextStyles.brandHeading(ts),
                            ),
                            SizedBox(height: 14 * ts),
                            Container(
                              height: 3,
                              width: 64 * ts,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
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
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: bottomHeight,
                child: Container(color: AppColors.cardBackground),
              ),
              Positioned(
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
                        const target = 260.0;
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
                                'Verify OTP',
                                style: AppTextStyles.cardHeading(s),
                              ),
                              const Spacer(flex: 1),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8 * s,
                                runSpacing: 4 * s,
                                children: [
                                  Text(
                                    'Enter the 6-digit code sent to',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.cardSubtext(s),
                                  ),
                                  Text(
                                    widget.mobile,
                                    style: AppTextStyles.mobileHighlight(s),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginScreen(),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(24),
                                    child: Padding(
                                      padding: EdgeInsets.all(4 * s),
                                      child: Icon(
                                        Icons.edit,
                                        size: 18 * s,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(flex: 2),
                              _OtpField(controller: _otpController, scale: s),
                              const Spacer(flex: 3),
                              _VerifyOtpButton(
                                isLoading: _isLoading,
                                onPressed: _verifyOtp,
                                scale: s,
                                glareAnim: _glareAnim,
                              ),
                              const Spacer(flex: 1),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Didn't receive the code? ",
                                    style: AppTextStyles.cardSubtext(s * 0.88),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'OTP resent successfully',
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Resend OTP',
                                      style: AppTextStyles.cardSubtext(s * 0.88)
                                          .copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: AppColors.primary,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(flex: 2),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
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
                        width: 5,
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
                      Icons.lock,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpField extends StatefulWidget {
  final TextEditingController controller;
  final double scale;
  const _OtpField({required this.controller, this.scale = 1.0});

  @override
  State<_OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<_OtpField> {
  static const int _length = 6;

  late final List<TextEditingController> _cells;
  late final List<FocusNode> _focusNodes;

  double get s => widget.scale;

  @override
  void initState() {
    super.initState();
    _cells = List.generate(_length, (_) => TextEditingController());
    _focusNodes = List.generate(_length, (_) => FocusNode());

    final initial = widget.controller.text.trim();
    if (initial.isNotEmpty) {
      final digits = RegExp(
        r'\d',
      ).allMatches(initial).map((m) => m.group(0)!).toList();
      for (var i = 0; i < _length && i < digits.length; i++) {
        _cells[i].text = digits[i];
      }
    }

    for (var c in _cells) {
      c.addListener(_syncToParent);
    }
  }

  void _syncToParent() {
    final otp = _cells.map((c) => c.text).join();
    if (widget.controller.text != otp) widget.controller.text = otp;
  }

  void _handlePaste(String pasted) {
    final digits = RegExp(
      r'\d',
    ).allMatches(pasted).map((m) => m.group(0)!).toList();
    for (var i = 0; i < _length; i++) {
      _cells[i].text = i < digits.length ? digits[i] : '';
    }
    _syncToParent();
    if (digits.length >= _length) {
      FocusScope.of(context).requestFocus(_focusNodes[_length - 1]);
    } else {
      final next = digits.length;
      if (next < _length)
        FocusScope.of(context).requestFocus(_focusNodes[next]);
    }
  }

  @override
  void dispose() {
    for (var c in _cells) {
      c.removeListener(_syncToParent);
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
      decoration: BoxDecoration(
        color: AppColors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_length, (i) {
                return SizedBox(
                  width: 44 * s,
                  height: 44 * s,
                  child: Focus(
                    onKey: (node, event) {
                      if (event is RawKeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.backspace) {
                        if (_cells[i].text.isEmpty && i > 0) {
                          _focusNodes[i - 1].requestFocus();
                          _cells[i - 1].text = '';
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      focusNode: _focusNodes[i],
                      controller: _cells[i],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      style: AppTextStyles.otpDigit(s),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                        counterText: '',
                      ),
                      showCursor: false,
                      cursorColor: AppColors.primary,
                      cursorWidth: 0,
                      enableInteractiveSelection: false,
                      onChanged: (val) async {
                        if (val.length > 1) {
                          _handlePaste(val);
                          return;
                        }
                        if (val.isNotEmpty) {
                          if (i + 1 < _length) {
                            FocusScope.of(
                              context,
                            ).requestFocus(_focusNodes[i + 1]);
                          } else {
                            FocusScope.of(context).requestFocus(_focusNodes[i]);
                          }
                        }
                      },
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifyOtpButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final double scale;
  final Animation<double> glareAnim;
  const _VerifyOtpButton({
    required this.isLoading,
    required this.onPressed,
    this.scale = 1.0,
    required this.glareAnim,
  });

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return SizedBox(
      width: double.infinity,
      height: 45 * s,
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        elevation: 3,
        shadowColor: AppColors.primary.withValues(alpha: 0.5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: glareAnim,
                builder: (context, _) {
                  final buttonWidth =
                      MediaQuery.of(context).size.width - 40 * s;
                  final left = -80 + (glareAnim.value * (buttonWidth + 160));
                  return Positioned(
                    left: left,
                    top: 0,
                    bottom: 0,
                    child: Transform.rotate(
                      angle: -0.05,
                      child: Container(
                        width: 65 * s,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.white.withValues(alpha: 0.0),
                              AppColors.white.withValues(alpha: 0.28),
                              AppColors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              InkWell(
                onTap: isLoading ? null : onPressed,
                borderRadius: BorderRadius.circular(14),
                splashColor: AppColors.white.withValues(alpha: 0.15),
                highlightColor: AppColors.white.withValues(alpha: 0.08),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18 * s),
                  child: isLoading
                      ? Center(
                          child: SizedBox(
                            height: 22 * s,
                            width: 22 * s,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.white,
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            Icon(
                              Icons.check,
                              color: AppColors.white,
                              size: 20 * s,
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  'Verify & Login',
                                  style: AppTextStyles.buttonLabel(s),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward,
                              color: AppColors.white,
                              size: 20 * s,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
