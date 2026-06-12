import 'package:flutter/material.dart';
import '../../models/role_permission_model.dart';
import '../../services/role_service.dart';
import '../../services/permission_service.dart';
import '../../config/modules.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dashboard_header.dart';
import '../../theme/nest_loader.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'role_permission_screen.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  final RoleService _roleService = RoleService();

  List<RoleModel> _roles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRoles();
  }

  Future<void> _fetchRoles() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final roles = await _roleService.getRoles();
      if (mounted) setState(() { _roles = roles; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // ─── Create role sheet ──────────────────────────────────────────────────────

  void _showCreateSheet() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            24, 16, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accentIndigo.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.shield_outlined,
                        color: AppColors.accentIndigo, size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Create New Role',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: nameCtrl,
                  label: 'Role Name',
                  hint: 'e.g. Accountant',
                  validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: codeCtrl,
                  label: 'Role Code',
                  hint: 'e.g. ACCOUNTANT (auto-uppercased)',
                  validator: (v) {
                    if ((v ?? '').isEmpty) return 'Required';
                    if (v!.contains(' ')) return 'Use underscores, no spaces';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: descCtrl,
                  label: 'Description (optional)',
                  hint: 'Brief description of this role',
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: 'Create Role',
                  isLoading: saving,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    setSheet(() => saving = true);
                    try {
                      await _roleService.createRole(
                        code: codeCtrl.text.trim().toUpperCase(),
                        name: nameCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      _fetchRoles();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Role created successfully')),
                        );
                      }
                    } catch (e) {
                      setSheet(() => saving = false);
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Edit role sheet ────────────────────────────────────────────────────────

  void _showEditSheet(RoleModel role) {
    final nameCtrl = TextEditingController(text: role.name);
    final descCtrl = TextEditingController(text: role.description ?? '');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            24, 16, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.accentOrange, size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Edit Role',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            role.code,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: nameCtrl,
                  label: 'Role Name',
                  validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: descCtrl,
                  label: 'Description (optional)',
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: 'Save Changes',
                  isLoading: saving,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    setSheet(() => saving = true);
                    try {
                      await _roleService.updateRole(
                        role.id,
                        name: nameCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      _fetchRoles();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Role updated')),
                        );
                      }
                    } catch (e) {
                      setSheet(() => saving = false);
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Delete confirm ──────────────────────────────────────────────────────────

  Future<void> _confirmDelete(RoleModel role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Role', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Delete "${role.name}"? This cannot be undone.\n'
          'Make sure no users are assigned to this role.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _roleService.deleteRole(role.id);
      _fetchRoles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Role "${role.name}" deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  // ─── UI helpers ─────────────────────────────────────────────────────────────

  Color _roleColor(RoleModel role) {
    switch (role.code) {
      case 'SUPER_ADMIN': return AppColors.accentRed;
      case 'SOCIETY_ADMIN': return AppColors.accentIndigo;
      case 'MEMBER': return AppColors.accentGreen;
      case 'SECURITY_GUARD': return AppColors.accentOrange;
      default: return AppColors.accentPurple;
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final totalRoles = _roles.length;
    final systemRoles = _roles.where((r) => r.isSystem).length;
    final customRoles = totalRoles - systemRoles;

    final canCreateRoles = PermissionService().canCreate(ModuleCodes.roles);
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      floatingActionButton: canCreateRoles
          ? FloatingActionButton.extended(
              onPressed: _showCreateSheet,
              backgroundColor: AppColors.accentIndigo,
              foregroundColor: AppColors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Role', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _fetchRoles,
        color: AppColors.white,
        backgroundColor: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AppDashboardHeader(
                leftAction: appHeaderBackButton(context),
                title: 'Roles & Permissions',
                subtitle: 'Manage access control across modules',
                stats: [
                  AppHeaderStat(
                    value: '$totalRoles',
                    label: 'Total',
                    color: AppColors.accentBlue,
                    icon: Icons.shield_outlined,
                  ),
                  AppHeaderStat(
                    value: '$systemRoles',
                    label: 'System',
                    color: AppColors.accentOrange,
                    icon: Icons.lock_outline_rounded,
                  ),
                  AppHeaderStat(
                    value: '$customRoles',
                    label: 'Custom',
                    color: AppColors.accentGreen,
                    icon: Icons.tune_rounded,
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad + 100),
              sliver: _isLoading
                  ? const SliverFillRemaining(child: NestLoader())
                  : _error != null
                      ? SliverFillRemaining(child: _buildError())
                      : _roles.isEmpty
                          ? SliverFillRemaining(child: _buildEmpty())
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => _buildRoleCard(_roles[i]),
                                childCount: _roles.length,
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(RoleModel role) {
    final color = _roleColor(role);
    final initial = role.name.isNotEmpty ? role.name[0].toUpperCase() : 'R';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        role.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _badge(
                      role.isSystem ? 'SYSTEM' : 'CUSTOM',
                      role.isSystem ? AppColors.accentRed : AppColors.accentGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  role.code,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                if (role.description != null && role.description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    role.description!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Actions
          _actionBtn(
            Icons.tune_rounded,
            AppColors.accentIndigo,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RolePermissionScreen(role: role),
              ),
            ),
            tooltip: 'Permissions',
          ),
          if (!role.isSystem) ...[
            if (PermissionService().canUpdate(ModuleCodes.roles)) ...[
              const SizedBox(width: 6),
              _actionBtn(
                Icons.edit_outlined,
                AppColors.accentOrange,
                () => _showEditSheet(role),
                tooltip: 'Edit',
              ),
            ],
            if (PermissionService().canDelete(ModuleCodes.roles)) ...[
              const SizedBox(width: 6),
              _actionBtn(
                Icons.delete_outline_rounded,
                AppColors.accentRed,
                () => _confirmDelete(role),
                tooltip: 'Delete',
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap, {String? tooltip}) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 17),
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
          Text(
            _error!,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: _fetchRoles, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.border, size: 56),
          SizedBox(height: 12),
          Text('No roles found', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
