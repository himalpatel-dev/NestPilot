import 'package:flutter/material.dart';
import 'gate_control_screen.dart';

/// Legacy screen alias forwarding to the unified GateControlScreen (Verify Passcode Tab)
class VerifyPasscodeScreen extends StatelessWidget {
  const VerifyPasscodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GateControlScreen(initialTabIndex: 0);
  }
}
