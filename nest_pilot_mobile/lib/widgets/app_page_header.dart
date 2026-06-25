import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable inner-screen header — the gradient hero bar used on detail/create
/// pages. Carries the back button, a chip-framed icon, a title and subtitle,
/// plus the faint skyline backdrop and decorative circles.
///
/// Extracted verbatim from the Society Create screen so every inner screen
/// shares the exact same design. Per-page parts come in as parameters:
///   - [icon]      : the symbol shown inside the chip (e.g. SocietyIcon,
///                   or an Icon(...)). Sized/colored by the caller.
///   - [title]     : main heading text.
///   - [subtitle]  : supporting line under the title (optional).
///   - [onBack]    : back-button tap; defaults to Navigator.pop.
///   - [showBack]  : hide the back button when false.
///   - [trailing]  : optional widget pinned to the right of the back-button row
///                   (e.g. an action button).
///   - [bottom]    : optional widget rendered below the title block, still
///                   inside the gradient (e.g. a search bar or tabs).
class AppPageHeader extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final bool showBack;
  final Widget? trailing;
  final Widget? bottom;

  const AppPageHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onBack,
    this.showBack = true,
    this.trailing,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        child: Stack(
          children: [
            // Right-side illustrated scene — moon, apartment towers, trees and
            // birds — drawn entirely with a CustomPainter (no image asset, so
            // it adds no decode/memory cost and scales crisply).
            const Positioned.fill(
              child: CustomPaint(painter: _HeaderScenePainter()),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showBack || trailing != null)
                      Row(
                        children: [
                          if (showBack)
                            GestureDetector(
                              onTap: onBack ?? () => Navigator.pop(context),
                              child: Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.reply_rounded,
                                  color: AppColors.white,
                                  size: 26,
                                ),
                              ),
                            ),
                          if (trailing != null) ...[const Spacer(), trailing!],
                        ],
                      ),
                    if (showBack || trailing != null)
                      const SizedBox(height: 22),
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.16),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: icon,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle!,
                                  style: const TextStyle(
                                    color: AppColors.whiteTranslucent,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (bottom != null) ...[
                      const SizedBox(height: 18),
                      bottom!,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Right-side illustrated scene for the header, matching the reference design:
/// a few soft puffy clouds, a tight cluster of warm cream / beige flat-roof
/// apartment blocks of varying heights with neat window grids, and a row of
/// rounded trees in two greens at the base. A clean, light, daytime look
/// painted purely with vector shapes (no image asset) so it costs nothing to
/// decode and scales crisply.
///
/// All coordinates are fractions of the canvas so the scene adapts to the
/// header's size. It hugs the right edge; the left is left clear for the
/// title block.
class _HeaderScenePainter extends CustomPainter {
  const _HeaderScenePainter();

  // ── Flat daytime palette (reads against the navy header gradient) ──────
  static const Color _cloud = Color(0xFFD9DEE6); // soft solid cloud grey-white
  static const Color _wallCream = Color(0xFFF1E9D8); // brightest face
  static const Color _wallSand = Color(0xFFE3D6BC); // mid sand face
  static const Color _wallTan = Color(0xFFCBB994); // shaded / warm tan
  static const Color _wallPale = Color(0xFFF7F2E8); // tall pale block
  static const Color _roof = Color(0xFFB05C3B); // terracotta pitched roof
  static const Color _window = Color(0x59243B55); // soft navy windows
  static const Color _trunk = Color(0xFF7E6347);
  static const Color _leafA = Color(0xFF9DBE93); // light sage canopy
  static const Color _leafB = Color(0xFF7FA277); // deeper green canopy

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint p = Paint()..isAntiAlias = true;

    canvas.clipRect(Offset.zero & size);

    final double ground = h; // buildings sit flush to the header bottom

    // ── Clouds (one solid puff: overlapping circles form the bumpy top,
    // a rectangle clamps the bottom into a sharp flat edge — like the
    // reference) ───────────────────────────────────────────────────────
    // [cx] horizontal centre, [baseY] the flat bottom line, [s] scale. All
    // shapes share one colour so they merge into a single cloud.
    void cloud(double cx, double baseY, double s) {
      p.color = _cloud;
      // Bumpy top: a big central hump flanked by two smaller side humps.
      canvas.drawCircle(Offset(cx, baseY - s * 0.8), s * 0.95, p);
      canvas.drawCircle(Offset(cx - s * 1.05, baseY - s * 0.4), s * 0.62, p);
      canvas.drawCircle(Offset(cx + s * 1.0, baseY - s * 0.45), s * 0.66, p);
      // Flat bottom: a rectangle that fills under the humps up to baseY,
      // giving the cloud its straight base edge.
      canvas.drawRect(
        Rect.fromLTRB(cx - s * 1.6, baseY - s * 0.55, cx + s * 1.6, baseY),
        p,
      );
    }

    cloud(w * 0.60, h * 0.22, h * 0.038);
    cloud(w * 0.86, h * 0.15, h * 0.048);

    // Helper: a flat-roof apartment block with a tidy window grid.
    void block(
      double leftF,
      double rightF,
      double topF,
      Color face, {
      bool windows = true,
      int cols = 3,
    }) {
      final double left = leftF * w;
      final double right = rightF * w;
      final double top = topF * h;
      final Rect r = Rect.fromLTRB(left, top, right, ground);
      final RRect rrect = RRect.fromRectAndCorners(
        r,
        topLeft: Radius.circular(w * 0.012),
        topRight: Radius.circular(w * 0.012),
      );
      canvas.drawRRect(rrect, p..color = face);
      // Border outline
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = AppColors.primaryLight.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..isAntiAlias = true,
      );
      if (!windows) return;
      // Even grid of small rounded windows.
      p.color = _window;
      final double ww = r.width * 0.16;
      final double wh = ww * 1.15;
      final double gapX = (r.width - cols * ww) / (cols + 1);
      final int rows = ((r.height - wh) / (wh * 1.7)).floor().clamp(1, 6);
      final double gapY = wh * 0.7;
      for (int c = 0; c < cols; c++) {
        for (int rr = 0; rr < rows; rr++) {
          final double x = r.left + gapX * (c + 1) + ww * c;
          final double y = r.top + wh * 0.7 + rr * (wh + gapY);
          if (y + wh > ground) break;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, ww, wh),
              Radius.circular(ww * 0.22),
            ),
            p,
          );
        }
      }
    }

    // ── Building cluster (back-to-front, varied heights) ───────────────
    // Short tan block tucked behind on the left of the cluster.
    block(0.65, 0.75, 0.62, AppColors.primary.withOpacity(0.7), cols: 2);

    // Tall pale tower — the hero of the cluster.
    block(0.75, 0.86, 0.30, AppColors.primary.withOpacity(0.6), cols: 2);

    // Mid cream block.
    block(0.86, 1, 0.47, AppColors.primary.withOpacity(0.8), cols: 2);

    // ── Rounded trees along the base (two greens, varied sizes) ────────
    void tree(double cxF, double scale, Color leaf) {
      final double cx = cxF * w;
      final double canopyR = h * 0.085 * scale;
      final double topY = ground - canopyR * 1.4;
      // Trunk
      p.color = _trunk;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, ground - canopyR * 0.4),
            width: w * 0.013 * scale,
            height: canopyR * 1.6,
          ),
          Radius.circular(w * 0.01),
        ),
        p,
      );
      // Round canopy (two overlapping circles for a soft bushy top)
      p.color = leaf;
      canvas.drawCircle(Offset(cx, topY), canopyR, p);
      canvas.drawCircle(
        Offset(cx - canopyR * 0.5, topY + canopyR * 0.3),
        canopyR * 0.7,
        p,
      );
      canvas.drawCircle(
        Offset(cx + canopyR * 0.5, topY + canopyR * 0.3),
        canopyR * 0.7,
        p,
      );
    }

    tree(0.83, 0.65, _leafB);
    tree(0.93, 0.85, _leafA);
  }

  @override
  bool shouldRepaint(_HeaderScenePainter oldDelegate) => false;
}
