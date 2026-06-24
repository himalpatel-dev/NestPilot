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
  final int? maxLength;

  const AppBorderlessField({
    super.key,
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
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
        counterText: '',
      ),
    );
  }
}

/// Borderless dropdown for use inside an [AppFieldCard]. Generic over the
/// item type [T] so it works for plain strings, enums, or model objects.
///
/// Provide [items] as the raw values and [itemLabel] to render each one's
/// display text; pass a custom [itemBuilder] when a row needs more than text.
///
/// Unlike a raw [DropdownButtonFormField] this opens a polished rounded card
/// menu (soft shadow, padded rows, the selected row highlighted in a light
/// primary tint with a check) so the popup matches the app's card aesthetic.
/// The collapsed field is borderless to sit flush inside an [AppFieldCard].
class AppCardDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T?> onChanged;

  /// Placeholder shown when [value] is null. A plain hint string is the common
  /// case; pass [hint] for a custom widget.
  final String? hintText;
  final Widget? hint;
  final Widget Function(T value)? itemBuilder;

  /// When false the field is greyed out and taps are ignored (e.g. a building
  /// dropdown that waits for a society to be picked first).
  final bool enabled;

  /// Optional [Form] validator. When provided the field participates in form
  /// validation and renders an error line below itself on failure.
  final String? Function(T? value)? validator;

  const AppCardDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.hintText,
    this.hint,
    this.itemBuilder,
    this.enabled = true,
    this.validator,
  });

  void _open(BuildContext context, FormFieldState<T> field) {
    if (!enabled || items.isEmpty) return;
    showDropdownCardMenu<T>(
      context: context,
      value: value,
      items: items,
      itemLabel: itemLabel,
      itemBuilder: itemBuilder,
    ).then((selected) {
      if (selected != null) {
        field.didChange(selected);
        onChanged(selected);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (field) {
        // Keep the FormField's value in sync with the parent-controlled value.
        if (field.value != value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (field.mounted) field.didChange(value);
          });
        }

        final bool hasValue = value != null;
        final Widget label;
        if (hasValue) {
          label = itemBuilder != null
              ? itemBuilder!(value as T)
              : Text(
                  itemLabel(value as T),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                );
        } else {
          label =
              hint ??
              Text(
                hintText ?? 'Select',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint,
                ),
              );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: enabled ? () => _open(context, field) : null,
              borderRadius: BorderRadius.circular(8),
              child: Opacity(
                opacity: enabled ? 1 : 0.5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: label),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 4),
              Text(
                field.errorText!,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accentRed,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Opens a rounded card-style selection menu anchored under the tapped field
/// and resolves to the chosen item (or null if dismissed). Shared by
/// [AppCardDropdown] but usable directly for any tap-to-select surface.
///
/// The menu is a white rounded sheet with a soft shadow; each row is padded
/// and the currently-selected row is tinted in light primary with a trailing
/// check, matching the app's card design.
Future<T?> showDropdownCardMenu<T>({
  required BuildContext context,
  required T? value,
  required List<T> items,
  required String Function(T value) itemLabel,
  Widget Function(T value)? itemBuilder,
}) {
  final RenderBox button = context.findRenderObject() as RenderBox;
  final RenderBox overlay =
      Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;

  // Try to find the ancestor AppFieldCard element to match its size/alignment.
  Element? cardElement;
  context.visitAncestorElements((element) {
    if (element.widget is AppFieldCard) {
      cardElement = element;
      return false;
    }
    return true;
  });
  final RenderBox? cardBox = cardElement?.findRenderObject() as RenderBox?;

  // Use the card's dimensions if found, otherwise fall back to the dropdown button.
  final Offset topLeft = cardBox != null
      ? cardBox.localToGlobal(Offset.zero, ancestor: overlay)
      : button.localToGlobal(Offset.zero, ancestor: overlay);

  final Size targetSize = cardBox != null ? cardBox.size : button.size;

  return showGeneralDialog<T>(
    context: context,
    barrierLabel: 'dropdown',
    barrierColor: AppColors.black.withValues(alpha: 0.12),
    barrierDismissible: true,
    transitionDuration: const Duration(milliseconds: 140),
    pageBuilder: (_, a, b) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, secondary, child) {
      final Size screen = MediaQuery.of(ctx).size;
      // Prefer to drop below the field; flip above if there's no room.
      const double maxHeight = 280;
      const double gap = 6;
      final double belowSpace =
          screen.height - (topLeft.dy + targetSize.height) - 12;
      final bool dropUp = belowSpace < 160 && topLeft.dy > belowSpace;
      final double width = targetSize.width.clamp(160.0, screen.width - 24);
      double left = topLeft.dx;
      if (left + width > screen.width - 12) left = screen.width - 12 - width;
      if (left < 12) left = 12;

      final Widget menu = Container(
        constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: width),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Material(
            color: AppColors.white,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              shrinkWrap: true,
              children: items.map((item) {
                final bool selected = item == value;
                return InkWell(
                  onTap: () => Navigator.of(ctx).pop(item),
                  child: Container(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.10)
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: DefaultTextStyle.merge(
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                            child: itemBuilder != null
                                ? itemBuilder(item)
                                : Text(
                                    itemLabel(item),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );

      return Stack(
        children: [
          Positioned(
            left: left,
            width: width,
            top: dropUp ? null : topLeft.dy + targetSize.height + gap,
            bottom: dropUp ? screen.height - topLeft.dy + gap : null,
            child: FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                ),
                alignment: dropUp
                    ? Alignment.bottomCenter
                    : Alignment.topCenter,
                child: menu,
              ),
            ),
          ),
        ],
      );
    },
  );
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

/// Rounded white search field matching the [AppFieldCard] surface — a leading
/// search icon, a clear button while text is present, and the borderless input
/// styling the global inputDecorationTheme would otherwise override.
class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: TextField(
        controller: controller,
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
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: controller.clear,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
    );
  }
}

/// White rounded directory row matching the [AppFieldCard] surface — a tinted
/// circular icon chip, a bold title with an optional accent badge, a wrap of
/// muted subtitle chips, and an optional trailing widget (e.g. an edit button).
class AppListCard extends StatelessWidget {
  final Color accentColor;
  final IconData icon;
  final String title;
  final String? badgeText;
  final List<String> subtitleChips;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AppListCard({
    super.key,
    required this.accentColor,
    required this.icon,
    required this.title,
    this.badgeText,
    this.subtitleChips = const [],
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 20, color: accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (badgeText != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badgeText!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitleChips.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          runSpacing: 2,
                          children: [
                            for (final chip in subtitleChips)
                              Text(
                                chip,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered italic prompt shown when a directory needs a prior selection
/// (e.g. "Select a society above.") before any list can load.
class AppListPlaceholder extends StatelessWidget {
  final String message;

  const AppListPlaceholder(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

/// Centered icon + message shown when a loaded directory is empty or a search
/// returns no matches.
class AppListEmpty extends StatelessWidget {
  final IconData icon;
  final String message;

  const AppListEmpty({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.grey),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
