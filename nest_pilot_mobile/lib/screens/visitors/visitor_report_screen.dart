import 'package:flutter/material.dart';
import 'visitor_management_screen.dart';

/// Legacy alias widget forwarding to the unified VisitorManagementScreen
class VisitorReportScreen extends StatelessWidget {
  const VisitorReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const VisitorManagementScreen();
  }
}
