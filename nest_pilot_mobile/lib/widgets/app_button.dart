import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? color;
  final List<Color>? gradientColors;
  final double height;
  final double? width;
  final double borderRadius;
  final TextStyle? textStyle;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.gradientColors,
    this.height = 54,
    this.width,
    this.borderRadius = 14,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasGradient = gradientColors != null || color == null;
    final defaultGradient = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF4F46E5), // Deep Indigo
    ];

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: hasGradient ? null : (color ?? theme.colorScheme.primary),
        gradient: hasGradient
            ? LinearGradient(
                colors: gradientColors ?? defaultGradient,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: (color ?? const Color(0xFF4F46E5)).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    text,
                    style: textStyle ??
                        const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                  ),
          ),
        ),
      ),
    );
  }
}
