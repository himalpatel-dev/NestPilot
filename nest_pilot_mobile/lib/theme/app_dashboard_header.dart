import 'package:flutter/material.dart';
import 'app_colors.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

class AppHeaderStat {
  const AppHeaderStat({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final IconData icon;
}

// ─── Back button helper ───────────────────────────────────────────────────────

Widget appHeaderBackButton(BuildContext context) {
  return GestureDetector(
    onTap: () => Navigator.maybePop(context),
    child: Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.20)),
      ),
      child: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: AppColors.white,
        size: 15,
      ),
    ),
  );
}

// ─── Header widget ────────────────────────────────────────────────────────────

class AppDashboardHeader extends StatelessWidget {
  const AppDashboardHeader({
    super.key,
    required this.title,
    this.subtitle = '',
    this.leftAction,
    this.preTitle,
    this.belowSubtitle,
    this.bottomSection,
    this.unreadCount = 0,
    this.onNotificationTap,
    this.stats = const [],
  });

  final String title;
  final String subtitle;

  /// Widget in the left of the nav row (back button, date text, etc.)
  final Widget? leftAction;

  /// Widget rendered just before the title (e.g. greeting line)
  final Widget? preTitle;

  /// Widget rendered below the subtitle (e.g. info chip)
  final Widget? belowSubtitle;

  /// Widget rendered in the stats slot (after the divider line).
  /// Use this to match the header height of stats-bearing tabs.
  final Widget? bottomSection;

  final int unreadCount;
  final VoidCallback? onNotificationTap;

  /// Pass an empty list (default) to hide the stats section entirely.
  final List<AppHeaderStat> stats;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    final cardW = MediaQuery.of(context).size.width - 32;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, safeTop + 10, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.55, 1.0],
              colors: [
                AppColors.heroGradientDeep,
                AppColors.primaryDark,
                AppColors.primary,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Faded building image on the right
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: cardW * 0.42,
                child: ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [0.0, 0.18, 1.0],
                    colors: [
                      AppColors.transparent,
                      Color(0x14FFFFFF),
                      Color(0x38FFFFFF),
                    ],
                  ).createShader(rect),
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    'assets/dash2.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                  ),
                ),
              ),
              // Card content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      16,
                      18,
                      (stats.isNotEmpty || bottomSection != null) ? 18 : 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nav row: left slot + notification bell
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            leftAction ?? const SizedBox.shrink(),
                            _NotifBell(
                              count: unreadCount,
                              onTap: onNotificationTap,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (preTitle != null) ...[
                          preTitle!,
                          const SizedBox(height: 3),
                        ],
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            height: 1.1,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.58),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                        if (belowSubtitle != null) ...[
                          const SizedBox(height: 12),
                          belowSubtitle!,
                        ],
                      ],
                    ),
                  ),
                  if (stats.isNotEmpty) ...[
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 18),
                      color: AppColors.white.withValues(alpha: 0.13),
                    ),
                    _StatsRow(stats: stats),
                  ] else if (bottomSection != null) ...[
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 18),
                      color: AppColors.white.withValues(alpha: 0.13),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 13, 16, 19),
                      child: bottomSection!,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Notification bell ────────────────────────────────────────────────────────

class _NotifBell extends StatelessWidget {
  const _NotifBell({required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.20)),
        ),
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              color: AppColors.white.withValues(alpha: 0.90),
              size: 22,
            ),
            if (count > 0)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.accentRed,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryDark,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat item ────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  const _StatItem({required this.stat});

  final AppHeaderStat stat;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, color: stat.color, size: 16),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stat.value,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    letterSpacing: -0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  stat.label,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.60),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 3-stat single row ────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final List<AppHeaderStat> stats;

  @override
  Widget build(BuildContext context) {
    final divider = Container(
      width: 1,
      height: 30,
      color: AppColors.white.withValues(alpha: 0.18),
      margin: const EdgeInsets.symmetric(horizontal: 10),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Row(
        children: [
          for (int i = 0; i < stats.length; i++) ...[
            if (i > 0) divider,
            _StatItem(stat: stats[i]),
          ],
        ],
      ),
    );
  }
}
