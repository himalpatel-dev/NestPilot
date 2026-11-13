import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;

import '../../config/roles.dart';
import '../../models/managed_user.dart';
import '../../models/role_permission_model.dart';
import '../../models/society_structure.dart';
import '../../services/role_service.dart';
import '../../services/session_service.dart';
import '../../services/society_service.dart';
import '../../services/user_management_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/nest_loader.dart';
import '../../widgets/app_field_card.dart';
import '../../widgets/app_form_sheet.dart' show AppPickerCard;
import '../../widgets/app_page_header.dart';
import '../../widgets/glare_button.dart';
import '../../widgets/society_picker_sheet.dart';

/// Create or edit any user as the Super Admin — name, mobile (their OTP
/// login), email, role and society, plus the flat for members. Pops `true`
/// after a create and the updated [ManagedUser] after an edit.
class UserFormScreen extends StatefulWidget {
  /// Pass [user] to open in edit mode.
  final ManagedUser? user;

  /// Pre-selects the society in create mode (e.g. from a filtered list).
  final Society? initialSociety;

  const UserFormScreen({super.key, this.user, this.initialSociety});

  bool get isEditing => user != null;

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  static const List<String> _relations = ['OWNER', 'TENANT', 'FAMILY'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _emailCtrl;

  final UserManagementService _service = UserManagementService();
  final SocietyService _societyService = SocietyService();

  List<RoleModel> _roles = [];
  RoleModel? _role;
  Society? _society;
  bool _societyMissing = false;

  List<Building> _buildings = [];
  Building? _building;
  List<Flat> _flats = [];
  Flat? _flat;
  String? _relation;

  bool _isLoadingRoles = true;
  bool _isLoadingBuildings = false;
  bool _isLoadingFlats = false;
  bool _isSaving = false;

  // Drop a slow buildings / flats response for a society or building the
  // form has already moved away from.
  int _buildingsRequest = 0;
  int _flatsRequest = 0;

  bool get _isSelf =>
      widget.user != null &&
      '${widget.user!.id}' == SessionService().currentUser?.id;
  bool get _isSuperAdminRole => _role?.code == UserRoles.superAdmin;
  bool get _isMemberRole => _role?.code == UserRoles.member;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameCtrl = TextEditingController(text: u?.fullName ?? '');
    _mobileCtrl = TextEditingController(text: u?.mobile ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    final relation = u?.relationType?.toUpperCase();
    _relation = _relations.contains(relation) ? relation : null;

    if (u != null && u.societyId != null) {
      _society = Society(
        id: '${u.societyId}',
        name: u.societyName ?? 'Society',
        address: '',
        societyType: 'APARTMENT',
      );
      _loadBuildings(preselectId: u.buildingId, preselectFlatId: u.houseId);
    } else if (widget.initialSociety != null) {
      _society = widget.initialSociety;
      _loadBuildings();
    }
    _loadRoles();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadRoles() async {
    try {
      final roles = await RoleService().getRoles();
      if (!mounted) return;
      final roleId = widget.user?.roleId;
      setState(() {
        _roles = roles;
        for (final r in roles) {
          if (r.id == roleId) _role = r;
        }
        _isLoadingRoles = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRoles = false);
      _snack('Failed to load roles: ${_errorText(e)}');
    }
  }

  Future<void> _loadBuildings({int? preselectId, int? preselectFlatId}) async {
    final societyId = _society?.id;
    if (societyId == null) return;
    final request = ++_buildingsRequest;
    _flatsRequest++;
    setState(() {
      _isLoadingBuildings = true;
      _isLoadingFlats = false;
      _buildings = [];
      _building = null;
      _flats = [];
      _flat = null;
    });
    try {
      final list = await _societyService.getBuildings(societyId);
      if (!mounted || request != _buildingsRequest) return;
      Building? selected;
      for (final b in list) {
        if (b.id == '$preselectId') selected = b;
      }
      setState(() {
        _buildings = list;
        _building = selected;
        _isLoadingBuildings = false;
      });
      if (selected != null) _loadFlats(preselectId: preselectFlatId);
    } catch (e) {
      if (!mounted || request != _buildingsRequest) return;
      setState(() => _isLoadingBuildings = false);
      _snack('Failed to load buildings: ${_errorText(e)}');
    }
  }

  Future<void> _loadFlats({int? preselectId}) async {
    final buildingId = _building?.id;
    if (buildingId == null) return;
    final request = ++_flatsRequest;
    setState(() {
      _isLoadingFlats = true;
      _flats = [];
      _flat = null;
    });
    try {
      final list = (await _societyService.getFlats(
        buildingId,
      )).where((f) => f.isActive).toList();
      if (!mounted || request != _flatsRequest) return;
      Flat? selected;
      for (final f in list) {
        if (f.id == '$preselectId') selected = f;
      }
      setState(() {
        _flats = list;
        _flat = selected;
        _isLoadingFlats = false;
      });
    } catch (e) {
      if (!mounted || request != _flatsRequest) return;
      setState(() => _isLoadingFlats = false);
      _snack('Failed to load flats: ${_errorText(e)}');
    }
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> _pickSociety() async {
    final picked = await showSocietyPicker(context, selectedId: _society?.id);
    if (picked == null || picked.id == _society?.id) return;
    setState(() {
      _society = picked;
      _societyMissing = false;
    });
    _loadBuildings();
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();
    final needsSociety = !_isSuperAdminRole;
    setState(() => _societyMissing = needsSociety && _society == null);
    if (!formOk || _societyMissing) return;
    if (_isMemberRole && (_flat == null || _relation == null)) {
      _snack("Choose the member's building, flat and how they live there");
      return;
    }

    final roleId = _role!.id;
    final societyId = needsSociety ? int.tryParse(_society!.id) : null;
    final houseId = _isMemberRole ? int.tryParse(_flat!.id) : null;
    final relation = _isMemberRole ? _relation : null;

    setState(() => _isSaving = true);
    try {
      if (widget.isEditing) {
        final updated = await _service.updateUser(
          widget.user!.id,
          fullName: _nameCtrl.text.trim(),
          mobile: _mobileCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          roleId: roleId,
          societyId: societyId,
          houseId: houseId,
          relationType: relation,
        );
        if (!mounted) return;
        _snack('User updated');
        Navigator.pop(context, updated);
      } else {
        final message = await _service.createUser(
          fullName: _nameCtrl.text.trim(),
          mobile: _mobileCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          roleId: roleId,
          societyId: societyId,
          houseId: houseId,
          relationType: relation,
        );
        if (!mounted) return;
        _snack(message);
        Navigator.pop(context, true);
      }
    } catch (e) {
      _snack(_errorText(e));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final editing = widget.isEditing;
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Column(
        children: [
          AppPageHeader(
            icon: editing
                ? Icons.manage_accounts_outlined
                : Icons.person_add_alt_1_outlined,
            title: editing ? 'Edit User' : 'Add User',
            accentColor: ModuleColors.users,
            subtitle: editing
                ? widget.user!.fullName
                : 'They can sign in with OTP on this mobile right away',
          ),
          Expanded(
            child: _isLoadingRoles
                ? const Center(child: NestLoader())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AppSectionHeader('Personal Details'),
                          const SizedBox(height: 12),
                          AppFieldCard(
                            icon: Icons.person_outline_rounded,
                            label: 'Full Name',
                            field: AppBorderlessField(
                              controller: _nameCtrl,
                              hint: 'e.g. Ramesh Patel',
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Name is required'
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 14),
                          AppFieldCard(
                            icon: Icons.phone_outlined,
                            label: 'Mobile (used to sign in)',
                            field: AppBorderlessField(
                              controller: _mobileCtrl,
                              hint: '10-digit mobile',
                              keyboardType: TextInputType.number,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (v) {
                                final val = (v ?? '').trim();
                                if (val.isEmpty) return 'Mobile is required';
                                if (val.length != 10) {
                                  return 'Enter a valid 10-digit mobile';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          AppFieldCard(
                            icon: Icons.email_outlined,
                            label: 'Email (optional)',
                            field: AppBorderlessField(
                              controller: _emailCtrl,
                              hint: 'email@example.com',
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                final val = (v ?? '').trim();
                                if (val.isEmpty) return null;
                                if (!RegExp(
                                  r'^[\w.+-]+@[\w-]+(\.[\w-]+)*\.[a-zA-Z]{2,}$',
                                ).hasMatch(val)) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          const AppSectionHeader('Access'),
                          const SizedBox(height: 12),
                          AppFieldCard(
                            icon: Icons.shield_outlined,
                            label: _isSelf ? 'Role (your own — locked)' : 'Role',
                            field: AppCardDropdown<RoleModel>(
                              value: _role,
                              items: _roles,
                              hintText: 'Select role',
                              enabled: !_isSelf,
                              itemLabel: (r) => r.name,
                              validator: (v) =>
                                  v == null ? 'Please choose a role' : null,
                              onChanged: (r) => setState(() => _role = r),
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (_isSuperAdminRole)
                            _hint(
                              "Super Admins manage every society, so they aren't linked to one.",
                            )
                          else ...[
                            AppPickerCard(
                              icon: Icons.location_city_outlined,
                              label: 'Society',
                              value: _society?.name,
                              hint: 'Select society',
                              error: _societyMissing,
                              onTap: _pickSociety,
                            ),
                            if (_societyMissing)
                              _errorLine('Please choose a society'),
                          ],
                          if (_isMemberRole && _society != null)
                            ..._buildHomeSection(),
                          const SizedBox(height: 32),
                          GlarePrimaryButton(
                            text: editing ? 'Save Changes' : 'Create User',
                            trailingIcon: Icons.arrow_forward_rounded,
                            isLoading: _isSaving,
                            onPressed: _save,
                            showGlare: true,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHomeSection() {
    const loader = Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Center(child: NestLoader(size: 32, showDots: false)),
    );

    return [
      const SizedBox(height: 24),
      const AppSectionHeader('Home'),
      const SizedBox(height: 12),
      if (_isLoadingBuildings)
        loader
      else if (_buildings.isEmpty)
        _hint(
          'This society has no buildings yet — add buildings and flats before adding members.',
        )
      else ...[
        AppFieldCard(
          icon: Icons.business_rounded,
          label: 'Building / Block',
          field: AppCardDropdown<Building>(
            value: _building,
            items: _buildings,
            hintText: 'Select building',
            itemLabel: (b) => b.name,
            validator: (v) => v == null ? 'Please choose a building' : null,
            onChanged: (b) {
              if (b == null || b == _building) return;
              setState(() => _building = b);
              _loadFlats();
            },
          ),
        ),
        const SizedBox(height: 14),
        if (_isLoadingFlats)
          loader
        else if (_building != null && _flats.isEmpty)
          _hint('No flats in this building yet.')
        else
          AppFieldCard(
            icon: Icons.door_front_door_outlined,
            label: 'Flat / Unit',
            field: AppCardDropdown<Flat>(
              value: _flat,
              items: _flats,
              enabled: _building != null,
              hintText: _building == null
                  ? 'Select a building first'
                  : 'Select flat',
              itemLabel: (f) =>
                  (f.wing ?? '').isNotEmpty ? '${f.wing}-${f.number}' : f.number,
              validator: (v) => v == null ? 'Please choose a flat' : null,
              onChanged: (f) => setState(() => _flat = f),
            ),
          ),
        const SizedBox(height: 14),
        AppFieldCard(
          icon: Icons.family_restroom_rounded,
          label: 'Lives here as',
          field: AppCardDropdown<String>(
            value: _relation,
            items: _relations,
            hintText: 'Owner, tenant or family',
            itemLabel: (r) {
              switch (r) {
                case 'OWNER':
                  return 'Owner';
                case 'TENANT':
                  return 'Tenant';
                default:
                  return 'Family member';
              }
            },
            validator: (v) => v == null ? 'Please choose one' : null,
            onChanged: (r) => setState(() => _relation = r),
          ),
        ),
      ],
    ];
  }

  Widget _hint(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentIndigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accentIndigo.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.accentIndigo,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.accentIndigo,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorLine(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: AppColors.accentRed,
        ),
      ),
    );
  }
}

String _errorText(Object e) => e.toString().replaceFirst('Exception: ', '');
