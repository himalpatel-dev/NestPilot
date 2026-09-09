import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/nest_loader.dart';
import '../../../widgets/module_page_header.dart';
import 'package:nest_pilot_mobile/models/community_models.dart';
import 'package:nest_pilot_mobile/services/community_service.dart';
import 'package:intl/intl.dart';

class AmenityBookingScreen extends StatefulWidget {
  const AmenityBookingScreen({super.key});

  @override
  State<AmenityBookingScreen> createState() => _AmenityBookingScreenState();
}

class _AmenityBookingScreenState extends State<AmenityBookingScreen> {
  final CommunityService _service = CommunityService();
  final TextEditingController _searchController = TextEditingController();
  List<Amenity> _amenities = [];
  List<Booking> _myBookings = [];
  bool _isLoading = true;
  String _query = '';

  /// 0 = Facilities, 1 = My Bookings
  int _section = 0;

  List<Amenity> get _filteredAmenities {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _amenities;
    return _amenities.where((a) => a.name.toLowerCase().contains(q)).toList();
  }

  List<Booking> get _filteredBookings {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _myBookings;
    return _myBookings
        .where((b) => (b.amenity?.name ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    if (amenity.isFullDay) {
      final mode = await _chooseFullDayBookingMode(amenity);
      if (mode == null) return;
      if (mode == 'HOURLY') {
        // Same request shape as a SLOT booking — the backend tells FULL_DAY
        // amenities apart by whether start_time/end_time are present.
        await _bookSlotAmenity(amenity);
      } else {
        await _bookFullDayAmenity(amenity);
      }
    } else {
      await _bookSlotAmenity(amenity);
    }
  }

  Future<String?> _chooseFullDayBookingMode(Amenity amenity) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Book ${amenity.name}'),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event_available_rounded, color: AppColors.primary),
              title: const Text('Whole Day / Multiple Days'),
              subtitle: Text(
                amenity.isPaid ? '₹${amenity.pricePerDay}/day' : 'Free',
              ),
              onTap: () => Navigator.pop(ctx, 'WHOLE_DAY'),
            ),
            ListTile(
              leading: const Icon(Icons.access_time_rounded, color: AppColors.primary),
              title: const Text('Specific Hours'),
              subtitle: Text(
                amenity.isPaid ? '₹${amenity.pricePerHour}/hr' : 'Free',
              ),
              onTap: () => Navigator.pop(ctx, 'HOURLY'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Hall / common plot style booking — no fixed time, just the date(s) needed.
  Future<void> _bookFullDayAmenity(Amenity amenity) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: now, end: now),
      helpText: 'Select date(s) for ${amenity.name}',
    );
    if (picked == null) return;

    try {
      await _service.bookAmenity({
        'amenity_id': amenity.id,
        'date': DateFormat('yyyy-MM-dd').format(picked.start),
        'end_date': DateFormat('yyyy-MM-dd').format(picked.end),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking requested!')));
      _fetchData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _bookSlotAmenity(Amenity amenity) async {
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking requested!')));
      _fetchData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Column(
        children: [
          ModulePageHeader(
            title: 'Amenities',
            description: 'Book facilities & view your bookings',
            icon: Icons.calendar_today_outlined,
            iconColor: ModuleColors.amenities,
            showSearch: true,
            searchHint: 'Search amenities...',
            searchController: _searchController,
            onSearchChanged: (v) => setState(() => _query = v),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _sectionChip('Facilities', 0),
                const SizedBox(width: 8),
                _sectionChip('My Bookings', 1),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: NestLoader())
                : (_section == 0
                    ? _buildAmenitiesList()
                    : _buildBookingsList()),
          ),
        ],
      ),
    );
  }

  Widget _sectionChip(String label, int value) {
    final selected = _section == value;
    return GestureDetector(
      onTap: () => setState(() => _section = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAmenitiesList() {
    final amenities = _filteredAmenities;
    return ListView.builder(
      itemCount: amenities.length,
      itemBuilder: (context, index) {
        final a = amenities[index];
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
                subtitle: Text(
                  a.isPaid
                      ? (a.isFullDay
                          ? '₹${a.pricePerDay}/day · ₹${a.pricePerHour}/hr'
                          : '₹${a.pricePerHour}/hr')
                      : 'Free',
                ),
                // Booking is a view-level action — anyone who can reach this
                // screen is a resident requesting a slot, not an administrator.
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
    final bookings = _filteredBookings;
    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final b = bookings[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(b.amenity?.name ?? 'Unknown'),
            subtitle: Text(
              b.isFullDay
                  ? (b.endDate != null && b.endDate != b.date
                      ? '${b.date} to ${b.endDate}'
                      : b.date)
                  : '${b.date} (${b.startTime} - ${b.endTime})',
            ),
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
