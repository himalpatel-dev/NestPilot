import 'package:flutter/material.dart';

/// Vector "gated society" mark — twin apartment towers flanking an entrance
/// gate, echoing the society renders in assets/. Drawn with a CustomPainter
/// so it scales crisply at any size without an SVG dependency.
class SocietyIcon extends StatelessWidget {
  final double size;
  final Color color;

  const SocietyIcon({super.key, this.size = 24, this.color = Colors.white});

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
    final Paint paint = Paint()
      ..color = color
      ..isAntiAlias = true;

    // Windows are punched out of the towers, so compose on a layer.
    canvas.saveLayer(Offset.zero & size, Paint());

    final Radius towerRadius = Radius.circular(w * 0.06);

    // Twin towers
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.14, w * 0.30, h * 0.86),
        towerRadius,
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.70, h * 0.14, w * 0.30, h * 0.86),
        towerRadius,
      ),
      paint,
    );

    // Gate canopy beam between the towers
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.26, h * 0.50, w * 0.48, h * 0.12),
        Radius.circular(h * 0.05),
      ),
      paint,
    );

    // Gate bars below the beam
    for (int i = 0; i < 3; i++) {
      final double x = w * (0.36 + i * 0.12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, h * 0.60, w * 0.05, h * 0.40),
          Radius.circular(w * 0.025),
        ),
        paint,
      );
    }

    // Punch out windows: 2 columns x 3 rows per tower
    final Paint clear = Paint()
      ..blendMode = BlendMode.clear
      ..isAntiAlias = true;
    final Radius windowRadius = Radius.circular(w * 0.02);
    for (int col = 0; col < 2; col++) {
      for (int row = 0; row < 3; row++) {
        final double y = h * (0.22 + row * 0.18);
        final double leftX = w * (0.055 + col * 0.115);
        final double rightX = w * (0.755 + col * 0.115);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(leftX, y, w * 0.075, h * 0.09),
            windowRadius,
          ),
          clear,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(rightX, y, w * 0.075, h * 0.09),
            windowRadius,
          ),
          clear,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SocietyIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
