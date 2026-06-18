import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/nest_loader.dart';

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
      AppColors.accentIndigo, // Indigo
      AppColors.accentIndigoDeep, // Deep Indigo
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
            color: (color ?? AppColors.accentIndigoDeep).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(
            child: isLoading
                ? const NestLoader(size: 32, showDots: false)
                : Text(
                    text,
                    style: textStyle ??
                        const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                          letterSpacing: 0.5,
                        ),
                  ),
          ),
        ),
      ),
    );
  }
}
