import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Primary action button with an optional sweeping "glare" highlight that
/// travels across the surface. Extracted verbatim from the Login / OTP
/// screens so every screen shares the same button design.
///
/// The glare animation is self-contained — the widget owns its own
/// [AnimationController]. Toggle it per use with [showGlare]: pass `true`
/// (default) for the animated sheen used on the login flow, or `false` for a
/// plain primary button with the same shape, color, and label styling. This
/// lets the same animation be reused or suppressed anywhere in the app.
///
///   GlarePrimaryButton(
///     text: 'Send OTP',
///     trailingIcon: Icons.send_rounded,
///     isLoading: _isLoading,
///     onPressed: _requestOtp,
///   )
class GlarePrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  /// Optional icon shown to the right of the label.
  final IconData? trailingIcon;

  /// Multiplier applied to sizes/paddings so the button can scale with a
  /// responsive layout (as the login/OTP screens do). Defaults to 1.0.
  final double scale;

  /// When true (default) the animated glare sweep runs across the button.
  /// Set false for a static primary button of the same design.
  final bool showGlare;

  const GlarePrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.trailingIcon,
    this.scale = 1.0,
    this.showGlare = true,
  });

  @override
  State<GlarePrimaryButton> createState() => _GlarePrimaryButtonState();
}

class _GlarePrimaryButtonState extends State<GlarePrimaryButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _glareCtrl;
  Animation<double>? _glareAnim;

  @override
  void initState() {
    super.initState();
    if (widget.showGlare) _startGlare();
  }

  void _startGlare() {
    _glareCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(min: 0, max: 1);
    _glareAnim = CurvedAnimation(parent: _glareCtrl!, curve: Curves.slowMiddle);
  }

  @override
  void didUpdateWidget(GlarePrimaryButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Honour runtime flips of showGlare.
    if (widget.showGlare && _glareCtrl == null) {
      _startGlare();
    } else if (!widget.showGlare && _glareCtrl != null) {
      _glareCtrl!.dispose();
      _glareCtrl = null;
      _glareAnim = null;
    }
  }

  @override
  void dispose() {
    _glareCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return SizedBox(
      width: double.infinity,
      height: 45 * s,
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        elevation: 3,
        shadowColor: AppColors.primary.withValues(alpha: 0.5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // ── Glare sweep ──────────────────────────────────────────
              if (_glareAnim != null)
                AnimatedBuilder(
                  animation: _glareAnim!,
                  builder: (context, _) {
                    final buttonWidth =
                        MediaQuery.of(context).size.width - 40 * s;
                    final left =
                        -80 + (_glareAnim!.value * (buttonWidth + 160));
                    return Positioned(
                      left: left,
                      top: 0,
                      bottom: 0,
                      child: Transform.rotate(
                        angle: -0.05,
                        child: Container(
                          width: 65 * s,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.white.withValues(alpha: 0.0),
                                AppColors.white.withValues(alpha: 0.28),
                                AppColors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              // ── Button content ────────────────────────────────────────
              InkWell(
                onTap: widget.isLoading ? null : widget.onPressed,
                borderRadius: BorderRadius.circular(14),
                splashColor: AppColors.white.withValues(alpha: 0.15),
                highlightColor: AppColors.white.withValues(alpha: 0.08),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18 * s),
                  child: widget.isLoading
                      ? Center(
                          child: SizedBox(
                            height: 22 * s,
                            width: 22 * s,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.white,
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: Text(
                                  widget.text,
                                  style: AppTextStyles.buttonLabel(s),
                                ),
                              ),
                            ),
                            if (widget.trailingIcon != null)
                              Icon(
                                widget.trailingIcon,
                                color: AppColors.white,
                                size: 20 * s,
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
