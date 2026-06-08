import 'package:flutter/material.dart';
import '../../models/role_permission_model.dart';
import '../../services/role_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dashboard_header.dart';
import '../../theme/nest_loader.dart';

class RolePermissionScreen extends StatefulWidget {
  final RoleModel role;
  const RolePermissionScreen({super.key, required this.role});

  @override
  State<RolePermissionScreen> createState() => _RolePermissionScreenState();
}

class _RolePermissionScreenState extends State<RolePermissionScreen> {
  final RoleService _roleService = RoleService();

  List<ModulePermission> _permissions = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPermissions();
  }

  Future<void> _fetchPermissions() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final perms = await _roleService.getRolePermissions(widget.role.id);
      if (mounted) setState(() { _permissions = perms; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _savePermissions() async {
    setState(() => _isSaving = true);
    try {
      await _roleService.updateRolePermissions(widget.role.id, _permissions);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissions saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toggleAll(ModulePermission perm, bool value) {
    setState(() {
      perm.canView = value;
      perm.canCreate = value;
      perm.canUpdate = value;
      perm.canDelete = value;
      perm.canApprove = value;
    });
  }

  // ─── Icons per module ───────────────────────────────────────────────────────

  IconData _moduleIcon(String code) {
    switch (code) {
      case 'DASHBOARD':   return Icons.dashboard_outlined;
      case 'NOTICES':     return Icons.campaign_outlined;
      case 'COMPLAINTS':  return Icons.report_problem_outlined;
      case 'BILLS':       return Icons.receipt_long_outlined;
      case 'EVENTS':      return Icons.event_outlined;
      case 'AMENITIES':   return Icons.fitness_center_outlined;
      case 'VISITORS':    return Icons.person_pin_circle_outlined;
      case 'STAFF':       return Icons.badge_outlined;
      case 'POLLS':       return Icons.poll_outlined;
      case 'DOCUMENTS':   return Icons.folder_outlined;
      case 'VEHICLES':    return Icons.directions_car_outlined;
      case 'USERS':       return Icons.group_outlined;
      case 'BUILDINGS':   return Icons.apartment_outlined;
      case 'REPORTS':     return Icons.bar_chart_outlined;
      case 'ROLES':       return Icons.shield_outlined;
      default:            return Icons.widgets_outlined;
    }
  }

  Color _moduleColor(String code) {
    switch (code) {
      case 'DASHBOARD':   return AppColors.accentBlue;
      case 'NOTICES':     return AppColors.accentPurple;
      case 'COMPLAINTS':  return AppColors.accentRed;
      case 'BILLS':       return AppColors.accentOrange;
      case 'EVENTS':      return AppColors.accentTeal;
      case 'AMENITIES':   return AppColors.accentGreen;
      case 'VISITORS':    return AppColors.accentPink;
      case 'STAFF':       return AppColors.accentBrown;
      case 'POLLS':       return AppColors.accentIndigo;
      case 'DOCUMENTS':   return AppColors.accentAmber;
      case 'VEHICLES':    return AppColors.accentBlue;
      case 'USERS':       return AppColors.accentGreen;
      case 'BUILDINGS':   return AppColors.accentOrange;
      case 'REPORTS':     return AppColors.accentTeal;
      case 'ROLES':       return AppColors.accentRed;
      default:            return AppColors.primary;
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isSuperAdmin = widget.role.code == 'SUPER_ADMIN';

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      bottomNavigationBar: _isLoading || _error != null || isSuperAdmin
          ? null
          : _buildSaveBar(bottomPad),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppDashboardHeader(
              leftAction: appHeaderBackButton(context),
              title: widget.role.name,
              subtitle: isSuperAdmin
                  ? 'Super Admin has full access to all modules'
                  : 'Configure module-level permissions',
              belowSubtitle: _roleBadge(),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(child: NestLoader())
          else if (_error != null)
            SliverFillRemaining(child: _buildError())
          else if (isSuperAdmin)
            SliverFillRemaining(child: _buildSuperAdminInfo())
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad + 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    if (i == 0) return _buildLegend();
                    return _buildModuleRow(_permissions[i - 1]);
                  },
                  childCount: _permissions.length + 1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _roleBadge() {
    final isSystem = widget.role.isSystem;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSystem ? Icons.lock_outline_rounded : Icons.tune_rounded,
            color: AppColors.white,
            size: 12,
          ),
          const SizedBox(width: 5),
          Text(
            isSystem ? 'SYSTEM ROLE' : 'CUSTOM ROLE',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const Expanded(
            flex: 5,
            child: Text(
              'Module',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          for (final label in ['View', 'Create', 'Edit', 'Delete', 'Approve'])
            Expanded(
              flex: 2,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildModuleRow(ModulePermission perm) {
    final color = _moduleColor(perm.moduleCode);
    final icon = _moduleIcon(perm.moduleCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: perm.hasAny ? color.withValues(alpha: 0.25) : AppColors.border,
          width: perm.hasAny ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Module icon
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          // Module name
          Expanded(
            flex: 3,
            child: Text(
              perm.moduleName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Permission toggles
          _permToggle(perm.canView, color, (v) => setState(() => perm.canView = v)),
          _permToggle(perm.canCreate, color, (v) => setState(() => perm.canCreate = v)),
          _permToggle(perm.canUpdate, color, (v) => setState(() => perm.canUpdate = v)),
          _permToggle(perm.canDelete, AppColors.accentRed, (v) => setState(() => perm.canDelete = v)),
          _permToggle(perm.canApprove, AppColors.accentOrange, (v) => setState(() => perm.canApprove = v)),
          // All-or-nothing toggle
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _toggleAll(perm, !perm.hasAll),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: perm.hasAll
                    ? color.withValues(alpha: 0.15)
                    : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: perm.hasAll ? color : AppColors.border,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                perm.hasAll ? Icons.done_all_rounded : Icons.remove_rounded,
                size: 14,
                color: perm.hasAll ? color : AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _permToggle(bool value, Color color, ValueChanged<bool> onChanged) {
    return Expanded(
      flex: 2,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: value ? color.withValues(alpha: 0.15) : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: value ? color : AppColors.border,
                width: value ? 1.5 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: value
                ? Icon(Icons.check_rounded, size: 14, color: color)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveBar(double bottomPad) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _savePermissions,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentIndigo,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Save Permissions',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }

  Widget _buildSuperAdminInfo() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accentRed.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.accentRed,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Super Admin — Full Access',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'The Super Admin role has unrestricted access to all modules and actions. Permissions cannot be modified for this role.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.accentRed, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextButton(onPressed: _fetchPermissions, child: const Text('Retry')),
        ],
      ),
    );
  }
}
