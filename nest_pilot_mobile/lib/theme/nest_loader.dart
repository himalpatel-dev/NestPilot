import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Animated house-construction loader themed for NestPilot.
/// Set [showDots] to false for compact inline use (e.g. inside buttons).
class NestLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final bool showDots;

  const NestLoader({super.key, this.size = 72, this.color, this.showDots = true});

  @override
  State<NestLoader> createState() => _NestLoaderState();
}

class _NestLoaderState extends State<NestLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final col = widget.color ?? AppColors.primary;
    final dotSz = widget.size * 0.09;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = _ctrl.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _HousePainter(t: t, color: col),
            ),
            if (widget.showDots) ...[
              SizedBox(height: dotSz * 0.9),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final phase = t * math.pi * 6 - i * (math.pi * 2 / 3);
                  final bounce = math.sin(phase) * 0.5 + 0.5;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: dotSz * 0.5),
                    child: Transform.translate(
                      offset: Offset(0, -dotSz * bounce),
                      child: Opacity(
                        opacity: 0.35 + 0.65 * bounce,
                        child: Container(
                          width: dotSz,
                          height: dotSz,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: col,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Full-screen semi-opaque overlay. Drop into a Stack over your content.
class NestLoadingOverlay extends StatelessWidget {
  final bool visible;
  const NestLoadingOverlay({super.key, this.visible = true});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Container(
      color: AppColors.cardBackground.withValues(alpha: 0.88),
      child: const Center(child: NestLoader(size: 84)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HousePainter extends CustomPainter {
  final double t;
  final Color color;

  const _HousePainter({required this.t, required this.color});

  /// Map global [t] into 0..1 over sub-interval [start, end], with optional curve.
  double _phase(double start, double end, [Curve curve = Curves.easeInOut]) {
    final raw = ((t - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(raw);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sw = w * 0.048;

    // ── Key geometry ──────────────────────────────────────────────────
    final bl = Offset(w * 0.10, h * 0.92);
    final br = Offset(w * 0.90, h * 0.92);
    final wallTR = Offset(w * 0.90, h * 0.50);
    final wallTL = Offset(w * 0.10, h * 0.50);
    final eaveR = Offset(w * 0.97, h * 0.50);
    final eaveL = Offset(w * 0.03, h * 0.50);
    final peak = Offset(w * 0.50, h * 0.07);

    // ── Phase 1 (0.00 – 0.56): Trace outline ─────────────────────────
    // Order: BL → BR → wallTR → eaveR → peak → eaveL → wallTL → BL
    final p1 = _phase(0.00, 0.56);
    if (p1 > 0) {
      _drawPartial(
        canvas,
        Path()
          ..moveTo(bl.dx, bl.dy)
          ..lineTo(br.dx, br.dy)
          ..lineTo(wallTR.dx, wallTR.dy)
          ..lineTo(eaveR.dx, eaveR.dy)
          ..lineTo(peak.dx, peak.dy)
          ..lineTo(eaveL.dx, eaveL.dy)
          ..lineTo(wallTL.dx, wallTL.dy)
          ..lineTo(bl.dx, bl.dy),
        p1,
        _mkStroke(color, sw),
      );
    }

    // ── Phase 2 (0.45 – 0.66): House fill fades in ───────────────────
    final p2 = _phase(0.45, 0.66, Curves.easeIn);
    if (p2 > 0) {
      canvas.drawPath(
        Path()
          ..moveTo(bl.dx, bl.dy)
          ..lineTo(br.dx, br.dy)
          ..lineTo(wallTR.dx, wallTR.dy)
          ..lineTo(eaveR.dx, eaveR.dy)
          ..lineTo(peak.dx, peak.dy)
          ..lineTo(eaveL.dx, eaveL.dy)
          ..lineTo(wallTL.dx, wallTL.dy)
          ..close(),
        _mkFill(color.withValues(alpha: 0.13 * p2)),
      );
    }

    // ── Phase 3 (0.56 – 0.72): Arched door traces in ─────────────────
    final p3 = _phase(0.56, 0.72, Curves.easeOut);
    if (p3 > 0) {
      final dW = w * 0.21;
      final dH = h * 0.28;
      _drawPartial(
        canvas,
        Path()
          ..addRRect(RRect.fromRectAndCorners(
            Rect.fromLTWH(w * 0.50 - dW / 2, h * 0.92 - dH, dW, dH),
            topLeft: Radius.circular(dW / 2),
            topRight: Radius.circular(dW / 2),
          )),
        p3,
        _mkStroke(color.withValues(alpha: p3), sw * 0.88),
      );
    }

  }

  /// Draws only the first [t] fraction (0..1) of [path].
  void _drawPartial(Canvas canvas, Path path, double t, Paint paint) {
    if (t <= 0) return;
    if (t >= 1) {
      canvas.drawPath(path, paint);
      return;
    }
    final metrics = path.computeMetrics().toList();
    final total = metrics.fold(0.0, (s, m) => s + m.length);
    var remaining = total * t;
    for (final m in metrics) {
      if (remaining <= 0) break;
      final take = remaining.clamp(0.0, m.length);
      canvas.drawPath(m.extractPath(0, take), paint);
      remaining -= m.length;
    }
  }

  Paint _mkStroke(Color c, double width) => Paint()
    ..color = c
    ..strokeWidth = width
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint _mkFill(Color c) => Paint()
    ..color = c
    ..style = PaintingStyle.fill;

  @override
  bool shouldRepaint(_HousePainter old) =>
      old.t != t || old.color != color;
}
