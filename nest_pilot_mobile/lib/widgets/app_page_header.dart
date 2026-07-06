import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'module_page_header.dart';

/// Inner-screen page header — legacy API kept so existing screens work
/// unchanged, now rendering the universal light [ModulePageHeader] design:
/// circular back button, page title with the society · role context line,
/// notification bell, and the white module card (icon chip + description).
///
/// Callers historically passed white icons (for the old gradient hero);
/// the icon is recolored to [accentColor] so they render correctly on the
/// light card. Pass a module accent via [accentColor] to tint the icon chip.
class AppPageHeader extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final bool showBack;
  final Widget? trailing;
  final Widget? bottom;
  final Color accentColor;

  const AppPageHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onBack,
    this.showBack = true,
    this.trailing,
    this.bottom,
    this.accentColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return ModulePageHeader(
      title: title,
      description: subtitle,
      iconWidget: ColorFiltered(
        colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
        child: icon,
      ),
      iconColor: accentColor,
      showBack: showBack,
      onBack: onBack,
      trailing: trailing,
      bottom: bottom,
    );
  }
}
