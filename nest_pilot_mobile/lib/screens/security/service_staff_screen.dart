import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/service_staff_model.dart';
import '../../services/staff_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/nest_loader.dart';
import '../../widgets/app_page_header.dart';

class ServiceStaffScreen extends StatefulWidget {
  const ServiceStaffScreen({super.key});

  @override
  State<ServiceStaffScreen> createState() => _ServiceStaffScreenState();
}

class _ServiceStaffScreenState extends State<ServiceStaffScreen> {
  final StaffService _service = StaffService();
  List<ServiceStaffModel> _staff = [];
  bool _isLoading = true;
  String? _error;

  static const _roles = ['MAID', 'DRIVER', 'COOK', 'GARDENER', 'SECURITY', 'OTHER'];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final list = await _service.getAll();
      if (mounted) setState(() { _staff = list; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _openSheet({ServiceStaffModel? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _StaffSheet(
        editing: editing,
        roles: _roles,
        onSaved: () { Navigator.pop(ctx); _fetch(); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: AppColors.white,
        backgroundColor: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AppPageHeader(
                icon: const Icon(Icons.badge_outlined, color: AppColors.white, size: 28),
                title: 'Service Staff',
                subtitle: _isLoading
                    ? 'Loading…'
                    : '${_staff.length} staff member${_staff.length == 1 ? '' : 's'}',
                trailing: GestureDetector(
                  onTap: () => _openSheet(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.40)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: AppColors.white, size: 16),
                        SizedBox(width: 4),
                        Text('Add', style: TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(child: NestLoader())
            else if (_error != null)
              SliverFillRemaining(child: _buildError())
            else if (_staff.isEmpty)
              const SliverFillRemaining(child: _EmptyState())
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad + 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildCard(_staff[i]),
                    childCount: _staff.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(ServiceStaffModel s) {
    final color = _roleColor(s.role);

    return GestureDetector(
      onTap: () => _openSheet(editing: s),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // Role icon square
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Icon(_roleIcon(s.role), color: color, size: 22),
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
                            s.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(s.role, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(s.mobile, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        if (s.aadhaarNumber != null && s.aadhaarNumber!.isNotEmpty) ...[
                          const Text('  ·  ', style: TextStyle(color: AppColors.textMuted)),
                          const Icon(Icons.credit_card_outlined, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text('••••${s.aadhaarNumber!.length >= 4 ? s.aadhaarNumber!.substring(s.aadhaarNumber!.length - 4) : s.aadhaarNumber!}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.edit_outlined, color: AppColors.textHint, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'MAID':      return AppColors.accentPink;
      case 'DRIVER':    return AppColors.accentBlue;
      case 'COOK':      return AppColors.accentOrange;
      case 'GARDENER':  return AppColors.accentGreen;
      case 'SECURITY':  return AppColors.accentRed;
      default:          return AppColors.accentPurple;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'MAID':      return Icons.cleaning_services_outlined;
      case 'DRIVER':    return Icons.directions_car_outlined;
      case 'COOK':      return Icons.restaurant_outlined;
      case 'GARDENER':  return Icons.yard_outlined;
      case 'SECURITY':  return Icons.shield_outlined;
      default:          return Icons.person_outlined;
    }
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.accentRed, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _fetch,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                child: const Text('Retry', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add / Edit sheet ─────────────────────────────────────────────────────────

class _StaffSheet extends StatefulWidget {
  final ServiceStaffModel? editing;
  final List<String> roles;
  final VoidCallback onSaved;

  const _StaffSheet({this.editing, required this.roles, required this.onSaved});

  @override
  State<_StaffSheet> createState() => _StaffSheetState();
}

class _StaffSheetState extends State<_StaffSheet> {
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  late String _role;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _nameCtrl.text = e?.name ?? '';
    _mobileCtrl.text = e?.mobile ?? '';
    _aadhaarCtrl.text = e?.aadhaarNumber ?? '';
    _role = e?.role ?? widget.roles.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _aadhaarCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final mobile = _mobileCtrl.text.trim();
    if (name.isEmpty || mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and mobile are required')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final svc = StaffService();
      if (widget.editing != null) {
        await svc.update(widget.editing!.id, name: name, role: _role, mobile: mobile, aadhaarNumber: _aadhaarCtrl.text.trim());
      } else {
        await svc.add(name: name, role: _role, mobile: mobile, aadhaarNumber: _aadhaarCtrl.text.trim());
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.editing != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Edit Staff' : 'Add Staff Member',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),

            // Name
            _field(controller: _nameCtrl, label: 'Full Name', icon: Icons.person_outline_rounded),
            const SizedBox(height: 12),

            // Mobile
            _field(
              controller: _mobileCtrl,
              label: 'Mobile Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            ),
            const SizedBox(height: 12),

            // Aadhaar
            _field(
              controller: _aadhaarCtrl,
              label: 'Aadhaar Number (optional)',
              icon: Icons.credit_card_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)],
            ),
            const SizedBox(height: 12),

            // Role picker
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.work_outline_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        const Text('Role', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Row(
                      children: widget.roles.map((r) {
                        final selected = _role == r;
                        return GestureDetector(
                          onTap: () => setState(() => _role = r),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary : AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                            ),
                            child: Text(
                              r,
                              style: TextStyle(
                                color: selected ? AppColors.white : AppColors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white))
                    : Text(isEdit ? 'Save Changes' : 'Add Staff Member',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.badge_outlined, color: AppColors.border, size: 56),
          SizedBox(height: 12),
          Text('No staff members added yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Pull down to refresh', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
