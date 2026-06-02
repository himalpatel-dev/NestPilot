import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFFFEC92D);
  static const Color primaryDark = Color(0xFF806514);
  static const Color primaryLight = Color(0xFFFEDB61);

  // Backgrounds
  static const Color cardBackground = Color(0xFFF8F1E5);
  static const Color white = Colors.white;
  static const Color transparent = Colors.transparent;
  static const Color black = Colors.black;

  // Text
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF757575); // grey.shade600
  static const Color textHint = Color(0xFF9E9E9E); // grey.shade500
  static const Color textMuted = Color(0xFF5E7388); // blue-grey muted

  // State
  static const Color warning = Color(0xFFB57047);
  static const Color success = Color(0xFF16A34A);

  // Borders & dividers
  static const Color border = Color(0xFFE0E0E0); // grey.shade300
  static const Color dividerOnDark = Color(0x3DFFFFFF); // white ~24%

  // Shadows
  static const Color textShadow = Color(0xFF1A1A1A);

  // Dashboard — dark background / surface
  static const Color dashBg = Color(0xFF000000);

  // Dashboard — compact tile surface gradient layers
  static const Color tileSurfaceHigh = Color(0xFF26262E);
  static const Color tileSurfaceMid = Color.fromARGB(230, 13, 13, 13);
  static const Color tileSurfaceLow = Color(0xFF0D0D0D);

  // Dashboard — cinematic hero gradient overlay stops
  static const Color heroOverlayTop = Color(0x88000000);
  static const Color heroOverlayMid = Color(0xCC000000);

  // Accent palette — per-module icon colors
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentPurple = Color(0xFFA855F7);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentBrown = Color(0xFF8B5A3C);
}
