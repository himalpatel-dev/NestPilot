import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Module card used on the unified dashboard — a tappable [AppIconTile], so
/// the dashboard grid and the services hub render the exact same tile.
///
/// Edit [AppIconTile] to restyle every module tile in the app.
class AppModuleCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  const AppModuleCard({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AppIconTile(icon: icon, color: color, label: label),
    );
  }
}

/// The single module/quick-action tile used everywhere (dashboard grid,
/// services hub, bills shortcuts): soft pastel rounded tile tinted with the
/// module accent, the darkened colored icon on it, and the label below —
/// identical on every screen and for every role.
///
/// Edit this class to restyle every module tile in the app.
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
    this.iconSize = 33,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: Center(
              child: Icon(
                icon,
                color: Color.lerp(color, AppColors.black, 0.25),
                size: iconSize,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 16,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
