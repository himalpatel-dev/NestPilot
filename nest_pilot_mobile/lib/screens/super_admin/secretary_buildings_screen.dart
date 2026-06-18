import 'package:flutter/material.dart';
import '../../models/society_structure.dart';
import '../../services/secretary_building_service.dart';
import '../../services/society_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dashboard_header.dart';
import '../../theme/nest_loader.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_field_card.dart';

class SecretaryBuildingsScreen extends StatefulWidget {
  const SecretaryBuildingsScreen({super.key});

  @override
  State<SecretaryBuildingsScreen> createState() =>
      _SecretaryBuildingsScreenState();
}

class _SecretaryBuildingsScreenState extends State<SecretaryBuildingsScreen> {
  final SecretaryBuildingService _service = SecretaryBuildingService();
  final SocietyService _societyService = SocietyService();

  List<SecretaryAdmin> _admins = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final admins = await _service.listSocietyAdmins();
      if (mounted) setState(() { _admins = admins; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // ─── Add secretary sheet ────────────────────────────────────────────────────

  Future<void> _showAddSheet() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    List<Society> societies = [];
    Society? selectedSociety;
    bool loadStarted = false;
    bool loadingSocieties = true;
    String? loadError;
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          if (!loadStarted) {
            loadStarted = true;
            _societyService.getSocieties().then((list) {
              if (!ctx.mounted) return;
              setSheet(() {
                societies = list;
                loadingSocieties = false;
              });
            }).catchError((e) {
              if (!ctx.mounted) return;
              setSheet(() {
                loadError = e.toString();
                loadingSocieties = false;
              });
            });
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              24, 16, 24,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
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
                            Icons.person_add_alt_1_outlined,
                            color: AppColors.accentIndigo, size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Society Admin',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'If the mobile is already registered, that user is promoted',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (loadingSocieties)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: NestLoader()),
                      )
                    else if (loadError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          loadError!,
                          style: const TextStyle(color: AppColors.accentRed),
                        ),
                      )
                    else ...[
                      TextFormField(
                        controller: nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: mobileCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return 'Mobile is required';
                          if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                            return 'Enter a valid 10-digit mobile';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppFieldCard(
                        icon: Icons.apartment_rounded,
                        label: 'Society',
                        field: AppCardDropdown<Society>(
                          value: selectedSociety,
                          hintText: 'Select society',
                          items: societies,
                          itemLabel: (s) => s.name,
                          validator: (v) =>
                              v == null ? 'Please choose a society' : null,
                          onChanged: (v) => setSheet(() => selectedSociety = v),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        text: 'Add Secretary',
                        isLoading: saving,
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final societyId =
                              int.tryParse(selectedSociety!.id);
                          if (societyId == null) return;
                          setSheet(() => saving = true);
                          try {
                            final msg = await _service.createSocietyAdmin(
                              fullName: nameCtrl.text.trim(),
                              mobile: mobileCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              societyId: societyId,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            _fetch();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(msg)),
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    nameCtrl.dispose();
    mobileCtrl.dispose();
    emailCtrl.dispose();
  }

  // ─── Assign sheet ───────────────────────────────────────────────────────────

  Future<void> _showAssignSheet(SecretaryAdmin admin) async {
    if (admin.societyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This secretary is not linked to a society')),
      );
      return;
    }

    List<Building> societyBuildings = [];
    bool loadingBuildings = true;
    String? loadError;
    final selectedIds = <int>{...admin.buildings.map((b) => b.id)};
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          if (loadingBuildings) {
            // kick off the load once
            _societyService
                .getBuildings(admin.societyId.toString())
                .then((bs) {
              if (!ctx.mounted) return;
              setSheet(() {
                societyBuildings = bs;
                loadingBuildings = false;
              });
            }).catchError((e) {
              if (!ctx.mounted) return;
              setSheet(() {
                loadError = e.toString();
                loadingBuildings = false;
              });
            });
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              24, 16, 24,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
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
                        Icons.apartment_outlined,
                        color: AppColors.accentIndigo, size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Assign Buildings',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            admin.fullName,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (loadingBuildings)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: NestLoader()),
                  )
                else if (loadError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      loadError!,
                      style: const TextStyle(color: AppColors.accentRed),
                    ),
                  )
                else if (societyBuildings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'This society has no buildings yet.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else ...[
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                    ),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: societyBuildings.map((b) {
                          final bid = int.tryParse(b.id);
                          if (bid == null) return const SizedBox.shrink();
                          final selected = selectedIds.contains(bid);
                          return FilterChip(
                            label: Text(b.name),
                            selected: selected,
                            onSelected: (v) => setSheet(() {
                              v ? selectedIds.add(bid) : selectedIds.remove(bid);
                            }),
                            selectedColor:
                                AppColors.accentIndigo.withValues(alpha: 0.18),
                            checkmarkColor: AppColors.accentIndigo,
                            labelStyle: TextStyle(
                              color: selected
                                  ? AppColors.accentIndigo
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: selected
                                    ? AppColors.accentIndigo
                                    : AppColors.border,
                              ),
                            ),
                            backgroundColor: AppColors.white,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${selectedIds.length} of ${societyBuildings.length} selected',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                AppButton(
                  text: 'Save Assignments',
                  isLoading: saving,
                  onPressed: () async {
                    setSheet(() => saving = true);
                    try {
                      final ok = await _service.setAssignments(
                        admin.id, selectedIds.toList(),
                      );
                      if (!ok) throw Exception('Save failed');
                      if (ctx.mounted) Navigator.pop(ctx);
                      _fetch();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Assignments updated')),
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
          );
        },
      ),
    );
  }

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
        onPressed: _showAddSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(
          Icons.person_add_alt_1_rounded,
          color: AppColors.white,
          size: 20,
        ),
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

  Widget _buildAdminCard(SecretaryAdmin admin) {
    final initial =
        admin.fullName.isNotEmpty ? admin.fullName[0].toUpperCase() : 'S';
    final hasBuildings = admin.buildings.isNotEmpty;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46, height: 46,
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
                Icons.tune_rounded,
                AppColors.accentIndigo,
                () => _showAssignSheet(admin),
                tooltip: 'Assign',
              ),
            ],
          ),
          if (hasBuildings) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: admin.buildings
                  .map((b) => _buildingChip(b.name))
                  .toList(),
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

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap,
      {String? tooltip}) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34, height: 34,
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
          Text('No society admins yet',
              style: TextStyle(color: AppColors.textSecondary)),
          SizedBox(height: 4),
          Text("Tap 'Add Secretary' to create one",
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
