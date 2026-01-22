import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../config/roles.dart';
import 'dashboard_screen.dart';
import 'pending_approval_screen.dart';
import 'register_screen.dart';

class OtpScreen extends StatefulWidget {
  final String mobile;
  const OtpScreen({super.key, required this.mobile});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
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
        // If user is null, it might mean they need to register
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterScreen(mobile: widget.mobile),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the 6-digit code sent to ${widget.mobile}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            AppTextField(
              controller: _otpController,
              label: 'OTP',
              hint: '6-digit code',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.lock_outline,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Verify & Login',
              isLoading: _isLoading,
              onPressed: _verifyOtp,
            ),
          ],
        ),
      ),
    );
  }
}
