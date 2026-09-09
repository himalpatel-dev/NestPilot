import 'package:flutter/material.dart';
import 'gate_control_screen.dart';

/// Legacy screen alias forwarding to the unified GateControlScreen (Walk-In Tab)
class WalkInEntryScreen extends StatelessWidget {
  const WalkInEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GateControlScreen(initialTabIndex: 1);
  }
}
