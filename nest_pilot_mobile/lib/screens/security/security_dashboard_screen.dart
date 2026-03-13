import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class SecurityDashboardScreen extends StatefulWidget {
  const SecurityDashboardScreen({super.key});

  @override
  State<SecurityDashboardScreen> createState() =>
      _SecurityDashboardScreenState();
}

class _SecurityDashboardScreenState extends State<SecurityDashboardScreen> {
  final CommunityService _service = CommunityService();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();
  bool _isLoading = false;
  List<String> _houseNumbers = [];

  @override
  void initState() {
    super.initState();
    _fetchHouses();
  }

  Future<void> _fetchHouses() async {
    try {
      final houses = await _service.getAllHouses();
      if (mounted) {
        setState(() {
          _houseNumbers = houses
              .map<String>((h) => h['house_no'].toString())
              .toList();
          // Sort numerically/alphabetically if needed
          _houseNumbers.sort();
        });
      }
    } catch (e) {
      print('Error fetching houses: $e');
    }
  }

  Future<void> _verifyEntry() async {
    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter Pass Code')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final visitorData = await _service.verifyPassCode(_codeController.text);
      final visitor = visitorData['Visitor'];
      final house = visitorData['House'];

      if (!mounted) return;
      setState(() => _isLoading = false);

      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Verify Guest'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Name: ${visitor['name']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Mobile: ${visitor['mobile']}'),
              Text('Visiting: ${house['house_no']}'),
              const SizedBox(height: 16),
              const Text('Do you want to allow this entry?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'DENIED'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Deny Entry'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'INSIDE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Allow Entry'),
            ),
          ],
        ),
      );

      if (result != null) {
        setState(() => _isLoading = true);
        await _service.logVisitorEntry({
          'pass_code': _codeController.text,
          'vehicle_number': _vehicleController.text,
          'gate': 'Main Gate',
          'status': result,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result == 'INSIDE'
                    ? 'Visitor entry logged'
                    : 'Visitor entry denied',
              ),
            ),
          );
          _codeController.clear();
          _vehicleController.clear();
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logWalkIn() async {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController mobileCtrl = TextEditingController();
    // No houseCtrl for text, using selectedHouse for Dropdown
    String? selectedHouse;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Walk-in Entry'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppTextField(
                        controller: nameCtrl,
                        label: 'Visitor Name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Visitor Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: mobileCtrl,
                        label: 'Mobile Number',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Mobile Number is required';
                          }
                          if (value.trim().length < 10) {
                            return 'Enter valid 10-digit mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedHouse,
                        decoration: InputDecoration(
                          labelText: 'Visiting Flat',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _houseNumbers.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setDialogState(() {
                            selectedHouse = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a flat';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _vehicleController,
                        label: 'Vehicle Number (Optional)',
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, 'DENIED'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Deny Entry'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context, 'INSIDE');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Allow Entry'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      // selectedHouse is verified by form already, but for safety:
      if (selectedHouse == null && result == 'INSIDE') return;

      setState(() => _isLoading = true);
      try {
        await _service.logVisitorEntry({
          'name': nameCtrl.text,
          'mobile': mobileCtrl.text,
          'house_no': selectedHouse,
          'vehicle_number': _vehicleController.text,
          'type': 'WALK_IN',
          'gate': 'Main Gate',
          'status': result,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result == 'INSIDE' ? 'Entry logged' : 'Entry denied',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Gate'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              color: Colors.blueAccent,
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.security, color: Colors.white, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'GATE CONTROL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Resident Invited Visitor?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _codeController,
              label: 'Enter 6-Digit Pass Code',
              keyboardType: TextInputType.number,
              maxLength: 6,
              prefixIcon: Icons.vpn_key,
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _vehicleController,
              label: 'Vehicle Number (Optional)',
              prefixIcon: Icons.directions_car,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Verify Pass Code',
              isLoading: _isLoading,
              onPressed: _verifyEntry,
            ),
            const SizedBox(height: 32),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _logWalkIn,
              icon: const Icon(Icons.person_add),
              label: const Text('New Walk-in / Delivery'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                side: const BorderSide(color: Colors.blueAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
