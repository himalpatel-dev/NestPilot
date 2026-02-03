import 'package:flutter/material.dart';
import 'package:nest_pilot_mobile/models/community_models.dart';
import 'package:nest_pilot_mobile/services/community_service.dart';
import 'package:intl/intl.dart';

class AmenityBookingScreen extends StatefulWidget {
  const AmenityBookingScreen({super.key});

  @override
  State<AmenityBookingScreen> createState() => _AmenityBookingScreenState();
}

class _AmenityBookingScreenState extends State<AmenityBookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CommunityService _service = CommunityService();
  List<Amenity> _amenities = [];
  List<Booking> _myBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final amenities = await _service.getAllAmenities();
      final bookings = await _service.getMyBookings();
      setState(() {
        _amenities = amenities;
        _myBookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _bookAmenity(Amenity amenity) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (pickedDate == null) return;

    TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (startTime == null) return;

    TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: startTime.hour + 1, minute: 0),
    );
    if (endTime == null) return;

    try {
      await _service.bookAmenity({
        'amenity_id': amenity.id,
        'date': DateFormat('yyyy-MM-dd').format(pickedDate),
        'start_time':
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
        'end_time':
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking requested!')));
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amenities'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Facilities'),
            Tab(text: 'My Bookings'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildAmenitiesList(), _buildBookingsList()],
            ),
    );
  }

  Widget _buildAmenitiesList() {
    return ListView.builder(
      itemCount: _amenities.length,
      itemBuilder: (context, index) {
        final a = _amenities[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: Column(
            children: [
              if (a.imageUrl != null)
                Image.network(
                  a.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ListTile(
                title: Text(
                  a.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(a.isPaid ? '₹${a.pricePerHour}/hr' : 'Free'),
                trailing: ElevatedButton(
                  onPressed: () => _bookAmenity(a),
                  child: const Text('Book'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingsList() {
    return ListView.builder(
      itemCount: _myBookings.length,
      itemBuilder: (context, index) {
        final b = _myBookings[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(b.amenity?.name ?? 'Unknown'),
            subtitle: Text('${b.date} (${b.startTime} - ${b.endTime})'),
            trailing: Chip(
              label: Text(b.status),
              backgroundColor: b.status == 'CONFIRMED'
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
            ),
          ),
        );
      },
    );
  }
}
