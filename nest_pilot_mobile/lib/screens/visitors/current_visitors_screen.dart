import 'package:flutter/material.dart';
import 'gate_control_screen.dart';

/// Legacy screen alias forwarding to the unified GateControlScreen (Inside Now Tab)
class CurrentVisitorsScreen extends StatelessWidget {
  const CurrentVisitorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GateControlScreen(initialTabIndex: 2);
  }
}
