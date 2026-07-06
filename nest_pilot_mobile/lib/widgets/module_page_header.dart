import 'package:flutter/material.dart';
import '../screens/notification_list_screen.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';

/// One stat pill shown inside the module card ("3 / OPEN").
class ModuleHeaderStat {
  final String value;
  final String label;
  const ModuleHeaderStat(this.value, this.label);
}

/// Light page header used on module list screens:
///
///   ← Complaints                    🔔
///     Palm Meadows · Secretary
///   ┌──────────────────────────────────┐
///   │ [icon]  Complaints               │
///   │         Raise & track issues     │
///   │  [3 OPEN] [18 RESOLVED] [2 ...]  │
///   └──────────────────────────────────┘
///
/// The context line (society · role) comes from [SessionService].
class ModulePageHeader extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;

  /// Custom icon widget (used instead of [icon]) — e.g. painted icons.
  final Widget? iconWidget;
  final Color iconColor;
  final List<ModuleHeaderStat> stats;
  final bool showBack;
  final VoidCallback? onBack;

  /// Optional action widget shown left of the bell in the top bar.
  final Widget? trailing;

  /// Optional widget rendered below the module card (e.g. tabs).
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
  }) : assert(icon != null || iconWidget != null,
            'Provide either icon or iconWidget');

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final contextLine = SessionService().contextLine;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top bar: back · title/context · bell ─────────────────────
          Row(
            children: [
              if (showBack) ...[
                _circleButton(
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                  onTap: onBack ?? () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (contextLine.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        contextLine,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
          // ── Module card: icon · title/description · stats ────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: iconWidget ??
                          Icon(icon, color: iconColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (description != null &&
                              description!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              description!,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12.5,
                                height: 1.35,
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
                if (stats.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (int i = 0; i < stats.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(child: _statPill(stats[i])),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (bottom != null) ...[
            const SizedBox(height: 14),
            bottom!,
          ],
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

  Widget _statPill(ModuleHeaderStat stat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
