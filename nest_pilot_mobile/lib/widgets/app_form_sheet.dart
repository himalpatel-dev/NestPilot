import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Opens a form bottom sheet with the app's standard modal chrome — pair it
/// with an [AppFormSheet] as the builder's root so every add/edit flow gets
/// the same rounded top, backdrop colour and full-height scroll behaviour.
///
///   void _openCreateSheet() {
///     showAppFormSheet(
///       context: context,
///       builder: (ctx) => _CreateThingSheet(
///         onCreated: () {
///           Navigator.pop(ctx);
///           _load();
///         },
///       ),
///     );
///   }
Future<T?> showAppFormSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: builder,
  );
}

/// The shell every create/edit bottom sheet sits inside — drag handle, an
/// accent icon chip with title/subtitle, a red close button, and a scrolling
/// body that lifts clear of the keyboard.
///
/// Extracted verbatim from the Events "New Event" sheet so every module's add
/// flow shares the exact same design. Pass the form itself as [child]; it is
/// placed inside the scroll view, so it must not scroll on its own.
class AppFormSheet extends StatelessWidget {
  /// Module accent — tints the icon chip. Use the module's [ModuleColors] entry.
  final Color accentColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const AppFormSheet({
    super.key,
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final maxH = MediaQuery.of(context).size.height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Header row: accent icon chip · title/subtitle · close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: Color.lerp(accentColor, AppColors.black, 0.25),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: AppColors.accentRed,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline error banner for use inside an [AppFormSheet]. A modal sheet renders
/// on top of any snackbar, so API failures must be surfaced in the sheet
/// itself — never via [ScaffoldMessenger].
class AppSheetErrorBanner extends StatelessWidget {
  final String message;

  const AppSheetErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.accentRed,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.accentRed,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tap-to-pick card matching [AppFieldCard] — icon chip, uppercase label, and
/// the selected [value] (or [hint]) with a chevron. Use for date/time pickers
/// and any other field whose value comes from a dialog rather than the
/// keyboard. Set [error] to outline the card in red after a failed submit.
class AppPickerCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String hint;
  final VoidCallback onTap;
  final bool error;

  const AppPickerCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: error
              ? Border.all(color: AppColors.accentRed, width: 1.4)
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: AppColors.primary),
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
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasValue ? value! : hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
                      color: hasValue
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// Themes the date/time picker dialogs with the app's primary colour so the
/// header, selected day/time and buttons match the rest of the app. Pass it
/// straight to `showDatePicker(builder: appPickerTheme)`.
Widget appPickerTheme(BuildContext context, Widget? child) {
  return Theme(
    data: Theme.of(context).copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        onSurface: AppColors.textPrimary,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.white,
        dialHandColor: AppColors.primary,
        dialBackgroundColor: AppColors.cardBackground,
        hourMinuteColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.cardBackground,
        ),
        hourMinuteTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textPrimary,
        ),
        // AM / PM selector — solid primary when selected, white text.
        dayPeriodColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.transparent,
        ),
        dayPeriodTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.white
              : AppColors.textSecondary,
        ),
        dayPeriodBorderSide: const BorderSide(color: AppColors.border),
        entryModeIconColor: AppColors.primary,
      ),
    ),
    child: child!,
  );
}
