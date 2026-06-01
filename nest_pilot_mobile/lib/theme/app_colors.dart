import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF4A6589);
  static const Color primaryDark = Color(0xFF334A66);
  static const Color primaryLight = Color(0xFF65798C);
  static const Color accent = Color(0xFFC9A86A);
  static const Color badgeGold = Color(0xFFDCAE6C);

  // Backgrounds
  static const Color cardBackground = Color(0xFFF8F1E5);
  static const Color white = Colors.white;
  static const Color transparent = Colors.transparent;
  static const Color black = Colors.black;

  // Text
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF757575); // grey.shade600
  static const Color textHint = Color(0xFF9E9E9E);      // grey.shade500
  static const Color textMuted = Color(0xFF5E7388);     // blue-grey muted

  // State
  static const Color warning = Color(0xFFB57047);
  static const Color success = Color(0xFF16A34A);

  // Borders & dividers
  static const Color border = Color(0xFFE0E0E0);         // grey.shade300
  static const Color dividerOnDark = Color(0x3DFFFFFF);  // white ~24%

  // Shadows
  static const Color textShadow = Color(0x66000000);
}
