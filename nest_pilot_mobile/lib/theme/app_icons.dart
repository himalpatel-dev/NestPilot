import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Shared Quick-Action tile: circular gradient icon with white symbol,
/// colored drop-shadow, and a short label below.
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

  const AppIconTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    // Derive a lighter start-stop for the gradient by blending toward white
    final lightColor = Color.lerp(AppColors.white, color, 0.55)!;

    // Fixed layout: circle area (top) + label area (bottom, fixed height).
    // Both regions have a set height so all tiles align perfectly regardless
    // of whether the label wraps to 1 or 2 lines.
    const double circleSize = 52;
    const double gap = 8;
    const double labelAreaHeight =
        30; // fits 2 lines at font 11, line-height 1.3

    return SizedBox(
      height: circleSize + gap + labelAreaHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [lightColor, color],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.20),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.white, size: iconSize),
          ),
          const SizedBox(height: gap),
          SizedBox(
            height: labelAreaHeight,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
