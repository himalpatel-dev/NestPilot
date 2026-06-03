import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Shared Quick-Action tile: a compact glass card with a colored icon and a
/// short label centered below.
///
/// Pass `color`, `icon`, `label` (and optionally `iconSize`). Wrap in a
/// GestureDetector at the call site if you want it tappable.
///
/// Edit this file to restyle every quick-action icon tile in the app.
class AppIconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final double iconSize;

  /// Overall tile height. Defaults to the quick-action card size (88).
  /// Pass a smaller value (e.g. 72) for denser grids like the services hub.
  final double height;

  const AppIconTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    this.iconSize = 26,
    this.height = 88,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18);
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.white.withValues(alpha: 0.12),
                  AppColors.white.withValues(alpha: 0.03),
                ],
              ),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: iconSize),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
