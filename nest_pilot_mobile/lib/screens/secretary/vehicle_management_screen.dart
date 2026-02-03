import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import '../../models/community_models.dart';
import '../../widgets/status_widgets.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() =>
      _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  final CommunityService _communityService = CommunityService();
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    setState(() => _isLoading = true);
    try {
      final vehicles = await _communityService.getAllVehicles();
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Registered Vehicles')),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : _vehicles.isEmpty
          ? const Center(child: Text('No vehicles found'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = _vehicles[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              vehicle.type == 'CAR'
                                  ? Icons.directions_car
                                  : Icons.two_wheeler,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              vehicle.vehicleNumber,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                vehicle.type,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        if (vehicle.userName != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text('Owner: ${vehicle.userName}'),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text('${vehicle.userMobile}'),
                            ],
                          ),
                          if (vehicle.flatNumber != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.home,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text('Flat: ${vehicle.flatNumber}'),
                              ],
                            ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '${vehicle.brand ?? 'Unknown'} ${vehicle.model ?? ''}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        if (vehicle.stickerNumber != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Sticker: ${vehicle.stickerNumber}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
