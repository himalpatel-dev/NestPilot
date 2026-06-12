import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single source of truth for the app font.
///
/// To switch the whole app to another Google Font (e.g. Arial → 'Arimo',
/// Roboto, Inter, ...), change ONLY [_fontName] below — nothing else.
///
/// Never hardcode a `fontFamily` on any screen; everything inherits it from
/// the app theme (see `main.dart`), or use [AppFonts.fontFamily] /
/// [AppFonts.style] when an explicit family is unavoidable.
abstract final class AppFonts {
  /// ── CHANGE THE APP FONT HERE (Google Fonts name) ──
  static const String _fontName = 'Lexend Deca';

  /// Resolved family name of [_fontName] from the google_fonts package.
  static String get fontFamily => GoogleFonts.getFont(_fontName).fontFamily!;

  /// App font text theme — applied app-wide via [ThemeData.textTheme].
  static TextTheme textTheme([TextTheme? base]) =>
      GoogleFonts.getTextTheme(_fontName, base ?? ThemeData.light().textTheme);

  /// App font [TextStyle] helper for one-off styles that need an explicit
  /// family (e.g. styles with `inherit: false`).
  static TextStyle style({
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
    TextDecoration? decoration,
  }) => GoogleFonts.getFont(
    _fontName,
    textStyle: textStyle,
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
    height: height,
    shadows: shadows,
    decoration: decoration,
  );
}
