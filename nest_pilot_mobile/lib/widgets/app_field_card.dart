import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Card-styled form field used on create/edit screens — a white rounded card
/// with a circular icon chip, an uppercase label, and a borderless field
/// (text input or dropdown) inside.
///
/// Extracted verbatim from the Society Create screen so every form screen
/// shares the exact same field design. Compose it as:
///
///   AppFieldCard(
///     icon: Icons.apartment_rounded,
///     label: 'Society Name',
///     field: AppBorderlessField(controller: ..., hint: ...),
///   )
class AppFieldCard extends StatelessWidget {
  static const Color _iconChipBg = AppColors.cardBackground;
  static const Color _iconColor = AppColors.primary;
  static const Color _fieldLabel = AppColors.textMuted;

  final IconData icon;
  final String label;
  final Widget field;
  final CrossAxisAlignment iconAlignment;

  const AppFieldCard({
    super.key,
    required this.icon,
    required this.label,
    required this.field,
    this.iconAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: iconAlignment,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: _iconChipBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: _iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: _fieldLabel,
                  ),
                ),
                const SizedBox(height: 2),
                field,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Borderless text field for use inside an [AppFieldCard]. The global
/// inputDecorationTheme injects a grey fill and outline border, so every
/// state is explicitly overridden here to keep the card's clean look.
class AppBorderlessField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;

  const AppBorderlessField({
    super.key,
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textHint,
        ),
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
      ),
    );
  }
}

/// Borderless dropdown for use inside an [AppFieldCard]. Generic over the
/// item type [T] so it works for plain strings, enums, or model objects.
///
/// Provide [items] as the raw values and [itemLabel] to render each one's
/// display text; pass a custom [itemBuilder] when a row needs more than text.
class AppCardDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T?> onChanged;
  final Widget? hint;
  final Widget Function(T value)? itemBuilder;

  const AppCardDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.hint,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isDense: true,
      isExpanded: true,
      hint: hint,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textSecondary,
      ),
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      dropdownColor: AppColors.white,
      decoration: const InputDecoration(
        isDense: true,
        filled: false,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: itemBuilder != null
              ? itemBuilder!(item)
              : Text(itemLabel(item)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

/// Small left-accent-bar section heading used above groups of form fields.
class AppSectionHeader extends StatelessWidget {
  final String title;

  const AppSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
