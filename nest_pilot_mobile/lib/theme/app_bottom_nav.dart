import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// A single tab entry for [AppBottomNav].
class AppNavItem {
  final IconData icon;
  final String label;
  const AppNavItem(this.icon, this.label);
}

/// Floating glassmorphism bottom navigation bar.
/// BackdropFilter blurs content behind the pill; the surface is a
/// semi-transparent dark layer with a white hairline border.
/// Changing this file updates every screen that uses it.
class AppBottomNav extends StatelessWidget {
  final List<AppNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final double bottomPadding;

  const AppBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    this.bottomPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.transparent,
      padding: EdgeInsets.fromLTRB(10, 8, 10, bottomPadding + 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: 65,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.transparent.withValues(alpha: 0.12),
                  AppColors.white.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.10),
                width: 1,
              ),
            ),
            child: Row(
              children: List.generate(items.length, (i) {
                final selected = i == selectedIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      height: 64,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Triangular cone spotlight
                          if (selected)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _SpotlightPainter(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),

                          // Icon + label
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                items[i].icon,
                                size: 22,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.white.withValues(alpha: 0.55),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                items[i].label,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.white.withValues(alpha: 0.50),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the triangular spotlight cone + glowing indicator bar.
class _SpotlightPainter extends CustomPainter {
  final Color color;
  const _SpotlightPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Cone — narrow at top, wide at bottom
    final trapezoid = Path()
      ..moveTo(size.width * 0.35, 0)
      ..lineTo(size.width * 0.65, 0)
      ..lineTo(size.width * 0.85, size.height)
      ..lineTo(size.width * 0.15, size.height)
      ..close();

    final conePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.white.withValues(alpha: 0.18),
          AppColors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(trapezoid, conePaint);

    // Indicator bar
    final double barW = size.width * 0.48;
    final double barX = (size.width - barW) / 2;
    const double barH = 4.0;
    const double barR = 4.0;

    // Soft white glow halo
    final glowPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX - 6, 0, barW + 12, barH + 6),
        const Radius.circular(barR),
      ),
      glowPaint,
    );

    // Solid primary bar
    final barPaint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, 0, barW, barH),
        const Radius.circular(barR),
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.color != color;
}
