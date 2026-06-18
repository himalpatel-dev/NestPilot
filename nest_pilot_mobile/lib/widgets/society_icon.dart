import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Society mark — two apartment towers (a taller one beside a shorter one)
/// sharing a single ground line, each with a tidy column of evenly-spaced
/// windows. Deliberately spare: a strong two-tower silhouette that stays
/// crisp and legible at small sizes (~28px) instead of dissolving into
/// visual noise. Drawn with a CustomPainter so it scales without an SVG.
class SocietyIcon extends StatelessWidget {
  final double size;
  final Color color;

  const SocietyIcon({super.key, this.size = 24, this.color = AppColors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _SocietyIconPainter(color),
    );
  }
}

class _SocietyIconPainter extends CustomPainter {
  final Color color;

  const _SocietyIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double stroke = w * 0.07;
    final double r = w * 0.06;

    final Paint line = Paint()
      ..color = color
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final double ground = h * 0.88;

    RRect tower(double l, double t, double right) => RRect.fromRectAndRadius(
      Rect.fromLTRB(l, t, right, ground),
      Radius.circular(r),
    );

    // ---- Two towers: a tall left block and a shorter right block ----
    final RRect tall = tower(w * 0.16, h * 0.16, w * 0.52);
    final RRect short = tower(w * 0.52, h * 0.40, w * 0.84);

    canvas.drawRRect(tall, line);
    canvas.drawRRect(short, line);

    // ---- Windows: a single centered column of small dashes per tower ----
    void windows(RRect block, int count) {
      final double cx = block.left + (block.right - block.left) / 2;
      final double top = block.top + stroke * 1.6;
      final double bottom = ground - stroke * 1.6;
      final double span = bottom - top;
      final double winW = (block.right - block.left) * 0.34;
      // Distribute `count` windows evenly across the available vertical span.
      for (int i = 0; i < count; i++) {
        final double t = count == 1 ? 0.5 : i / (count - 1);
        final double cy = top + span * t;
        canvas.drawLine(
          Offset(cx - winW / 2, cy),
          Offset(cx + winW / 2, cy),
          line,
        );
      }
    }

    windows(tall, 4);
    windows(short, 3);

    // ---- Ground line: anchors both towers to a shared base ----
    canvas.drawLine(Offset(w * 0.08, ground), Offset(w * 0.92, ground), line);
  }

  @override
  bool shouldRepaint(_SocietyIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
