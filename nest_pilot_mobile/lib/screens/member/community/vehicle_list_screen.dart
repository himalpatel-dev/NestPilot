import 'package:flutter/material.dart';
import '../../../theme/nest_loader.dart';
import 'package:nest_pilot_mobile/models/community_models.dart';
import 'package:nest_pilot_mobile/services/community_service.dart';
import 'package:nest_pilot_mobile/services/auth_service.dart';
import 'package:nest_pilot_mobile/services/permission_service.dart';
import 'package:nest_pilot_mobile/config/modules.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final CommunityService _service = CommunityService();
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    try {
      final vehicles = await _service.getMyVehicles();
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _addVehicle() async {
    final formKey = GlobalKey<FormState>();
    final numberController = TextEditingController();
    final modelController = TextEditingController();
    String type = 'CAR';

    // Fetch user details to construct sticker number
    final user = await AuthService().getMe();
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Could not retrieve user profile.'),
          ),
        );
      }
      return;
    }

    final flatNo = user.flatNumber ?? 'N/A';
    final societyId = user.societyId ?? 'N/A';
    final userId = user.id;
    final stickerNumber = '$flatNo-$societyId-$userId';

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vehicle'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: numberController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Number (e.g. MH01AB1234)',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: modelController,
                decoration: const InputDecoration(
                  labelText: 'Model (e.g. Honda City)',
                ),
              ),
              DropdownButtonFormField<String>(
                value: type,
                items: ['CAR', 'BIKE', 'OTHER']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => type = v!,
                decoration: const InputDecoration(labelText: 'Type'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _service.addVehicle({
                    'vehicle_number': numberController.text,
                    'model': modelController.text,
                    'type': type,
                    'sticker_number': stickerNumber,
                  });
                  Navigator.pop(context);
                  _fetchVehicles();
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVehicle(int id) async {
    try {
      await _service.deleteVehicle(id);
      _fetchVehicles();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final perms = PermissionService();
    final canCreate = perms.canCreate(ModuleCodes.vehicles);
    final canDelete = perms.canDelete(ModuleCodes.vehicles);
    return Scaffold(
      appBar: AppBar(title: const Text('My Vehicles')),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: _addVehicle,
              child: const Icon(Icons.add),
            )
          : null,
      body: _isLoading
          ? const Center(child: NestLoader())
          : _vehicles.isEmpty
          ? const Center(child: Text('No vehicles registered'))
          : ListView.builder(
              itemCount: _vehicles.length,
              itemBuilder: (context, index) {
                final v = _vehicles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: Icon(
                      v.type == 'CAR'
                          ? Icons.directions_car
                          : v.type == 'BIKE'
                          ? Icons.two_wheeler
                          : Icons.commute,
                      size: 32,
                      color: Colors.blue,
                    ),
                    title: Text(
                      v.vehicleNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(v.model ?? v.type),
                    trailing: canDelete
                        ? IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteVehicle(v.id),
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
