import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final int maxLines;
  final int? maxLength;
  final void Function(String)? onChanged;
  
  // Customization styling options for premium dark & glass layouts
  final Color? fillColor;
  final Color? textColor;
  final Color? labelColor;
  final Color? prefixIconColor;
  final Color? enabledBorderColor;
  final Color? focusedBorderColor;
  final TextStyle? textStyle;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.fillColor,
    this.textColor,
    this.labelColor,
    this.prefixIconColor,
    this.enabledBorderColor,
    this.focusedBorderColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lColor = labelColor;
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      style: textStyle ?? (textColor != null ? TextStyle(color: textColor) : null),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: lColor != null ? TextStyle(color: lColor) : null,
        hintText: hint,
        hintStyle: lColor != null ? TextStyle(color: lColor.withOpacity(0.6)) : null,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: prefixIconColor ?? theme.colorScheme.primary) : null,
        filled: true,
        fillColor: fillColor ?? theme.inputDecorationTheme.fillColor ?? AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: enabledBorderColor ?? AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: enabledBorderColor ?? AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: focusedBorderColor ?? theme.colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}
