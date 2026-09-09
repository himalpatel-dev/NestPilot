import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/nest_loader.dart';
import '../../theme/app_colors.dart';
import '../../widgets/module_page_header.dart';
import '../../widgets/app_field_card.dart';
import '../../widgets/app_form_sheet.dart';
import '../../widgets/glare_button.dart';
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

  void _openCreateSheet() {
    showAppFormSheet(
      context: context,
      builder: (ctx) => _AmenityFormSheet(
        onSaved: () {
          Navigator.pop(ctx);
          _fetchData();
        },
      ),
    );
  }

  void _openEditSheet(Amenity amenity) {
    showAppFormSheet(
      context: context,
      builder: (ctx) => _AmenityFormSheet(
        editing: amenity,
        onSaved: () {
          Navigator.pop(ctx);
          _fetchData();
        },
      ),
    );
  }

  Future<void> _deleteAmenity(Amenity amenity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.15),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                decoration: const BoxDecoration(
                  color: AppColors.accentRed,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.40),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Delete Amenity?',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      amenity.name,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.80),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  children: [
                    const Text(
                      'Residents will no longer be able to book it. Existing bookings are kept.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx, false),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx, true),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.accentRed,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentRed.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Delete',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
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
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteAmenity(amenity.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Amenity deleted')));
        _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  /// Bookings waiting on an approve/reject decision — drives the chip badge
  /// and the header stat, so requests are visible without opening the tab.
  int get _pendingCount =>
      _bookings.where((b) => b.status == 'PENDING').length;

  Widget _sectionChip(String label, int value, {int badgeCount = 0}) {
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 18),
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.white : AppColors.accentRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    color: selected ? AppColors.primaryDark : AppColors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
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
              stats: [
                ModuleHeaderStat('${_amenities.length}', 'FACILITIES'),
                ModuleHeaderStat('$_pendingCount', 'PENDING'),
                ModuleHeaderStat('${_bookings.length}', 'BOOKINGS'),
              ],
              showSearch: true,
              // The search box filters whichever section is open, so the hint
              // follows the selected chip.
              searchHint: _section == 0
                  ? 'Search amenities...'
                  : 'Search bookings...',
              searchController: _searchController,
              onSearchChanged: (v) => setState(() => _query = v),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  _sectionChip('Facilities', 0),
                  const SizedBox(width: 8),
                  _sectionChip('Bookings', 1, badgeCount: _pendingCount),
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
        floatingActionButton:
            PermissionService().canManage(ModuleCodes.amenities)
            ? FloatingActionButton(
                onPressed: _openCreateSheet,
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
    // Editing and deleting a facility are manage-only actions — the list
    // itself is shared with view-only roles.
    final canManage = PermissionService().canManage(ModuleCodes.amenities);

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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              amenity.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // A paid full-day amenity shows two prices in one
                          // badge — cap it so a long price can't push the row
                          // past the card edge on narrow screens.
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * 0.45,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isPaid
                                    ? AppColors.accentAmber.withValues(
                                        alpha: 0.12,
                                      )
                                    : AppColors.accentGreen.withValues(
                                        alpha: 0.12,
                                      ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isPaid
                                    ? (amenity.isFullDay
                                          ? "₹${amenity.pricePerDay}/day · ₹${amenity.pricePerHour}/hr"
                                          : "₹${amenity.pricePerHour}/hr")
                                    : "Free",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isPaid
                                      ? AppColors.warning
                                      : AppColors.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (amenity.description != null &&
                          amenity.description!.isNotEmpty) ...[
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Icon(
                              amenity.isFullDay
                                  ? Icons.event_available_rounded
                                  : Icons.access_time_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Wraps instead of overflowing — the full-day label is
                          // wider than the card on smaller phones.
                          Expanded(
                            child: Text(
                              amenity.isFullDay
                                  ? 'Full-day booking (as per requirement)'
                                  : 'Timing: ${amenity.startTime} - ${amenity.endTime}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (canManage) ...[
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () => _openEditSheet(amenity),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.accentIndigo.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: AppColors.accentIndigo,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _deleteAmenity(amenity),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.accentRed.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 14,
                            color: AppColors.accentRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
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
                    ? (booking.endDate != null &&
                              booking.endDate != booking.date
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                const Icon(
                  Icons.expand_more,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
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
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'Resident: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(text: booking.userName),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_android_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'Mobile: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(text: booking.userMobile ?? 'N/A'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        const Icon(
                          Icons.currency_rupee_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Amount: ',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
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
                        ),
                      ],
                    ),
                    if (isPending &&
                        PermissionService().canManage(
                          ModuleCodes.amenities,
                        )) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () =>
                                _updateBookingStatus(booking.id, 'REJECTED'),
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.accentRed,
                            ),
                            label: const Text(
                              'Reject',
                              style: TextStyle(
                                color: AppColors.accentRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentRed.withValues(
                                alpha: 0.1,
                              ),
                              foregroundColor: AppColors.accentRed,
                              elevation: 0,
                              shadowColor: AppColors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(
                                  color: AppColors.accentRed,
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _updateBookingStatus(booking.id, 'CONFIRMED'),
                            icon: const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: AppColors.white,
                            ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
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

// ── Add / edit amenity sheet ─────────────────────────────────────────────────

class _AmenityFormSheet extends StatefulWidget {
  final VoidCallback onSaved;
  final Amenity? editing;
  const _AmenityFormSheet({required this.onSaved, this.editing});

  @override
  State<_AmenityFormSheet> createState() => _AmenityFormSheetState();
}

class _AmenityFormSheetState extends State<_AmenityFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.editing?.name);
  late final _descCtrl = TextEditingController(
    text: widget.editing?.description,
  );
  late final _priceCtrl = TextEditingController(
    text: _priceText(widget.editing?.pricePerHour),
  );
  late final _dailyPriceCtrl = TextEditingController(
    text: _priceText(widget.editing?.pricePerDay),
  );

  late bool _isPaid = widget.editing?.isPaid ?? false;
  late String _bookingType = widget.editing?.bookingType ?? 'SLOT';
  late TimeOfDay _startTime =
      _parseTime(widget.editing?.startTime) ??
      const TimeOfDay(hour: 9, minute: 0);
  late TimeOfDay _endTime =
      _parseTime(widget.editing?.endTime) ??
      const TimeOfDay(hour: 22, minute: 0);

  bool _isLoading = false;

  // Inline error state — modal sheets hide snackbars behind them, so API
  // failures are surfaced in the sheet instead.
  String? _apiError;

  bool get _isEditing => widget.editing != null;

  bool get _isFullDay => _bookingType == 'FULL_DAY';

  /// Prices come back as doubles — prefill whole rupees without a ".0" tail,
  /// and leave the field blank for a free amenity.
  static String? _priceText(double? value) {
    if (value == null || value == 0) return null;
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  // start_time / end_time are 'HH:mm:ss' strings on the backend.
  static TimeOfDay? _parseTime(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _dailyPriceCtrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: appPickerTheme,
    );
    if (picked != null) {
      setState(() => isStart ? _startTime = picked : _endTime = picked);
    }
  }

  String? _validatePrice(String? v) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return 'Required';
    final value = double.tryParse(text);
    if (value == null || value <= 0) return 'Enter a valid amount';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _apiError = null;
    });
    try {
      final payload = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'is_paid': _isPaid,
        'booking_type': _bookingType,
        // price_per_hour applies to SLOT amenities and to partial-day bookings
        // of a FULL_DAY amenity, so it's sent for both types.
        'price_per_hour': _isPaid ? double.parse(_priceCtrl.text.trim()) : 0,
        'price_per_day': _isPaid && _isFullDay
            ? double.parse(_dailyPriceCtrl.text.trim())
            : 0,
        // Fixed timings only mean something for a slot amenity — sent as null
        // for a full-day one so switching type clears any stale hours.
        'start_time': _isFullDay ? null : _fmt(_startTime),
        'end_time': _isFullDay ? null : _fmt(_endTime),
      };

      if (_isEditing) {
        await CommunityService().updateAmenity(widget.editing!.id, payload);
      } else {
        payload['is_active'] = true;
        await CommunityService().createAmenity(payload);
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(
          () => _apiError = e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      accentColor: ModuleColors.amenities,
      icon: _isEditing ? Icons.edit_rounded : Icons.calendar_today_rounded,
      title: _isEditing ? 'Edit Amenity' : 'New Amenity',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader('Amenity Details'),
            const SizedBox(height: 14),
            AppFieldCard(
              icon: Icons.business_center_outlined,
              label: 'Name',
              field: AppBorderlessField(
                controller: _nameCtrl,
                hint: 'e.g. Community Hall',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
            ),
            const SizedBox(height: 12),
            AppFieldCard(
              icon: Icons.description_outlined,
              label: 'Description',
              iconAlignment: CrossAxisAlignment.start,
              field: AppBorderlessField(
                controller: _descCtrl,
                hint: 'Optional details residents should know…',
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 12),
            AppFieldCard(
              icon: Icons.category_outlined,
              label: 'Booking Type',
              field: AppCardDropdown<String>(
                value: _bookingType,
                items: const ['SLOT', 'FULL_DAY'],
                itemLabel: (t) => t == 'FULL_DAY' ? 'Full Day' : 'Hourly Slot',
                onChanged: (v) => setState(() => _bookingType = v!),
              ),
            ),
            const SizedBox(height: 24),
            const AppSectionHeader('Availability'),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                _isFullDay
                    ? 'Members can request either the whole day (or several days) or just a few specific hours — no fixed timing needed.'
                    : 'Hours residents can pick a slot from — e.g. gym, yoga or courts.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
            if (!_isFullDay) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppPickerCard(
                      icon: Icons.access_time_rounded,
                      label: 'Opens At',
                      value: _startTime.format(context),
                      hint: 'Start time',
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppPickerCard(
                      icon: Icons.access_time_outlined,
                      label: 'Closes At',
                      value: _endTime.format(context),
                      hint: 'End time',
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            const AppSectionHeader('Pricing'),
            const SizedBox(height: 14),
            _buildPaidToggle(),
            if (_isPaid) ...[
              if (_isFullDay) ...[
                const SizedBox(height: 12),
                AppFieldCard(
                  icon: Icons.currency_rupee_rounded,
                  label: 'Price Per Day',
                  field: AppBorderlessField(
                    controller: _dailyPriceCtrl,
                    hint: 'Whole-day booking charge',
                    keyboardType: TextInputType.number,
                    validator: _validatePrice,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              AppFieldCard(
                icon: Icons.schedule_rounded,
                label: _isFullDay
                    ? 'Price Per Hour (partial-day)'
                    : 'Price Per Hour',
                field: AppBorderlessField(
                  controller: _priceCtrl,
                  hint: 'e.g. 200',
                  keyboardType: TextInputType.number,
                  validator: _validatePrice,
                ),
              ),
            ],
            if (_apiError != null) ...[
              const SizedBox(height: 18),
              AppSheetErrorBanner(_apiError!),
            ],
            const SizedBox(height: 26),
            GlarePrimaryButton(
              text: _isEditing ? 'Update Amenity' : 'Add Amenity',
              trailingIcon: Icons.check_rounded,
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaidToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.payments_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAID AMENITY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Residents are charged for booking',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPaid,
            onChanged: (v) => setState(() => _isPaid = v),
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
