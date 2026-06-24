import 'package:flutter/material.dart';
import '../../services/secretary_building_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dashboard_header.dart';
import '../../theme/nest_loader.dart';
import 'secretary_assign_screen.dart';
import 'secretary_create_screen.dart';

class SecretaryBuildingsScreen extends StatefulWidget {
  const SecretaryBuildingsScreen({super.key});

  @override
  State<SecretaryBuildingsScreen> createState() =>
      _SecretaryBuildingsScreenState();
}

class _SecretaryBuildingsScreenState extends State<SecretaryBuildingsScreen> {
  final SecretaryBuildingService _service = SecretaryBuildingService();

  List<SecretaryAdmin> _admins = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final admins = await _service.listSocietyAdmins();
      if (mounted) setState(() { _admins = admins; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _goCreate() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SecretaryCreateScreen()),
      ).then((changed) { if (changed == true) _fetch(); });

  void _goEdit(SecretaryAdmin admin) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SecretaryCreateScreen(admin: admin),
        ),
      ).then((changed) { if (changed == true) _fetch(); });

  void _goAssign(SecretaryAdmin admin) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SecretaryAssignScreen(admin: admin),
        ),
      ).then((changed) { if (changed == true) _fetch(); });

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final total = _admins.length;
    final assigned = _admins.where((a) => a.buildings.isNotEmpty).length;
    final unassigned = total - assigned;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goCreate,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_alt_1_rounded,
            color: AppColors.white, size: 20),
        label: const Text(
          'Add Secretary',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: AppColors.white,
        backgroundColor: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AppDashboardHeader(
                leftAction: appHeaderBackButton(context),
                title: 'Secretary Buildings',
                subtitle: 'Add secretaries and assign their buildings',
                stats: [
                  AppHeaderStat(
                    value: '$total',
                    label: 'Total',
                    color: AppColors.accentBlue,
                    icon: Icons.supervisor_account_outlined,
                  ),
                  AppHeaderStat(
                    value: '$assigned',
                    label: 'Assigned',
                    color: AppColors.accentGreen,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  AppHeaderStat(
                    value: '$unassigned',
                    label: 'Pending',
                    color: AppColors.accentOrange,
                    icon: Icons.error_outline_rounded,
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad + 24),
              sliver: _isLoading
                  ? const SliverFillRemaining(child: NestLoader())
                  : _error != null
                      ? SliverFillRemaining(child: _buildError())
                      : _admins.isEmpty
                          ? SliverFillRemaining(child: _buildEmpty())
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => _buildAdminCard(_admins[i]),
                                childCount: _admins.length,
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Admin card ─────────────────────────────────────────────────────────────

  Widget _buildAdminCard(SecretaryAdmin admin) {
    final initial =
        admin.fullName.isNotEmpty ? admin.fullName[0].toUpperCase() : 'S';
    final hasBuildings = admin.buildings.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.accentIndigo.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.accentIndigo,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            admin.fullName,
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
                          hasBuildings ? 'ASSIGNED' : 'PENDING',
                          hasBuildings
                              ? AppColors.accentGreen
                              : AppColors.accentOrange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      admin.mobile ?? '—',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                    if (admin.societyName != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        admin.societyName!,
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
              _actionBtn(
                Icons.edit_outlined,
                AppColors.accentBlue,
                () => _goEdit(admin),
                tooltip: 'Edit',
              ),
              const SizedBox(width: 8),
              _actionBtn(
                Icons.tune_rounded,
                AppColors.accentIndigo,
                () => _goAssign(admin),
                tooltip: 'Assign',
              ),
            ],
          ),
          if (hasBuildings) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  admin.buildings.map((b) => _buildingChip(b.name)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildingChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentIndigo.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        name,
        style: const TextStyle(
          color: AppColors.accentIndigo,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
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

  Widget _actionBtn(
    IconData icon,
    Color color,
    VoidCallback onTap, {
    String? tooltip,
  }) {
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
          const Icon(Icons.error_outline_rounded,
              color: AppColors.accentRed, size: 48),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: _fetch, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.supervisor_account_outlined,
              color: AppColors.border, size: 56),
          SizedBox(height: 12),
          Text(
            'No society admins yet',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          SizedBox(height: 4),
          Text(
            "Tap 'Add Secretary' to create one",
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
