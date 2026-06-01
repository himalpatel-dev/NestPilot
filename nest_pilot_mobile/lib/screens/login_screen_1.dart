import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import '../services/auth_service.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  static const Color _primaryBlue = Color(0xFF4A6589);
  static const Color _cardBg = Color(0xFFF8F1E5);

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
          MaterialPageRoute(
            builder: (context) => OtpScreen(mobile: _mobileController.text),
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
    final topHeight = size.height * 0.75;
    // Reference design at ~800px tall; scale top overlay text accordingly.
    final ts = (size.height / 800).clamp(0.78, 1.15);

    return Scaffold(
      backgroundColor: _cardBg,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Full Screen Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/login2.png',
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
              ),
            ),

            // Top overlay text stack (covering top 70%)
            Positioned(
              top: -50,
              left: 0,
              right: 0,
              height: topHeight,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(28, 0, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 180 * ts),
                      Text(
                        'Smart\nNivaas',
                        style: TextStyle(
                          fontSize: 50 * ts,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.02,
                          letterSpacing: 0.5,
                          shadows: const [
                            Shadow(
                              color: Color(0x66000000),
                              blurRadius: 12,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14 * ts),
                      Container(
                        height: 3,
                        width: 64 * ts,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC9A86A),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: 18 * ts),
                      Text(
                        'Connected Living Made Simple',
                        style: TextStyle(
                          fontSize: 15 * ts,
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Rounded card overlapping the seam with Glassmorphic cream effect
            Positioned(
              top: topHeight - 90,
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 28.0, sigmaY: 28.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _cardBg.withValues(
                        alpha: 0.60,
                      ), // Frosted cream background with enhanced transparency
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: 0.50,
                        ), // Enhanced edge border highlight
                        width: 1.5,
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Target content height at scale 1.0 (without bottom padding):
                          //   topPad(32) + heading(22) + gap(8) + sub(14) + gap(24)
                          //   + field(52) + gap(16) + button(52) + bottomPad(16) = ~236
                          // Scale = available / target, clamped to a safe range.
                          const target = 236.0;
                          final available = constraints.maxHeight;
                          final s = (available / target).clamp(0.60, 1.0);
                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              24,
                              32 * s,
                              24,
                              16 * s,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Let’s get you started',
                                  style: TextStyle(
                                    fontSize: 22 * s,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1F2937),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                SizedBox(height: 8 * s),
                                Text(
                                  'Enter your mobile number to login',
                                  style: TextStyle(
                                    fontSize: 14 * s,
                                    color: Colors.grey.shade600,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                SizedBox(height: 24 * s),
                                _MobileNumberField(
                                  controller: _mobileController,
                                  scale: s,
                                ),
                                SizedBox(height: 16 * s),
                                _SendOtpButton(
                                  isLoading: _isLoading,
                                  onPressed: _requestOtp,
                                  scale: s,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileNumberField extends StatefulWidget {
  final TextEditingController controller;
  final double scale;
  const _MobileNumberField({required this.controller, this.scale = 1.0});

  @override
  State<_MobileNumberField> createState() => _MobileNumberFieldState();
}

class _MobileNumberFieldState extends State<_MobileNumberField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  static const Color _primaryBlue = Color(0xFF4A6589);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isFocused ? _primaryBlue : Colors.grey.shade300,
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _isFocused
                ? _primaryBlue.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: _isFocused ? 12 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 8 * s,
        vertical: _isFocused
            ? (5 * s - 0.5)
            : 5 * s, // offset vertical padding slightly to preserve size
      ),
      child: Row(
        children: [
          Container(
            width: 38 * s,
            height: 38 * s,
            decoration: BoxDecoration(
              color: _primaryBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.phone_iphone, color: Colors.white, size: 22 * s),
          ),
          SizedBox(width: 10 * s),
          Text(
            '+91',
            style: TextStyle(
              fontSize: 16 * s,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(width: 8 * s),
          Container(width: 1, height: 24 * s, color: Colors.grey.shade300),
          SizedBox(width: 8 * s),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: TextStyle(
                fontSize: 16 * s,
                color: const Color(0xFF1F2937),
              ),
              decoration: InputDecoration(
                hintText: 'Mobile Number',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16 * s,
                ),
                border: InputBorder.none,
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

class _SendOtpButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final double scale;
  const _SendOtpButton({
    required this.isLoading,
    required this.onPressed,
    this.scale = 1.0,
  });

  static const Color _primaryBlue = Color(0xFF4A6589);

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return SizedBox(
      width: double.infinity,
      height: 52 * s,
      child: Material(
        color: _primaryBlue,
        borderRadius: BorderRadius.circular(14),
        elevation: 2,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18 * s),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      height: 22 * s,
                      width: 22 * s,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Icon(Icons.send, color: Colors.white, size: 20 * s),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Send Verification OTP',
                            style: TextStyle(
                              fontSize: 16 * s,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20 * s,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
