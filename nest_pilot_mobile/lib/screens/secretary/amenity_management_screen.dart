import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/nest_loader.dart';
import '../../theme/app_colors.dart';
import '../../widgets/module_page_header.dart';
import 'package:nest_pilot_mobile/models/community_models.dart';
import 'package:nest_pilot_mobile/services/community_service.dart';
import 'package:nest_pilot_mobile/services/permission_service.dart';
import 'package:nest_pilot_mobile/config/modules.dart';

class AmenityManagementScreen extends StatefulWidget {
  const AmenityManagementScreen({super.key});

  @override
  State<AmenityManagementScreen> createState() =>
      _AmenityManagementScreenState();
}

class _AmenityManagementScreenState extends State<AmenityManagementScreen> {
  final CommunityService _service = CommunityService();
  final TextEditingController _searchController = TextEditingController();

  List<Amenity> _amenities = [];
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String _query = '';

  /// 0 = Facilities, 1 = Bookings
  int _section = 0;

  List<Amenity> get _filteredAmenities {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _amenities;
    return _amenities.where((a) => a.name.toLowerCase().contains(q)).toList();
  }

  List<Booking> get _filteredBookings {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _bookings;
    return _bookings
        .where(
          (b) =>
              (b.amenity?.name ?? '').toLowerCase().contains(q) ||
              (b.userName ?? '').toLowerCase().contains(q),
        )
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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cardBackground,
        body: Column(
          children: [
            ModulePageHeader(
              title: 'Amenities',
              description: 'Manage facilities & approve bookings',
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
                  _sectionChip('Bookings', 1),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: NestLoader())
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      color: AppColors.white,
                      backgroundColor: AppColors.primary,
                      child: _section == 0
                          ? _buildFacilitiesTab()
                          : _buildBookingsTab(),
                    ),
            ),
          ],
        ),
        floatingActionButton: PermissionService().canManage(ModuleCodes.amenities)
            ? FloatingActionButton(
                onPressed: _showAddAmenityDialog,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.add, size: 28),
              )
            : null,
      ),
    );
  }

  // ─── Facilities Tab ────────────────────────────────────────────────────────

  Widget _buildFacilitiesTab() {
    final amenities = _filteredAmenities;
    if (amenities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_center_outlined,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'No amenities found. Add one!',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: amenities.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final amenity = amenities[index];
        final isPaid = amenity.isPaid;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar / Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: amenity.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            amenity.imageUrl!,
                            fit: BoxFit.cover,
                            width: 52,
                            height: 52,
                          ),
                        )
                      : const Icon(
                          Icons.sports_soccer_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 16),
                // Title and Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              amenity.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? AppColors.accentAmber.withValues(alpha: 0.12)
                                  : AppColors.accentGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isPaid
                                  ? (amenity.isFullDay
                                      ? "₹${amenity.pricePerDay}/day · ₹${amenity.pricePerHour}/hr"
                                      : "₹${amenity.pricePerHour}/hr")
                                  : "Free",
                              style: TextStyle(
                                color: isPaid ? AppColors.warning : AppColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (amenity.description != null && amenity.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          amenity.description!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            amenity.isFullDay
                                ? Icons.event_available_rounded
                                : Icons.access_time_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            amenity.isFullDay
                                ? 'Full-day booking (as per requirement)'
                                : 'Timing: ${amenity.startTime} - ${amenity.endTime}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Bookings Tab ──────────────────────────────────────────────────────────

  Widget _buildBookingsTab() {
    final bookings = _filteredBookings;
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'No bookings found.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: bookings.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final isPending = booking.status == 'PENDING';

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            collapsedShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            backgroundColor: AppColors.white,
            collapsedBackgroundColor: AppColors.white,
            iconColor: AppColors.primary,
            collapsedIconColor: AppColors.textSecondary,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            title: Text(
              booking.amenity?.name ?? 'Unknown Amenity',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                booking.isFullDay
                    ? (booking.endDate != null && booking.endDate != booking.date
                        ? '${booking.date} to ${booking.endDate}'
                        : booking.date)
                    : '${booking.date} (${booking.startTime} - ${booking.endTime})',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(booking.status),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _statusLabel(booking.status),
                    style: TextStyle(
                      color: _getStatusColor(booking.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.expand_more, size: 18, color: AppColors.textSecondary),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 8),
                    if (booking.userName != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                              children: [
                                const TextSpan(text: 'Resident: ', style: TextStyle(fontWeight: FontWeight.w600)),
                                TextSpan(text: booking.userName),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone_android_rounded, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                              children: [
                                const TextSpan(text: 'Mobile: ', style: TextStyle(fontWeight: FontWeight.w600)),
                                TextSpan(text: booking.userMobile ?? 'N/A'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        const Icon(Icons.currency_rupee_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            children: [
                              const TextSpan(text: 'Amount: ', style: TextStyle(fontWeight: FontWeight.w600)),
                              TextSpan(
                                text: '₹${booking.amount}',
                                style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (isPending && PermissionService().canManage(ModuleCodes.amenities)) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _updateBookingStatus(booking.id, 'REJECTED'),
                            icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.accentRed),
                            label: const Text(
                              'Reject',
                              style: TextStyle(
                                color: AppColors.accentRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentRed.withValues(alpha: 0.1),
                              foregroundColor: AppColors.accentRed,
                              elevation: 0,
                              shadowColor: AppColors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: AppColors.accentRed, width: 1),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _updateBookingStatus(booking.id, 'CONFIRMED'),
                            icon: const Icon(Icons.check_rounded, size: 16, color: AppColors.white),
                            label: const Text(
                              'Approve',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Status Mappers ────────────────────────────────────────────────────────

  String _statusLabel(String status) {
    switch (status) {
      case 'CONFIRMED':
      case 'APPROVED':
        return 'Approved';
      case 'PENDING':
        return 'Pending';
      case 'REJECTED':
        return 'Rejected';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
      case 'APPROVED':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'REJECTED':
      case 'CANCELLED':
        return AppColors.accentRed;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'CONFIRMED':
      case 'APPROVED':
        return AppColors.accentGreen.withValues(alpha: 0.12);
      case 'PENDING':
        return AppColors.accentOrange.withValues(alpha: 0.12);
      case 'REJECTED':
      case 'CANCELLED':
        return AppColors.accentRed.withValues(alpha: 0.12);
      default:
        return AppColors.border;
    }
  }
}

// ─── Add Amenity Dialog ──────────────────────────────────────────────────────

class AddAmenityDialog extends StatefulWidget {
  const AddAmenityDialog({super.key});

  @override
  State<AddAmenityDialog> createState() => _AddAmenityDialogState();
}

class _AddAmenityDialogState extends State<AddAmenityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController(); // price per hour
  final _dailyPriceController = TextEditingController(); // price per day (FULL_DAY only)

  bool _isPaid = false;
  String _bookingType = 'SLOT';
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    );
    final focusBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    );

    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      title: const Text(
        'Add New Amenity',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.white,
                  enabledBorder: borderStyle,
                  focusedBorder: focusBorderStyle,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.white,
                  enabledBorder: borderStyle,
                  focusedBorder: focusBorderStyle,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Booking Type',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _bookingTypeOption(
                      label: 'Hourly Slot',
                      subtitle: 'Gym, yoga, courts…',
                      icon: Icons.access_time_rounded,
                      value: 'SLOT',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _bookingTypeOption(
                      label: 'Full Day',
                      subtitle: 'Hall, common plot…',
                      icon: Icons.event_available_rounded,
                      value: 'FULL_DAY',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text(
                  'Paid Amenity?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                value: _isPaid,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _isPaid = val);
                },
              ),
              if (_isPaid) ...[
                if (_bookingType == 'FULL_DAY') ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _dailyPriceController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Price Per Day (whole-day booking)',
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: AppColors.white,
                      enabledBorder: borderStyle,
                      focusedBorder: focusBorderStyle,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                ],
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: _bookingType == 'FULL_DAY'
                        ? 'Price Per Hour (for partial-day bookings)'
                        : 'Price Per Hour',
                    labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    prefixText: '₹ ',
                    prefixStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: AppColors.white,
                    enabledBorder: borderStyle,
                    focusedBorder: focusBorderStyle,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                ),
              ],
              if (_bookingType == 'SLOT') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, size: 16, color: AppColors.primary),
                        label: Text(
                          'Start: ${_startTime.format(context)}',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: AppColors.white,
                        ),
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: _startTime,
                          );
                          if (t != null) setState(() => _startTime = t);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, size: 16, color: AppColors.primary),
                        label: Text(
                          'End: ${_endTime.format(context)}',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: AppColors.white,
                        ),
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
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'Members can request either the whole day (or several days) or just a few specific hours — no fixed timing needed.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: _isLoading
              ? const NestLoader(size: 20, showDots: false)
              : const Text(
                  'Add',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _bookingTypeOption({
    required String label,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final selected = _bookingType == value;
    return GestureDetector(
      onTap: () => setState(() => _bookingType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primaryDark : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final payload = <String, dynamic>{
        'name': _nameController.text,
        'description': _descController.text,
        'is_paid': _isPaid,
        'booking_type': _bookingType,
        'is_active': true,
      };

      // price_per_hour applies to SLOT amenities and to partial-day bookings of a
      // FULL_DAY amenity, so it's sent for both types.
      payload['price_per_hour'] = _isPaid ? double.parse(_priceController.text) : 0;

      if (_bookingType == 'FULL_DAY') {
        payload['price_per_day'] = _isPaid ? double.parse(_dailyPriceController.text) : 0;
      } else {
        payload['start_time'] =
            '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00';
        payload['end_time'] =
            '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00';
      }

      await CommunityService().createAmenity(payload);

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

