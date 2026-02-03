import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/society_service.dart';
import '../models/society_structure.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'pending_approval_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String mobile;
  const RegisterScreen({super.key, required this.mobile});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final AuthService _authService = AuthService();
  final SocietyService _societyService = SocietyService();

  List<Society> _societies = [];
  List<Building> _buildings = [];
  List<Flat> _flats = [];

  String? _selectedSocietyId;
  String? _selectedBuildingId;
  String? _selectedFlatId;
  String? _selectedRelationType;

  bool _isLoading = false;
  bool _isFetchingData = true;

  @override
  void initState() {
    super.initState();
    _fetchSocieties();
  }

  Future<void> _fetchSocieties() async {
    try {
      final societies = await _societyService.getSocieties();
      setState(() {
        _societies = societies;
        _isFetchingData = false;
      });
    } catch (e) {
      setState(() => _isFetchingData = false);
    }
  }

  Future<void> _fetchBuildings(String societyId) async {
    setState(() {
      _isFetchingData = true;
      _buildings = [];
      _flats = [];
      _selectedBuildingId = null;
      _selectedFlatId = null;
    });
    try {
      final buildings = await _societyService.getBuildings(societyId);
      setState(() {
        _buildings = buildings;
        _isFetchingData = false;
      });
    } catch (e) {
      setState(() => _isFetchingData = false);
    }
  }

  Future<void> _fetchFlats(String buildingId) async {
    setState(() {
      _isFetchingData = true;
      _flats = [];
      _selectedFlatId = null;
    });
    try {
      final flats = await _societyService.getFlats(buildingId);
      setState(() {
        _flats = flats;
        _isFetchingData = false;
      });
    } catch (e) {
      setState(() => _isFetchingData = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSocietyId == null ||
        _selectedBuildingId == null ||
        _selectedFlatId == null ||
        _selectedRelationType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select all fields')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await _authService.register(
        fullName: _nameController.text,
        mobile: widget.mobile,
        societyId: _selectedSocietyId!,
        buildingId: _selectedBuildingId!,
        flatId: _selectedFlatId!,
        relationType: _selectedRelationType!,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
      );

      if (success && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const PendingApprovalScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Registration')),
      body: _isFetchingData && _societies.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      prefixIcon: Icons.person_outline,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _emailController,
                      label: 'Email (Optional)',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSocietyId,
                      decoration: const InputDecoration(
                        labelText: 'Society',
                        border: OutlineInputBorder(),
                      ),
                      items: _societies
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() => _selectedSocietyId = val);
                        if (val != null) _fetchBuildings(val);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedBuildingId,
                      decoration: const InputDecoration(
                        labelText: 'Building',
                        border: OutlineInputBorder(),
                      ),
                      items: _buildings
                          .map(
                            (b) => DropdownMenuItem(
                              value: b.id,
                              child: Text(b.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() => _selectedBuildingId = val);
                        if (val != null) _fetchFlats(val);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedFlatId,
                      decoration: const InputDecoration(
                        labelText: 'Flat',
                        border: OutlineInputBorder(),
                      ),
                      items: _flats
                          .map(
                            (f) => DropdownMenuItem(
                              value: f.id,
                              child: Text(f.number),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedFlatId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRelationType,
                      decoration: const InputDecoration(
                        labelText: 'Relation Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ['OWNER', 'TENANT', 'FAMILY_MEMBER']
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedRelationType = val),
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      text: 'Register',
                      isLoading: _isLoading,
                      onPressed: _register,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
