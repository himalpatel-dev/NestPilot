import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import '../screens/notification_list_screen.dart';
import '../theme/app_colors.dart';

/// One stat shown in the bar under the hero card ("24 / ACTIVE").
class ModuleHeaderStat {
  final String value;
  final String label;
  const ModuleHeaderStat(this.value, this.label);
}

/// Universal inner-page header:
///
///   (←)  Palm Meadows · Secretary            (🔔)
///   ┌──────────────────────────────────────────┐
///   │ [icon chip]                              │
///   │ Notices                                  │
///   │ Broadcast updates to all residents       │
///   └───┬──────────────────────────────────┬───┘
///       │ (24 ACTIVE) 12 PENDING  158 READ │
///       └──────────────────────────────────┘
///
/// A bold hero card tinted with the module accent (white icon + title +
/// description) and, when [stats] are given, a light stats bar overlapping
/// the card's bottom edge with the first stat highlighted as a white pill.
/// The context line (society · role) comes from [SessionService].
class ModulePageHeader extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;

  /// Custom icon widget (used instead of [icon]) — e.g. painted icons.
  /// Rendered on the colored hero, so it should read well in white.
  final Widget? iconWidget;

  /// Module accent — used as the hero card background.
  final Color iconColor;
  final List<ModuleHeaderStat> stats;
  final bool showBack;
  final VoidCallback? onBack;

  /// Optional action widget shown left of the bell in the top bar.
  final Widget? trailing;

  /// Optional widget rendered below the header (e.g. section chips).
  final Widget? bottom;

  const ModulePageHeader({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.iconWidget,
    required this.iconColor,
    this.stats = const [],
    this.showBack = true,
    this.onBack,
    this.trailing,
    this.bottom,
  }) : assert(
         icon != null || iconWidget != null,
         'Provide either icon or iconWidget',
       );

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top bar: back · trailing action · notification bell ──────
          Row(
            children: [
              if (showBack)
                _circleButton(
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                  onTap: onBack ?? () => Navigator.pop(context),
                ),
              const Spacer(),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: 8),
              ],
              _circleButton(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.accentOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationListScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ── Hero card — same light pastel tint as the dashboard tiles ─
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              stats.isNotEmpty ? 36 : 22,
            ),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child:
                      iconWidget ??
                      Icon(
                        icon,
                        color: Color.lerp(iconColor, AppColors.black, 0.25),
                        size: 26,
                      ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (description != null && description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Frosted translucent stats bar overlapping the hero ───────
          if (stats.isNotEmpty)
            Container(
              transform: Matrix4.translationValues(0, -18, 0),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      children: [
                        for (int i = 0; i < stats.length; i++) ...[
                          if (i > 0)
                            Container(
                              width: 1,
                              height: 34,
                              color: AppColors.border.withValues(alpha: 0.6),
                            ),
                          Expanded(child: _statCell(stats[i])),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (bottom != null) ...[const SizedBox(height: 14), bottom!],
        ],
      ),
    );
  }

  Widget _circleButton({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  Widget _statCell(ModuleHeaderStat stat) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stat.label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          stat.value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
