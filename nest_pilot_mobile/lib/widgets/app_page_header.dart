import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'module_page_header.dart';

/// Inner-screen page header — legacy API kept so existing screens work
/// unchanged, now rendering the universal light [ModulePageHeader] design:
/// circular back button, page title with the society · role context line,
/// notification bell, and the white module card (icon chip + description).
///
/// Callers historically pass an `Icon(...)` with a baked-in size. To keep the
/// header icon size universal, a plain [Icon] is unwrapped to its [IconData]
/// and rendered through [ModulePageHeader]'s central `icon` path (so the size
/// comes from [ModulePageHeader.iconSize], not the caller). Custom painted
/// icons (e.g. SocietyIcon) fall back to the widget path, recolored to a
/// darker shade of [accentColor]. Pass a module accent via [accentColor].
class AppPageHeader extends StatelessWidget {
  /// The module icon. Pass an [IconData] only — its size and colour come from
  /// [ModulePageHeader] (universal), never from the calling screen.
  final IconData? icon;

  /// Custom painted icon (e.g. SocietyIcon) for the rare case where an
  /// [IconData] won't do. Scaled to [ModulePageHeader.iconSize] automatically.
  final Widget? iconWidget;

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final bool showBack;
  final Widget? trailing;
  final Widget? bottom;
  final Color accentColor;

  /// Set false to hide the search field on this page while keeping the rest
  /// of the header unchanged.
  final bool showSearch;
  final String searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;

  const AppPageHeader({
    super.key,
    this.icon,
    this.iconWidget,
    required this.title,
    this.subtitle,
    this.onBack,
    this.showBack = true,
    this.trailing,
    this.bottom,
    this.accentColor = AppColors.primary,
    this.showSearch = false,
    this.searchHint = 'Search...',
    this.searchController,
    this.onSearchChanged,
  }) : assert(
         icon != null || iconWidget != null,
         'Provide either icon or iconWidget',
       );

  @override
  Widget build(BuildContext context) {
    return ModulePageHeader(
      title: title,
      description: subtitle,
      icon: icon,
      iconWidget: icon != null
          ? null
          // Custom painted icon — scale it to the universal
          // ModulePageHeader.iconSize so it follows the central size too.
          : SizedBox(
              width: ModulePageHeader.iconSize,
              height: ModulePageHeader.iconSize,
              child: FittedBox(
                fit: BoxFit.contain,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Color.lerp(accentColor, AppColors.black, 0.25)!,
                    BlendMode.srcIn,
                  ),
                  child: iconWidget!,
                ),
              ),
            ),
      iconColor: accentColor,
      showBack: showBack,
      onBack: onBack,
      trailing: trailing,
      bottom: bottom,
      showSearch: showSearch,
      searchHint: searchHint,
      searchController: searchController,
      onSearchChanged: onSearchChanged,
    );
  }
}
