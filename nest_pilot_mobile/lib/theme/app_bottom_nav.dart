import 'package:flutter/material.dart';
import 'app_colors.dart';

/// A single tab entry for [AppBottomNav].
class AppNavItem {
  final IconData icon;
  final String label;
  const AppNavItem(this.icon, this.label);
}

/// Floating glassmorphism bottom navigation bar with smooth animated indicator.
/// The spotlight and icon/label colours animate as you switch tabs.
class AppBottomNav extends StatefulWidget {
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
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  Animation<double> _slideAnim = const AlwaysStoppedAnimation(0);
  int _fromIndex = 0;
  int _toIndex = 0;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.selectedIndex;
    _toIndex = widget.selectedIndex;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _slideAnim = AlwaysStoppedAnimation(widget.selectedIndex.toDouble());
  }

  @override
  void didUpdateWidget(AppBottomNav old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) {
      _fromIndex = old.selectedIndex;
      _toIndex = widget.selectedIndex;
      _slideAnim = Tween<double>(
        begin: _fromIndex.toDouble(),
        end: _toIndex.toDouble(),
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.transparent,
      padding: EdgeInsets.only(bottom: widget.bottomPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            color: AppColors.transparent,
            border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabW = constraints.maxWidth / widget.items.length;
              return AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  final t = _ctrl.value;
                  final pos = _slideAnim.value;
                  return Stack(
                    children: [
                      // Sliding spotlight — follows the animated position
                      Positioned(
                        left: pos * tabW,
                        width: tabW,
                        top: 0,
                        bottom: 0,
                        child: CustomPaint(
                          painter: _SpotlightPainter(color: AppColors.primary),
                        ),
                      ),

                      // Tab items
                      Row(
                        children: List.generate(widget.items.length, (i) {
                          final isTo = i == _toIndex;
                          final isFrom = i == _fromIndex;

                          // 0 = unselected, 1 = selected colour
                          final double colorT;
                          if (isTo) {
                            colorT = Curves.easeOut.transform(t);
                          } else if (isFrom && _fromIndex != _toIndex) {
                            colorT = 1.0 - Curves.easeIn.transform(t);
                          } else {
                            colorT = 0.0;
                          }

                          final double scale;
                          if (isTo) {
                            scale =
                                1.0 + 0.12 * Curves.easeOutBack.transform(t);
                          } else if (isFrom && _fromIndex != _toIndex) {
                            scale = 1.12 - 0.12 * Curves.easeIn.transform(t);
                          } else {
                            scale = 1.0;
                          }

                          final iconColor = Color.lerp(
                            AppColors.textSecondary,
                            AppColors.primary,
                            colorT,
                          )!;
                          final labelColor = Color.lerp(
                            AppColors.textSecondary,
                            AppColors.primary,
                            colorT,
                          )!;
                          final labelWeight = FontWeight.lerp(
                            FontWeight.w500,
                            FontWeight.w700,
                            colorT,
                          )!;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () => widget.onTap(i),
                              behavior: HitTestBehavior.opaque,
                              child: SizedBox(
                                height: 64,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Transform.scale(
                                      scale: scale,
                                      child: Icon(
                                        widget.items[i].icon,
                                        size: 22,
                                        color: iconColor,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      widget.items[i].label,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: labelWeight,
                                        color: labelColor,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              );
            },
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
    final trapezoid = Path()
      ..moveTo(size.width * 0.35, 0)
      ..lineTo(size.width * 0.65, 0)
      ..lineTo(size.width * 0.95, size.height)
      ..lineTo(size.width * 0.05, size.height)
      ..close();

    final conePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.18),
          AppColors.primary.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(trapezoid, conePaint);

    final double barW = size.width * 0.55;
    final double barX = (size.width - barW) / 2;
    const double barH = 4.0;
    const double barR = 4.0;

    final glowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX - 6, 0, barW + 12, barH + 6),
        const Radius.circular(barR),
      ),
      glowPaint,
    );

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
