import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Inline notice rendered in place of a submit/action button when the
/// current user lacks the required permission. Keeps the form visible
/// so the user understands what would happen if they had access.
class NoPermissionNotice extends StatelessWidget {
  final String action;
  const NoPermissionNotice({super.key, this.action = 'perform this action'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.accentAmber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded,
              color: AppColors.accentAmber, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "You don't have permission to $action.",
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
