import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nest_pilot_mobile/models/community_models.dart';
import 'package:nest_pilot_mobile/services/community_service.dart';

import '../../theme/app_colors.dart';
import '../../theme/nest_loader.dart';
import '../../widgets/app_field_card.dart';
import '../../widgets/app_form_sheet.dart';
import '../../widgets/app_sheet_action.dart';
import '../../widgets/glare_button.dart';
import '../../widgets/module_page_header.dart';
import 'membership.dart';

/// Resident view of the society's amenities: browse the facilities, book one
/// (whole days or a few hours for halls, a time slot for courts, a membership
/// plan for a gym or pool), and follow each request under My Bookings. Free
/// bookings are confirmed straight away; paid ones wait for the society admin.
class AmenityBookingScreen extends StatefulWidget {
  const AmenityBookingScreen({super.key});

  @override
  State<AmenityBookingScreen> createState() => _AmenityBookingScreenState();
}

enum _FullDayMode { wholeDays, hours }

class _AmenityBookingScreenState extends State<AmenityBookingScreen> {
  final CommunityService _service = CommunityService();
  final TextEditingController _searchController = TextEditingController();
  List<Amenity> _amenities = [];
  List<Booking> _myBookings = [];
  bool _isLoading = true;
  String? _error;
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

  // Memberships have their own section; "upcoming" means reservations.
  int get _upcomingCount =>
      _myBookings.where((b) => !b.isMembership && _isUpcoming(b)).length;

  Amenity? _amenityById(int id) {
    for (final a in _amenities) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Running or queued memberships of [amenityId], earliest first — so the
  /// first is the one in force today (or the next to start).
  List<Booking> _liveMemberships(int amenityId) =>
      _myBookings
          .where(
            (b) =>
                b.isMembership &&
                b.amenityId == amenityId &&
                isLiveMembership(b),
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  int get _pendingCount =>
      _myBookings.where((b) => b.status == 'PENDING').length;

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

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        _service.getAllAmenities(),
        _service.getMyBookings(),
      ]);
      if (!mounted) return;
      setState(() {
        _amenities = results[0] as List<Amenity>;
        _myBookings = results[1] as List<Booking>;
        _error = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final message = _errorText(e);
      final hasData = _amenities.isNotEmpty || _myBookings.isNotEmpty;
      setState(() {
        // A failed refresh keeps what's already on screen.
        if (!hasData) _error = message;
        _isLoading = false;
      });
      if (hasData) _snack(message);
    }
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _fetchData();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ─── Booking flow ──────────────────────────────────────────────────────────

  /// Picks the date(s) / time, confirms the amount on a summary sheet, then
  /// jumps to My Bookings so the new request is right there.
  Future<void> _bookAmenity(Amenity amenity) async {
    if (amenity.isMembership) return _joinMembership(amenity);

    _BookingRequest? request;
    if (amenity.isFullDay) {
      final mode = await _chooseFullDayMode(amenity);
      if (mode == null || !mounted) return;
      request = mode == _FullDayMode.wholeDays
          ? await _pickDays(amenity)
          : await _pickHours(amenity);
    } else {
      request = await _pickHours(amenity);
    }
    final picked = request;
    if (picked == null || !mounted) return;

    final booked = await showAppFormSheet<bool>(
      context: context,
      builder: (_) => _ConfirmBookingSheet(amenity: amenity, request: picked),
    );
    if (booked != true || !mounted) return;

    _snack(
      amenity.isPaid
          ? 'Booking requested — the society admin will confirm it'
          : 'Booked! Your booking is confirmed',
    );
    setState(() => _section = 1);
    _fetchData();
  }

  /// Join, or renew straight after the latest running membership.
  Future<void> _joinMembership(Amenity amenity) async {
    final joined = await showMembershipSheet(
      context,
      amenity: amenity,
      current: latestLiveMembership(amenity.id, _myBookings),
    );
    if (joined != true || !mounted) return;

    _snack(
      amenity.isPaid
          ? 'Membership requested — it starts once the admin confirms payment'
          : "You're in! Your membership is active",
    );
    setState(() => _section = 1);
    _fetchData();
  }

  Future<_FullDayMode?> _chooseFullDayMode(Amenity amenity) {
    return showAppFormSheet<_FullDayMode>(
      context: context,
      builder: (ctx) => AppFormSheet(
        accentColor: ModuleColors.amenities,
        icon: Icons.event_available_rounded,
        title: 'Book ${amenity.name}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'How would you like to book it?',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            AppSheetAction(
              icon: Icons.date_range_rounded,
              label: 'Whole day(s)',
              subtitle: amenity.isPaid
                  ? '${_money(amenity.pricePerDay)} per day'
                  : 'Free · one or more full days',
              color: ModuleColors.amenities,
              onTap: () => Navigator.pop(ctx, _FullDayMode.wholeDays),
            ),
            AppSheetAction(
              icon: Icons.access_time_rounded,
              label: 'Specific hours',
              subtitle: amenity.isPaid
                  ? '${_money(amenity.pricePerHour)} per hour'
                  : 'Free · a few hours on one day',
              color: AppColors.accentBlue,
              onTap: () => Navigator.pop(ctx, _FullDayMode.hours),
            ),
          ],
        ),
      ),
    );
  }

  // Hall / common plot style — no fixed time, just the date(s) needed.
  Future<_BookingRequest?> _pickDays(Amenity amenity) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: today, end: today),
      helpText: 'Select date(s) for ${amenity.name}',
      builder: appPickerTheme,
    );
    if (range == null) return null;
    return _BookingRequest.days(range.start, range.end);
  }

  Future<_BookingRequest?> _pickHours(Amenity amenity) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
      helpText: 'Select date',
      builder: appPickerTheme,
    );
    if (date == null || !mounted) return null;

    final open = _parseTime(amenity.startTime);
    final close = _parseTime(amenity.endTime);
    final start = await showTimePicker(
      context: context,
      initialTime: open ?? const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Start time',
      builder: appPickerTheme,
    );
    if (start == null || !mounted) return null;

    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (start.hour + 1) % 24, minute: start.minute),
      helpText: 'End time',
      builder: appPickerTheme,
    );
    if (end == null || !mounted) return null;

    // The server takes any times it's sent, so the checks live here.
    if (_minutes(end) <= _minutes(start)) {
      _snack('End time must be after the start time');
      return null;
    }
    if (DateUtils.isSameDay(date, DateTime.now()) &&
        _minutes(start) <= _minutes(TimeOfDay.now())) {
      _snack('That time has already passed — pick a later start');
      return null;
    }
    if (!amenity.isFullDay &&
        open != null &&
        close != null &&
        (_minutes(start) < _minutes(open) || _minutes(end) > _minutes(close))) {
      _snack(
        '${amenity.name} is open ${_formatTime(open)} – ${_formatTime(close)}',
      );
      return null;
    }
    return _BookingRequest.hours(date, start, end);
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      // The pinned block is tall — let the keyboard cover the list rather than
      // squeeze the column and overflow on small phones.
      resizeToAvoidBottomInset: false,
      // Header, search and section chips stay pinned; only the list scrolls.
      body: Column(
        children: [
          ModulePageHeader(
            title: 'Amenities',
            description: 'Book facilities & track your bookings',
            icon: Icons.calendar_today_outlined,
            iconColor: ModuleColors.amenities,
            stats: [
              ModuleHeaderStat('${_amenities.length}', 'FACILITIES'),
              ModuleHeaderStat('$_upcomingCount', 'UPCOMING'),
              ModuleHeaderStat('$_pendingCount', 'PENDING'),
            ],
            showSearch: true,
            // The search box filters whichever section is open, so the hint
            // follows the selected chip.
            searchHint: _section == 0
                ? 'Search amenities...'
                : 'Search your bookings...',
            searchController: _searchController,
            onSearchChanged: (v) => setState(() => _query = v),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                : RefreshIndicator(
                    onRefresh: _fetchData,
                    color: AppColors.white,
                    backgroundColor: AppColors.primary,
                    child: _error != null
                        ? _fillScroll(
                            _messageBox(
                              icon: Icons.error_outline,
                              title: 'Could not load amenities',
                              subtitle: _error,
                              actionLabel: 'Retry',
                              onAction: _retry,
                            ),
                          )
                        : _section == 0
                        ? _buildFacilities(bottomPad)
                        : _buildBookings(bottomPad),
                  ),
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

  // ─── Facilities ────────────────────────────────────────────────────────────

  Widget _buildFacilities(double bottomPad) {
    final amenities = _filteredAmenities;
    if (amenities.isEmpty) {
      final searching = _query.trim().isNotEmpty;
      return _emptyState(
        icon: searching
            ? Icons.search_off_rounded
            : Icons.sports_soccer_rounded,
        title: searching
            ? 'No amenities match your search'
            : 'No amenities yet',
        message: searching
            ? 'Try a different name.'
            : "Your society hasn't added any facilities to book yet.",
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad + 24),
      itemCount: amenities.length,
      itemBuilder: (context, i) => _facilityCard(amenities[i]),
    );
  }

  // Same card as the admin Amenities list, with a Book action in place of
  // edit.
  Widget _facilityCard(Amenity amenity) {
    final hasDescription = (amenity.description ?? '').trim().isNotEmpty;
    final hours = amenity.isMembership
        ? 'Membership · ${membershipHoursLabel(amenity) ?? 'use any time'}'
        : amenity.isFullDay
        ? 'Whole days or a few hours'
        : (amenity.startTime != null && amenity.endTime != null
              ? 'Open ${_apiTimeLabel(amenity.startTime)} – '
                    '${_apiTimeLabel(amenity.endTime)}'
              : 'Hourly slots');
    final memberships = amenity.isMembership
        ? _liveMemberships(amenity.id)
        : const <Booking>[];
    final actionLabel = !amenity.isMembership
        ? 'Book'
        : memberships.isEmpty
        ? 'Join'
        : 'Renew';
    final actionIcon = !amenity.isMembership
        ? Icons.event_available_rounded
        : memberships.isEmpty
        ? Icons.card_membership_rounded
        : Icons.autorenew_rounded;

    return GestureDetector(
      onTap: () => _bookAmenity(amenity),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(radius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _amenityThumb(amenity),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        amenity.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (hasDescription) ...[
                        const SizedBox(height: 4),
                        Text(
                          amenity.description!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _priceBadge(amenity),
              ],
            ),
            if (memberships.isNotEmpty) ...[
              const SizedBox(height: 12),
              _memberStrip(memberships),
            ],
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  amenity.isMembership
                      ? Icons.card_membership_rounded
                      : amenity.isFullDay
                      ? Icons.event_available_rounded
                      : Icons.access_time_rounded,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hours,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _bookButton(
                  () => _bookAmenity(amenity),
                  label: actionLabel,
                  icon: actionIcon,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// "Member until 15 Dec 2026" (plus any renewal already queued) on a
  /// membership facility the resident belongs to. [live] is earliest first.
  Widget _memberStrip(List<Booking> live) {
    final current = live.first;
    final state = membershipStateOf(current);
    final color = membershipStateColor(state);
    final day = DateFormat('d MMM yyyy');
    final end = _parseDate(current.endDate);
    final start = _parseDate(current.date);
    final queued = live.length > 1 ? live.last : null;

    final (IconData icon, String text) = switch (state) {
      MembershipState.active => (
        Icons.verified_rounded,
        'Member until ${end == null ? '--' : day.format(end)}',
      ),
      MembershipState.scheduled => (
        Icons.event_rounded,
        'Membership starts ${start == null ? '--' : day.format(start)}',
      ),
      _ => (Icons.hourglass_top_rounded, 'Membership request pending'),
    };
    final renewal = queued == null
        ? ''
        : membershipStateOf(queued) == MembershipState.pending
        ? ' · renewal pending'
        : ' · renewed';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: membershipStateBg(state),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$text$renewal',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceBadge(Amenity amenity) {
    final isPaid = amenity.isPaid;
    // A paid full-day amenity shows two prices in one badge — cap it so a long
    // price can't push the row past the card edge on narrow screens.
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.4,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isPaid
              ? AppColors.accentAmber.withValues(alpha: 0.12)
              : AppColors.accentGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _priceLabel(amenity),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isPaid ? AppColors.warning : AppColors.success,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _bookButton(
    VoidCallback onTap, {
    String label = 'Book',
    IconData icon = Icons.event_available_rounded,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── My Bookings ───────────────────────────────────────────────────────────

  Widget _buildBookings(double bottomPad) {
    final bookings = _filteredBookings;
    if (bookings.isEmpty) {
      final searching = _query.trim().isNotEmpty;
      return _emptyState(
        icon: searching ? Icons.search_off_rounded : Icons.event_note_outlined,
        title: searching ? 'No bookings match your search' : 'No bookings yet',
        message: searching
            ? 'Try a different amenity name.'
            : 'Book a facility and it will show up here.',
        actionLabel: searching ? null : 'Browse facilities',
        onAction: searching ? null : () => setState(() => _section = 0),
      );
    }

    // Running / queued memberships first, then reservations still ahead
    // (soonest first); the API already sends the rest newest first.
    final memberships =
        bookings.where((b) => b.isMembership && isLiveMembership(b)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final upcoming =
        bookings.where((b) => !b.isMembership && _isUpcoming(b)).toList()
          ..sort((a, b) => _sortKey(a).compareTo(_sortKey(b)));
    final history = bookings
        .where((b) => b.isMembership ? !isLiveMembership(b) : !_isUpcoming(b))
        .toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad + 24),
      children: [
        if (memberships.isNotEmpty) ...[
          const AppSectionHeader('Memberships'),
          const SizedBox(height: 12),
          for (final b in memberships) _membershipCard(b),
        ],
        if (upcoming.isNotEmpty) ...[
          if (memberships.isNotEmpty) const SizedBox(height: 10),
          const AppSectionHeader('Upcoming'),
          const SizedBox(height: 12),
          for (final b in upcoming) _bookingCard(b, upcoming: true),
        ],
        if (history.isNotEmpty) ...[
          if (memberships.isNotEmpty || upcoming.isNotEmpty)
            const SizedBox(height: 10),
          const AppSectionHeader('History'),
          const SizedBox(height: 12),
          for (final b in history)
            b.isMembership
                ? _membershipCard(b)
                : _bookingCard(b, upcoming: false),
        ],
      ],
    );
  }

  /// A membership pass: plan and validity, days left with a progress bar
  /// while it runs, and Renew once it's close to ending (or has ended).
  Widget _membershipCard(Booking b) {
    final state = membershipStateOf(b);
    final daysLeft = membershipDaysLeft(b);
    final renewAmenity = _renewableAmenity(b);
    final canRenew = renewAmenity != null;

    final String amount;
    if (b.amount <= 0) {
      amount = 'Free';
    } else if (b.paymentStatus == 'PAID') {
      amount = '${_money(b.amount)} · Paid';
    } else if (state == MembershipState.pending) {
      amount = '${_money(b.amount)} · Awaiting payment confirmation';
    } else {
      amount = _money(b.amount);
    }

    return GestureDetector(
      onTap: () => _openDetails(b),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(radius: 18),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _membershipTile(b, state, daysLeft),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              b.amenity?.name ?? 'Amenity',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _pill(
                            membershipStateLabel(state),
                            color: membershipStateColor(state),
                            background: membershipStateBg(state),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _metaRow(
                        Icons.card_membership_rounded,
                        '${b.planName ?? 'Membership'} · '
                        '${membershipPeriodLabel(b)}',
                      ),
                      const SizedBox(height: 5),
                      _metaRow(Icons.currency_rupee_rounded, amount),
                    ],
                  ),
                ),
              ],
            ),
            if (state == MembershipState.active || canRenew) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: state == MembershipState.active
                        ? _usageBar(b, daysLeft)
                        : const Text(
                            'Your membership has ended',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  if (renewAmenity != null) ...[
                    const SizedBox(width: 12),
                    _bookButton(
                      () => _joinMembership(renewAmenity),
                      label: 'Renew',
                      icon: Icons.autorenew_rounded,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The amenity to renew [b] on, when Renew applies to it — only on the
  /// newest membership: while it runs (in its last fortnight), or once it has
  /// expired with nothing newer in place. Null otherwise.
  Amenity? _renewableAmenity(Booking b) {
    if (!b.isMembership) return null;
    final amenity = _amenityById(b.amenityId);
    if (amenity == null || !amenity.isMembership) return null;
    final state = membershipStateOf(b);
    final latestLive = latestLiveMembership(b.amenityId, _myBookings);
    final renewable =
        (state == MembershipState.active &&
            latestLive?.id == b.id &&
            membershipDaysLeft(b) <= 15) ||
        (state == MembershipState.expired &&
            latestLive == null &&
            _isNewestMembership(b));
    return renewable ? amenity : null;
  }

  /// The renewal already queued after membership [b], if any.
  Booking? _nextMembership(Booking b) {
    Booking? next;
    for (final o in _myBookings) {
      if (o.id == b.id || !o.isMembership || o.amenityId != b.amenityId) {
        continue;
      }
      if (!isLiveMembership(o)) continue;
      if (o.date.compareTo(b.endDate ?? b.date) <= 0) continue;
      if (next == null || o.date.compareTo(next.date) < 0) next = o;
    }
    return next;
  }

  /// Full details of one booking or membership, with Renew when it applies.
  Future<void> _openDetails(Booking b) async {
    final renewAmenity = _renewableAmenity(b);
    final renew = await showAppFormSheet<bool>(
      context: context,
      builder: (_) => _BookingDetailsSheet(
        booking: b,
        amenity: b.amenity ?? _amenityById(b.amenityId),
        next: b.isMembership ? _nextMembership(b) : null,
        canRenew: renewAmenity != null,
      ),
    );
    if (renew == true && renewAmenity != null && mounted) {
      _joinMembership(renewAmenity);
    }
  }

  /// No other (non-rejected) membership of the same amenity ends later.
  bool _isNewestMembership(Booking b) => !_myBookings.any(
    (o) =>
        o.id != b.id &&
        o.isMembership &&
        o.amenityId == b.amenityId &&
        o.status != 'REJECTED' &&
        o.status != 'CANCELLED' &&
        (o.endDate ?? o.date).compareTo(b.endDate ?? b.date) > 0,
  );

  /// Days-left tile while a membership runs; a calendar leaf otherwise
  /// (start date while pending/upcoming, end date once over).
  Widget _membershipTile(Booking b, MembershipState state, int daysLeft) {
    switch (state) {
      case MembershipState.active:
        const color = ModuleColors.amenities;
        return Container(
          width: 54,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              FittedBox(
                child: Text(
                  '$daysLeft',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                daysLeft == 1 ? 'DAY\nLEFT' : 'DAYS\nLEFT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color.lerp(color, AppColors.black, 0.25),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  height: 1.15,
                ),
              ),
            ],
          ),
        );
      case MembershipState.pending:
      case MembershipState.scheduled:
        return _dateLeaf(_parseDate(b.date), muted: false);
      default:
        return _dateLeaf(_parseDate(b.endDate ?? b.date), muted: true);
    }
  }

  Widget _bookingCard(Booking b, {required bool upcoming}) {
    final amount = b.amount > 0 ? _money(b.amount) : 'Free';
    return GestureDetector(
      onTap: () => _openDetails(b),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(radius: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dateLeaf(_parseDate(b.date), muted: !upcoming),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          b.amenity?.name ?? 'Amenity',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _statusPill(b.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _metaRow(Icons.access_time_rounded, _whenLabel(b)),
                  const SizedBox(height: 5),
                  _metaRow(Icons.currency_rupee_rounded, amount),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Calendar-leaf date tile — month, day and weekday.
  Widget _dateLeaf(DateTime? d, {required bool muted}) {
    final color = muted ? AppColors.textMuted : ModuleColors.amenities;
    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            d == null ? '--' : DateFormat('MMM').format(d).toUpperCase(),
            style: TextStyle(
              color: Color.lerp(color, AppColors.black, 0.25),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            d == null ? '--' : '${d.day}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            d == null ? '' : DateFormat('EEE').format(d),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Shared pieces ─────────────────────────────────────────────────────────

  BoxDecoration _cardDecoration({required double radius}) => BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Centres [child] in a scrollable, so pull-to-refresh still works on an
  // empty or failed list.
  Widget _fillScroll(Widget child) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(padding: const EdgeInsets.all(24), child: child),
          ),
        ),
      ],
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    const tint = ModuleColors.amenities;
    return _fillScroll(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: Color.lerp(tint, AppColors.black, 0.2),
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Same message box as the User Management list.
  Widget _messageBox({
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 18),
      alignment: Alignment.center,
      decoration: _cardDecoration(radius: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textHint, size: 32),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Booking request ─────────────────────────────────────────────────────────

/// What the resident picked, before it's sent: whole days [start]–[end], or
/// [from]–[to] on [start].
class _BookingRequest {
  final DateTime start;
  final DateTime end;
  final TimeOfDay? from;
  final TimeOfDay? to;

  const _BookingRequest.days(this.start, this.end) : from = null, to = null;

  const _BookingRequest.hours(
    this.start,
    TimeOfDay this.from,
    TimeOfDay this.to,
  ) : end = start;

  bool get isHourly => from != null && to != null;

  int get days => _daysBetween(start, end) + 1;

  double get hours => isHourly ? (_minutes(to!) - _minutes(from!)) / 60 : 0;

  /// Same maths as the server, so the figure shown is the one charged.
  double amountFor(Amenity a) {
    if (!a.isPaid) return 0;
    return isHourly ? hours * a.pricePerHour : days * a.pricePerDay;
  }

  String get dateLabel {
    final full = DateFormat('EEE, d MMM yyyy');
    if (isHourly || days == 1) return full.format(start);
    return '${DateFormat('d MMM').format(start)} – ${full.format(end)}';
  }

  String get timeLabel {
    if (!isHourly) return days == 1 ? 'Whole day' : '$days whole days';
    return '${_formatTime(from!)} – ${_formatTime(to!)} · ${_hoursLabel(hours)}';
  }

  Map<String, dynamic> payload(int amenityId) => {
    'amenity_id': amenityId,
    'date': _apiDate(start),
    if (isHourly) ...{
      'start_time': _apiTime(from!),
      'end_time': _apiTime(to!),
    } else
      'end_date': _apiDate(end),
  };
}

// ─── Confirm sheet ───────────────────────────────────────────────────────────

/// Summary of the request with the amount it will cost; sends it and pops
/// `true` once the server accepts. Errors stay inside the sheet, since a
/// snackbar would sit underneath it.
class _ConfirmBookingSheet extends StatefulWidget {
  final Amenity amenity;
  final _BookingRequest request;

  const _ConfirmBookingSheet({required this.amenity, required this.request});

  @override
  State<_ConfirmBookingSheet> createState() => _ConfirmBookingSheetState();
}

class _ConfirmBookingSheetState extends State<_ConfirmBookingSheet> {
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await CommunityService().bookAmenity(
        widget.request.payload(widget.amenity.id),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _errorText(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.amenity;
    final r = widget.request;
    final breakdown = !a.isPaid
        ? null
        : r.isHourly
        ? '${_hoursLabel(r.hours)} × ${_money(a.pricePerHour)}/hr'
        : '${r.days} ${r.days == 1 ? 'day' : 'days'} × '
              '${_money(a.pricePerDay)}/day';

    return AppFormSheet(
      accentColor: ModuleColors.amenities,
      icon: Icons.event_available_rounded,
      title: 'Confirm Booking',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            AppSheetErrorBanner(_error!),
            const SizedBox(height: 14),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
            child: Column(
              children: [
                _summaryRow(
                  icon: Icons.sports_soccer_rounded,
                  color: ModuleColors.amenities,
                  label: 'Amenity',
                  value: a.name,
                ),
                const Divider(height: 1, color: AppColors.border),
                _summaryRow(
                  icon: Icons.calendar_today_rounded,
                  color: AppColors.accentBlue,
                  label: r.days > 1 ? 'Dates' : 'Date',
                  value: r.dateLabel,
                ),
                const Divider(height: 1, color: AppColors.border),
                _summaryRow(
                  icon: Icons.access_time_rounded,
                  color: AppColors.accentIndigo,
                  label: r.isHourly ? 'Time' : 'Duration',
                  value: r.timeLabel,
                ),
                const Divider(height: 1, color: AppColors.border),
                _summaryRow(
                  icon: Icons.currency_rupee_rounded,
                  color: AppColors.accentAmber,
                  label: 'Amount',
                  value: a.isPaid ? _money(r.amountFor(a)) : 'Free',
                  hint: breakdown,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          a.isPaid
              ? _note(
                  icon: Icons.hourglass_top_rounded,
                  color: AppColors.accentAmber,
                  text:
                      'Paid bookings stay Pending until the society admin '
                      'approves them.',
                )
              : _note(
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.accentGreen,
                  text: 'Free bookings are confirmed right away.',
                ),
          const SizedBox(height: 24),
          GlarePrimaryButton(
            text: a.isPaid ? 'Request Booking' : 'Confirm Booking',
            isLoading: _saving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// ─── Booking details sheet ───────────────────────────────────────────────────

/// Everything about one of the resident's bookings or memberships: where it
/// stands, the dates / time or plan and validity, the amount, when it was
/// requested, and what happens next. Pops `true` when Renew is tapped.
class _BookingDetailsSheet extends StatelessWidget {
  final Booking booking;

  /// The facility booked (from the booking itself, or the facilities list).
  final Amenity? amenity;

  /// The renewal already queued after this membership, if any.
  final Booking? next;

  final bool canRenew;

  const _BookingDetailsSheet({
    required this.booking,
    required this.amenity,
    required this.next,
    required this.canRenew,
  });

  static final _dayFull = DateFormat('EEE, d MMM yyyy');
  static final _dayShort = DateFormat('d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return AppFormSheet(
      accentColor: ModuleColors.amenities,
      icon: b.isMembership
          ? Icons.card_membership_rounded
          : Icons.event_note_rounded,
      title: b.isMembership ? 'Membership Details' : 'Booking Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: 14),
          _detailsCard(b.isMembership ? _membershipRows() : _bookingRows()),
          const SizedBox(height: 14),
          _statusNote(),
          if (next != null) ...[const SizedBox(height: 10), _renewalNote()],
          if (canRenew) ...[
            const SizedBox(height: 24),
            GlarePrimaryButton(
              text: 'Renew Membership',
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ],
      ),
    );
  }

  /// Facility, reference number and status — plus the days-left bar while a
  /// membership runs.
  Widget _header() {
    final b = booking;
    final state = b.isMembership ? membershipStateOf(b) : null;
    final reference = b.isMembership
        ? 'Membership #${b.id}'
        : 'Booking #${b.id}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _sheetCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _amenityThumb(amenity),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      amenity?.name ?? 'Amenity',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      reference,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              state == null
                  ? _statusPill(b.status)
                  : _pill(
                      membershipStateLabel(state),
                      color: membershipStateColor(state),
                      background: membershipStateBg(state),
                    ),
            ],
          ),
          if (state == MembershipState.active) ...[
            const SizedBox(height: 14),
            _usageBar(b, membershipDaysLeft(b)),
          ],
        ],
      ),
    );
  }

  /// White card of label/value rows split by hairlines, as on Confirm
  /// Booking.
  Widget _detailsCard(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: _sheetCardDecoration,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            rows[i],
          ],
        ],
      ),
    );
  }

  List<Widget> _bookingRows() {
    final b = booking;
    final start = _parseDate(b.date);
    final end = _parseDate(b.endDate ?? b.date);
    final days = start == null || end == null
        ? 1
        : _daysBetween(start, end) + 1;

    final String dateValue;
    if (start == null) {
      dateValue = b.date;
    } else if (days <= 1 || end == null) {
      dateValue = _dayFull.format(start);
    } else {
      dateValue =
          '${DateFormat('EEE, d MMM').format(start)} – ${_dayFull.format(end)}';
    }

    final String timeValue;
    if (b.isFullDay) {
      timeValue = days <= 1 ? 'Whole day' : '$days whole days';
    } else {
      final from = _parseTime(b.startTime);
      final to = _parseTime(b.endTime);
      final span =
          '${_apiTimeLabel(b.startTime)} – ${_apiTimeLabel(b.endTime)}';
      timeValue = from == null || to == null
          ? span
          : '$span · ${_hoursLabel((_minutes(to) - _minutes(from)) / 60)}';
    }

    return [
      _summaryRow(
        icon: Icons.calendar_today_rounded,
        color: AppColors.accentBlue,
        label: days > 1 ? 'Dates' : 'Date',
        value: dateValue,
      ),
      _summaryRow(
        icon: Icons.access_time_rounded,
        color: AppColors.accentIndigo,
        label: b.isFullDay ? 'Duration' : 'Time',
        value: timeValue,
      ),
      _summaryRow(
        icon: Icons.currency_rupee_rounded,
        color: AppColors.accentAmber,
        label: 'Amount',
        value: b.amount > 0 ? _money(b.amount) : 'Free',
      ),
      ?_requestedRow(),
    ];
  }

  List<Widget> _membershipRows() {
    final b = booking;
    final start = _parseDate(b.date);
    final end = _parseDate(b.endDate ?? b.date);
    final totalDays = start == null || end == null
        ? null
        : _daysBetween(start, end) + 1;
    final a = amenity;
    final hasHours = a != null && a.startTime != null && a.endTime != null;

    final String? paymentHint;
    if (b.amount <= 0) {
      paymentHint = null;
    } else if (b.paymentStatus == 'PAID') {
      paymentHint = 'Paid';
    } else if (b.status == 'PENDING') {
      paymentHint = 'Awaiting payment confirmation';
    } else {
      paymentHint = null;
    }

    return [
      _summaryRow(
        icon: Icons.card_membership_rounded,
        color: ModuleColors.amenities,
        label: 'Plan',
        value: b.planName ?? 'Membership',
      ),
      _summaryRow(
        icon: Icons.date_range_rounded,
        color: AppColors.accentBlue,
        label: 'Valid',
        value: start == null || end == null
            ? b.date
            : '${_dayShort.format(start)} – ${_dayShort.format(end)}',
        hint: totalDays == null
            ? null
            : '$totalDays ${totalDays == 1 ? 'day' : 'days'}',
      ),
      if (hasHours)
        _summaryRow(
          icon: Icons.access_time_rounded,
          color: AppColors.accentIndigo,
          label: 'Opening Hours',
          value: '${_apiTimeLabel(a.startTime)} – ${_apiTimeLabel(a.endTime)}',
          hint: 'Use it any time in this window',
        ),
      _summaryRow(
        icon: Icons.currency_rupee_rounded,
        color: AppColors.accentAmber,
        label: 'Amount',
        value: b.amount > 0 ? membershipMoney(b.amount) : 'Free',
        hint: paymentHint,
      ),
      ?_requestedRow(),
    ];
  }

  /// "Requested On" from the booking's creation time, when the API sent it.
  Widget? _requestedRow() {
    final created = DateTime.tryParse(booking.createdAt ?? '');
    if (created == null) return null;
    return _summaryRow(
      icon: Icons.schedule_send_rounded,
      color: AppColors.accentTeal,
      label: 'Requested On',
      value: DateFormat('d MMM yyyy, h:mm a').format(created.toLocal()),
    );
  }

  /// What the status means for the resident, and what happens next.
  Widget _statusNote() {
    final b = booking;
    if (b.status == 'REJECTED') {
      return _note(
        icon: Icons.cancel_outlined,
        color: AppColors.accentRed,
        text:
            'The society admin declined this request. Contact the society '
            'office if you have questions.',
      );
    }
    if (b.status == 'CANCELLED') {
      return _note(
        icon: Icons.block_rounded,
        color: AppColors.accentRed,
        text: b.isMembership
            ? 'This membership was cancelled.'
            : 'This booking was cancelled.',
      );
    }

    if (b.isMembership) {
      final start = _parseDate(b.date);
      final end = _parseDate(b.endDate ?? b.date);
      final from = start == null ? '--' : _dayFull.format(start);
      final until = end == null ? '--' : _dayFull.format(end);
      return switch (membershipStateOf(b)) {
        MembershipState.pending => _note(
          icon: Icons.hourglass_top_rounded,
          color: AppColors.accentAmber,
          text: b.amount > 0
              ? 'Waiting for the society admin to confirm your payment. '
                    'The membership starts once it is marked paid.'
              : 'Waiting for the society admin to approve it.',
        ),
        MembershipState.scheduled => _note(
          icon: Icons.event_available_rounded,
          color: AppColors.accentBlue,
          text:
              'Confirmed. It starts on $from, and you can use it any time '
              'during opening hours from then.',
        ),
        MembershipState.active => _note(
          icon: Icons.verified_rounded,
          color: AppColors.accentGreen,
          text: 'Active. Use it any time during opening hours until $until.',
        ),
        _ => _note(
          icon: Icons.history_rounded,
          color: AppColors.textSecondary,
          text: 'This membership ended on $until.',
        ),
      };
    }

    final upcoming = _isUpcoming(b);
    if (b.status == 'PENDING') {
      return upcoming
          ? _note(
              icon: Icons.hourglass_top_rounded,
              color: AppColors.accentAmber,
              text: 'Waiting for the society admin to approve this request.',
            )
          : _note(
              icon: Icons.history_rounded,
              color: AppColors.textSecondary,
              text: 'This request was not approved before its date passed.',
            );
    }
    return upcoming
        ? _note(
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.accentGreen,
            text:
                'Confirmed. The ${amenity?.name ?? 'amenity'} is reserved for '
                'you.',
          )
        : _note(
            icon: Icons.history_rounded,
            color: AppColors.textSecondary,
            text: 'This booking is over.',
          );
  }

  /// The membership already queued to follow this one.
  Widget _renewalNote() {
    final n = next!;
    final pending = membershipStateOf(n) == MembershipState.pending;
    return _note(
      icon: Icons.autorenew_rounded,
      color: AppColors.accentBlue,
      text:
          'Renewed: your next membership (${n.planName ?? 'Membership'}) runs '
          '${membershipPeriodLabel(n)}'
          '${pending ? ', awaiting payment confirmation' : ''}.',
    );
  }
}

// ─── Shared widgets ──────────────────────────────────────────────────────────

final _sheetCardDecoration = BoxDecoration(
  color: AppColors.white,
  borderRadius: BorderRadius.circular(18),
  boxShadow: [
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ],
);

Widget _amenityThumb(Amenity? amenity) {
  const fallback = Icon(
    Icons.sports_soccer_rounded,
    color: AppColors.primary,
    size: 28,
  );
  final image = amenity?.imageUrl;
  return Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
    ),
    alignment: Alignment.center,
    child: image == null || image.isEmpty
        ? fallback
        : ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              image,
              fit: BoxFit.cover,
              width: 52,
              height: 52,
              errorBuilder: (_, _, _) => fallback,
            ),
          ),
  );
}

Widget _usageBar(Booking b, int daysLeft) {
  final endingSoon = daysLeft <= 7;
  final color = endingSoon ? AppColors.accentOrange : ModuleColors.amenities;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: membershipProgress(b),
          minHeight: 6,
          color: color,
          backgroundColor: AppColors.cardBackground,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        endingSoon
            ? 'Ends in $daysLeft ${daysLeft == 1 ? 'day' : 'days'} — renew to keep access'
            : '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: endingSoon
              ? Color.lerp(color, AppColors.black, 0.3)
              : AppColors.textSecondary,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

// Same status pill as the admin Bookings tab.
Widget _statusPill(String status) => _pill(
  _statusLabel(status),
  color: _statusColor(status),
  background: _statusBgColor(status),
);

Widget _pill(String label, {required Color color, required Color background}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

// Tinted icon tile over an uppercase label and value — the same detail row
// as the profile page.
Widget _summaryRow({
  required IconData icon,
  required Color color,
  required String label,
  required String value,
  String? hint,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (hint != null) ...[
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

// Tinted info note, like the User Management detail sheet's.
Widget _note({
  required IconData icon,
  required Color color,
  required String text,
}) {
  final ink = Color.lerp(color, AppColors.black, 0.35)!;
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Row(
      children: [
        Icon(icon, color: ink, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: ink,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _errorText(Object e) => e.toString().replaceFirst('Exception: ', '');

int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;

/// "09:00" / "09:00:00" from the API → TimeOfDay.
TimeOfDay? _parseTime(String? value) {
  final parts = (value ?? '').split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return TimeOfDay(hour: h, minute: m);
}

String _formatTime(TimeOfDay t) =>
    DateFormat('h:mm a').format(DateTime(2000, 1, 1, t.hour, t.minute));

/// "18:30:00" → "6:30 PM"; anything unparsable passes through as-is.
String _apiTimeLabel(String? value) {
  final t = _parseTime(value);
  return t == null ? (value ?? '--') : _formatTime(t);
}

String _apiDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

String _apiTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:'
    '${t.minute.toString().padLeft(2, '0')}:00';

DateTime? _parseDate(String? value) =>
    value == null ? null : DateTime.tryParse(value);

// Calendar days from [a] to [b], counted in UTC so a DST shift can't turn a
// 23-hour day into zero.
int _daysBetween(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// Prices come back as doubles — drop the ".00" tail on whole rupees.
String _money(double value) => value == value.roundToDouble()
    ? '₹${value.toStringAsFixed(0)}'
    : '₹${value.toStringAsFixed(2)}';

String _hoursLabel(double hours) {
  if (hours == hours.roundToDouble()) {
    final h = hours.toInt();
    return '$h ${h == 1 ? 'hr' : 'hrs'}';
  }
  return '${hours.toStringAsFixed(1)} hrs';
}

String _priceLabel(Amenity a) {
  if (a.isMembership) return membershipPriceLabel(a);
  if (!a.isPaid) return 'Free';
  return a.isFullDay
      ? '${_money(a.pricePerDay)}/day · ${_money(a.pricePerHour)}/hr'
      : '${_money(a.pricePerHour)}/hr';
}

/// Still ahead (or today) and not turned down.
bool _isUpcoming(Booking b) {
  if (b.status == 'REJECTED' || b.status == 'CANCELLED') return false;
  final end = _parseDate(b.endDate ?? b.date);
  return end != null && _daysBetween(DateTime.now(), end) >= 0;
}

String _sortKey(Booking b) => '${b.date} ${b.startTime ?? ''}';

String _whenLabel(Booking b) {
  if (!b.isFullDay) {
    return '${_apiTimeLabel(b.startTime)} – ${_apiTimeLabel(b.endTime)}';
  }
  final start = _parseDate(b.date);
  final end = _parseDate(b.endDate ?? b.date);
  if (start == null || end == null) return 'Whole day';
  final days = _daysBetween(start, end) + 1;
  if (days <= 1) return 'Whole day';
  return 'Whole day · until ${DateFormat('d MMM').format(end)} ($days days)';
}

// Same status wording and colours as the admin Bookings tab.
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

Color _statusColor(String status) {
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

Color _statusBgColor(String status) {
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
