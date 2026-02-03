import 'package:flutter/material.dart';
import 'package:nest_pilot_mobile/models/community_models.dart';
import 'package:nest_pilot_mobile/services/community_service.dart';

class AmenityManagementScreen extends StatefulWidget {
  const AmenityManagementScreen({super.key});

  @override
  State<AmenityManagementScreen> createState() =>
      _AmenityManagementScreenState();
}

class _AmenityManagementScreenState extends State<AmenityManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CommunityService _service = CommunityService();

  List<Amenity> _amenities = [];
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final amenities = await _service.getAllAmenities();
      final bookings = await _service.getAllBookings();
      if (mounted) {
        setState(() {
          _amenities = amenities;
          _bookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _updateBookingStatus(int id, String status) async {
    try {
      await _service.updateBookingStatus(id, status);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Booking $status')));
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddAmenityDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddAmenityDialog(),
    ).then((val) {
      if (val == true) _fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amenity Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Facilities'),
            Tab(text: 'Bookings'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildFacilitiesTab(), _buildBookingsTab()],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAmenityDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFacilitiesTab() {
    if (_amenities.isEmpty) {
      return const Center(child: Text('No amenities found. Add one!'));
    }
    return ListView.builder(
      itemCount: _amenities.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final amenity = _amenities[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: amenity.imageUrl != null
                ? CircleAvatar(backgroundImage: NetworkImage(amenity.imageUrl!))
                : const CircleAvatar(child: Icon(Icons.pool)),
            title: Text(amenity.name),
            subtitle: Text(
              '${amenity.startTime} - ${amenity.endTime}\n${amenity.isPaid ? "₹${amenity.pricePerHour}/hr" : "Free"}',
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildBookingsTab() {
    if (_bookings.isEmpty) {
      return const Center(child: Text('No bookings found.'));
    }
    return ListView.builder(
      itemCount: _bookings.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        final isPending = booking.status == 'PENDING';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ExpansionTile(
            title: Text(booking.amenity?.name ?? 'Unknown Amenity'),
            subtitle: Text(
              '${booking.date} (${booking.startTime} - ${booking.endTime})',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(booking.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                booking.status,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // If we had user details here, we would show them.
                    // The backend response for getAllBookings includes User details, but the Booking model might not fully parse it yet or we need to check.
                    // Let's assume generic display for now until we update model.
                    if (booking.userName != null)
                      Text(
                        'User: ${booking.userName} (${booking.userMobile})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 8),
                    Text('Amount: ₹${booking.amount}'),
                    const SizedBox(height: 16),
                    if (isPending)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () =>
                                _updateBookingStatus(booking.id, 'REJECTED'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Reject'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () =>
                                _updateBookingStatus(booking.id, 'CONFIRMED'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'REJECTED':
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class AddAmenityDialog extends StatefulWidget {
  const AddAmenityDialog({super.key});

  @override
  State<AddAmenityDialog> createState() => _AddAmenityDialogState();
}

class _AddAmenityDialogState extends State<AddAmenityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isPaid = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Amenity'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              SwitchListTile(
                title: const Text('Paid Amenity?'),
                value: _isPaid,
                onChanged: (val) {
                  setState(() => _isPaid = val);
                },
              ),
              if (_isPaid)
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price Per Hour',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text('Start: ${_startTime.format(context)}'),
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (t != null) setState(() => _startTime = t);
                      },
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text('End: ${_endTime.format(context)}'),
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _endTime,
                        );
                        if (t != null) setState(() => _endTime = t);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final startStr =
          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00';
      final endStr =
          '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00';

      await CommunityService().createAmenity({
        'name': _nameController.text,
        'description': _descController.text,
        'is_paid': _isPaid,
        'price_per_hour': _isPaid ? double.parse(_priceController.text) : 0,
        'start_time': startStr,
        'end_time': endStr,
        'is_active': true,
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }
}
