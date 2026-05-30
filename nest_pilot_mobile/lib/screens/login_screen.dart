import 'package:flutter/material.dart';
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
    final topHeight = size.height * 0.65;
    final bottomHeight = size.height * 0.35;
    // Reference design at ~800px tall; scale top overlay text accordingly.
    final ts = (size.height / 800).clamp(0.78, 1.15);

    return Scaffold(
      backgroundColor: _cardBg,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Top 70% — background image with overlay text
            Positioned(
              top: 0,
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
                      padding: EdgeInsets.fromLTRB(28, 60 * ts, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16 * ts,
                              vertical: 10 * ts,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.55),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.home_outlined,
                                  color: Colors.white,
                                  size: 18 * ts,
                                ),
                                SizedBox(width: 8 * ts),
                                Text(
                                  'NEST PILOT',
                                  style: TextStyle(
                                    fontSize: 13 * ts,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 28 * ts),
                          Text(
                            'Smart\nNivaas',
                            style: TextStyle(
                              fontSize: 64 * ts,
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
                ],
              ),
            ),
            // Bottom 30% — cream background fill (matches card)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: bottomHeight,
              child: Container(color: _cardBg),
            ),
            // Rounded card overlapping the seam
            Positioned(
              top: topHeight - 40,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Target content height at scale 1.0 (without bottom padding):
                      //   topPad(28) + heading(20) + gap(4) + sub(13) + gap(12)
                      //   + field(56) + gap(10) + button(52) + gap(8)
                      //   + divider(14) + gap(6) + footer(14) = ~237
                      // Scale = available / target, clamped to a safe range.
                      const target = 237.0;
                      final available = constraints.maxHeight;
                      final s = (available / target).clamp(0.55, 1.05);
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          28 * s,
                          20,
                          8 * s,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Let’s get you started',
                              style: TextStyle(
                                fontSize: 20 * s,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            SizedBox(height: 4 * s),
                            Text(
                              'Enter your mobile number to login',
                              style: TextStyle(
                                fontSize: 13 * s,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 12 * s),
                            _MobileNumberField(
                              controller: _mobileController,
                              scale: s,
                            ),
                            SizedBox(height: 10 * s),
                            _SendOtpButton(
                              isLoading: _isLoading,
                              onPressed: _requestOtp,
                              scale: s,
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.shade300,
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8 * s,
                                  ),
                                  child: Icon(
                                    Icons.shield_outlined,
                                    size: 14 * s,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.shade300,
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6 * s),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 12 * s,
                                    color: Colors.grey.shade500,
                                  ),
                                  SizedBox(width: 6 * s),
                                  Text(
                                    'By continuing, you agree to our ',
                                    style: TextStyle(
                                      fontSize: 11 * s,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    'Terms & Privacy Policy',
                                    style: TextStyle(
                                      fontSize: 11 * s,
                                      color: _primaryBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Center shield badge sitting on the seam
            Positioned(
              top: topHeight - 72,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _primaryBlue,
                    border: Border.all(color: _cardBg, width: 5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield,
                    color: Colors.white,
                    size: 28,
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

class _MobileNumberField extends StatelessWidget {
  final TextEditingController controller;
  final double scale;
  const _MobileNumberField({required this.controller, this.scale = 1.0});

  static const Color _primaryBlue = Color(0xFF4A6589);

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 5 * s),
      child: Row(
        children: [
          Container(
            width: 38 * s,
            height: 38 * s,
            decoration: BoxDecoration(
              color: _primaryBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.phone_iphone,
              color: Colors.white,
              size: 22 * s,
            ),
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
              controller: controller,
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
