import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  // ─── Auth / login flow ─────────────────────────────────────────────────────

  static TextStyle brandHeading(double scale) => TextStyle(
    fontSize: 50 * scale,
    fontWeight: FontWeight.w900,
    color: AppColors.white,
    height: 1.02,
    letterSpacing: 0.5,
    shadows: const [
      Shadow(color: AppColors.textShadow, blurRadius: 12, offset: Offset(0, 2)),
    ],
  );

  static TextStyle brandSubtitle(double scale) => TextStyle(
    fontSize: 15 * scale,
    color: AppColors.white.withValues(alpha: 0.92),
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );

  static TextStyle cardHeading(double scale) => TextStyle(
    fontSize: 20 * scale,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle cardSubtext(double scale) =>
      TextStyle(fontSize: 13 * scale, color: AppColors.textSecondary);

  // ─── Inputs ────────────────────────────────────────────────────────────────

  static TextStyle inputText(double scale) => TextStyle(
    fontSize: 17 * scale,
    color: AppColors.black,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.0,
  );

  static TextStyle hintText(double scale) =>
      TextStyle(fontSize: 16 * scale, color: AppColors.textHint);

  static TextStyle mobileHighlight(double scale) => TextStyle(
    fontSize: 15 * scale,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle otpDigit(double scale) => TextStyle(
    fontSize: 20 * scale,
    color: AppColors.black,
    fontWeight: FontWeight.w700,
  );

  // ─── Buttons ───────────────────────────────────────────────────────────────

  static TextStyle buttonLabel(double scale) => TextStyle(
    fontSize: 16 * scale,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    letterSpacing: 0.3,
  );

  // ─── Dashboard — header ────────────────────────────────────────────────────

  static TextStyle greeting() =>
      TextStyle(color: AppColors.white.withValues(alpha: 0.75), fontSize: 15);

  static const TextStyle userName = TextStyle(
    color: AppColors.white,
    fontSize: 26,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.2,
  );

  static const TextStyle locationText = TextStyle(
    color: AppColors.white,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle badgeLabel = TextStyle(
    color: AppColors.black,
    fontSize: 8,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle avatarInitial = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryDark,
  );

  // ─── Dashboard — content cards ─────────────────────────────────────────────

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryDark,
  );

  static const TextStyle sectionLink = TextStyle(
    fontSize: 12,
    color: AppColors.primary,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle cardLabel = TextStyle(
    color: AppColors.textMuted,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle outstandingAmount = TextStyle(
    color: AppColors.primaryDark,
    fontSize: 26,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle dueWarning = TextStyle(
    color: AppColors.warning,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle dueClear = TextStyle(
    color: AppColors.success,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle viewBillsLabel = TextStyle(
    color: AppColors.primaryDark,
    fontWeight: FontWeight.bold,
    fontSize: 13,
  );

  static const TextStyle adminRoleTitle = TextStyle(
    color: AppColors.primaryDark,
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle adminSubtext = TextStyle(
    color: AppColors.warning,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  // ─── Dashboard — quick-action grid ─────────────────────────────────────────

  static const TextStyle actionLabel = TextStyle(
    color: AppColors.primaryDark,
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );

  // ─── Dashboard — promo card ─────────────────────────────────────────────────

  static const TextStyle promoTitle = TextStyle(
    color: AppColors.primaryDark,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle promoBody = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    height: 1.4,
  );

  static const TextStyle ctaButtonLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  // ─── Drawer ────────────────────────────────────────────────────────────────

  static const TextStyle drawerName = TextStyle(
    color: AppColors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static TextStyle drawerSubtext() =>
      TextStyle(color: AppColors.white.withValues(alpha: 0.65), fontSize: 13);

  static const TextStyle drawerItemLabel = TextStyle(
    color: AppColors.white,
    fontSize: 15,
  );

  static const TextStyle profileInitial = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryDark,
  );

  static const TextStyle logoutLabel = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  // ─── Bottom sheets ─────────────────────────────────────────────────────────

  static const TextStyle bottomSheetTitle = TextStyle(
    color: AppColors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
}
