import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import '../../models/society_structure.dart';
import '../../services/secretary_building_service.dart';
import '../../services/society_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/nest_loader.dart';
import '../../widgets/app_field_card.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/glare_button.dart';

class SecretaryCreateScreen extends StatefulWidget {
  /// Pass [admin] to open in edit mode.
  final SecretaryAdmin? admin;

  const SecretaryCreateScreen({super.key, this.admin});

  bool get isEditing => admin != null;

  @override
  State<SecretaryCreateScreen> createState() => _SecretaryCreateScreenState();
}

class _SecretaryCreateScreenState extends State<SecretaryCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _emailCtrl;

  final SecretaryBuildingService _service = SecretaryBuildingService();
  final SocietyService _societyService = SocietyService();

  List<Society> _societies = [];
  Society? _selectedSociety;

  bool _isLoadingSocieties = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.admin;
    _nameCtrl = TextEditingController(text: a?.fullName ?? '');
    _mobileCtrl = TextEditingController(text: a?.mobile ?? '');
    _emailCtrl = TextEditingController(text: a?.email ?? '');
    _loadSocieties();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSocieties() async {
    try {
      final list = await _societyService.getSocieties();
      if (!mounted) return;
      setState(() {
        _societies = list;
        if (widget.isEditing && widget.admin?.societyId != null) {
          _selectedSociety = list.cast<Society?>().firstWhere(
                (s) => s?.id == widget.admin!.societyId.toString(),
                orElse: () => null,
              );
        }
        _isLoadingSocieties = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load societies: $e')),
        );
        setState(() => _isLoadingSocieties = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      if (widget.isEditing) {
        final ok = await _service.updateSocietyAdmin(
          id: widget.admin!.id,
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          societyId: _selectedSociety != null
              ? int.tryParse(_selectedSociety!.id)
              : null,
        );
        if (!mounted) return;
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Secretary updated successfully')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update secretary')),
          );
        }
      } else {
        final societyId = _selectedSociety != null
            ? int.tryParse(_selectedSociety!.id)
            : null;
        if (societyId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a society')),
          );
          setState(() => _isSaving = false);
          return;
        }
        final msg = await _service.createSocietyAdmin(
          fullName: _nameCtrl.text.trim(),
          mobile: _mobileCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          societyId: societyId,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Column(
        children: [
          AppPageHeader(
            icon: Icon(
              widget.isEditing
                  ? Icons.edit_outlined
                  : Icons.person_add_alt_1_outlined,
              color: AppColors.white,
              size: 28,
            ),
            title: widget.isEditing ? 'Edit Secretary' : 'Add Secretary',
            subtitle: widget.isEditing
                ? 'Update the secretary\'s details'
                : 'If the mobile is already registered, that user is promoted',
          ),
          Expanded(
            child: _isLoadingSocieties
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
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Name is required'
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (widget.isEditing)
                            AppFieldCard(
                              icon: Icons.phone_outlined,
                              label: 'Mobile (read-only)',
                              field: Text(
                                widget.admin?.mobile ?? '—',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          else
                            AppFieldCard(
                              icon: Icons.phone_outlined,
                              label: 'Mobile Number',
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
                                  r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$',
                                ).hasMatch(val)) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          const AppSectionHeader('Society'),
                          const SizedBox(height: 12),
                          AppFieldCard(
                            icon: Icons.apartment_rounded,
                            label: 'Society',
                            field: AppCardDropdown<Society>(
                              value: _selectedSociety,
                              hintText: 'Select society',
                              items: _societies,
                              itemLabel: (s) => s.name,
                              validator: widget.isEditing
                                  ? null
                                  : (v) =>
                                      v == null
                                          ? 'Please choose a society'
                                          : null,
                              onChanged: (v) =>
                                  setState(() => _selectedSociety = v),
                            ),
                          ),
                          const SizedBox(height: 32),
                          GlarePrimaryButton(
                            text: widget.isEditing
                                ? 'Save Changes'
                                : 'Add Secretary',
                            trailingIcon: Icons.arrow_forward_rounded,
                            isLoading: _isSaving,
                            onPressed: _save,
                            showGlare: false,
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
}
