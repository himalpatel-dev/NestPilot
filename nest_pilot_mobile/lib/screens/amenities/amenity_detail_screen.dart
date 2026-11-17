import 'package:flutter/material.dart';
import 'package:nest_pilot_mobile/config/modules.dart';
import 'package:nest_pilot_mobile/models/community_models.dart';
import 'package:nest_pilot_mobile/services/community_service.dart';
import 'package:nest_pilot_mobile/services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_page_header.dart';
import 'membership.dart';

class AmenityDetailScreen extends StatefulWidget {
  final Amenity amenity;

  /// Bookings the management list already loaded, filtered to this amenity —
  /// shown read-only here; approving/rejecting stays on the Bookings tab.
  final List<Booking> bookings;

  const AmenityDetailScreen({
    super.key,
    required this.amenity,
    this.bookings = const [],
  });

  @override
  State<AmenityDetailScreen> createState() => _AmenityDetailScreenState();
}

class _AmenityDetailScreenState extends State<AmenityDetailScreen> {
  final CommunityService _service = CommunityService();
  bool _deleting = false;

  /// Prices come back as doubles — drop the ".0" tail on whole rupees.
  String _money(double value) => value == value.roundToDouble()
      ? '₹${value.toStringAsFixed(0)}'
      : '₹$value';

  /// Removes the amenity and pops `true` so the list knows to refetch.
  Future<void> _confirmDelete() async {
    final a = widget.amenity;
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
                      a.name,
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

    setState(() => _deleting = true);
    try {
      await _service.deleteAmenity(a.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.amenity;
    final canManage = PermissionService().canManage(ModuleCodes.amenities);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isPaid = a.isPaid;
    final priceColor = isPaid ? AppColors.warning : AppColors.success;
    final hasDescription =
        a.description != null && a.description!.isNotEmpty;
    final bookings = widget.bookings;
    final typeLabel = a.isMembership
        ? 'Membership'
        : a.isFullDay
        ? 'Full Day'
        : 'Hourly Slot';

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Stack(
        children: [
          Column(
            children: [
              AppPageHeader(
                icon: Icons.calendar_today_outlined,
                title: 'Amenity',
                accentColor: ModuleColors.amenities,
                subtitle: typeLabel,
              ),

              // Sits outside the scroll view so the gap under the fixed header
              // survives scrolling instead of collapsing with the content.
              const SizedBox(height: 14),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    bottomPad + (canManage ? 116 : 40),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Info card ──────────────────────────────────────────
                      _card(
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (a.imageUrl != null &&
                                a.imageUrl!.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  a.imageUrl!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  // A broken image URL shouldn't leave a torn
                                  // box in the middle of the card.
                                  errorBuilder: (_, _, _) => Container(
                                    height: 150,
                                    color: AppColors.primary.withValues(
                                      alpha: 0.08,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.sports_soccer_rounded,
                                      color: AppColors.primary,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    a.name,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: priceColor.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: priceColor.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPaid
                                            ? Icons.payments_outlined
                                            : Icons.card_giftcard_rounded,
                                        size: 13,
                                        color: priceColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isPaid ? 'Paid' : 'Free',
                                        style: TextStyle(
                                          color: priceColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),

                            _infoRow(
                              icon: a.isMembership
                                  ? Icons.card_membership_rounded
                                  : a.isFullDay
                                  ? Icons.event_available_rounded
                                  : Icons.access_time_rounded,
                              color: AppColors.accentIndigo,
                              label: 'Booking Type',
                              value: typeLabel,
                            ),
                            const SizedBox(height: 12),

                            _infoRow(
                              icon: Icons.schedule_rounded,
                              color: const Color(0xFF00897B),
                              label: 'Availability',
                              // A full-day amenity has no fixed hours — the
                              // resident picks whole days or a few hours. A
                              // membership one is used any time it's open.
                              value: a.isMembership
                                  ? (membershipHoursLabel(a) ??
                                        'Any time · members only')
                                  : a.isFullDay
                                  ? 'Whole day or selected hours'
                                  : '${a.startTime ?? '--'} - ${a.endTime ?? '--'}',
                            ),

                            if (a.isMembership) ...[
                              const SizedBox(height: 12),
                              _infoRow(
                                icon: Icons.groups_rounded,
                                color: AppColors.accentBlue,
                                label: 'Active Members',
                                value: a.maxMembers != null
                                    ? '${a.activeMembers} of ${a.maxMembers}'
                                    : '${a.activeMembers} · no limit',
                              ),
                              for (final p in a.plans) ...[
                                const SizedBox(height: 12),
                                _infoRow(
                                  icon: Icons.card_membership_rounded,
                                  color: AppColors.accentAmber,
                                  label: '${p.name} · ${p.durationLabel}',
                                  value: isPaid
                                      ? membershipMoney(p.price)
                                      : 'Free for residents',
                                ),
                              ],
                            ] else if (isPaid) ...[
                              if (a.isFullDay) ...[
                                const SizedBox(height: 12),
                                _infoRow(
                                  icon: Icons.currency_rupee_rounded,
                                  color: AppColors.accentAmber,
                                  label: 'Price Per Day',
                                  value: _money(a.pricePerDay),
                                ),
                              ],
                              const SizedBox(height: 12),
                              _infoRow(
                                icon: Icons.currency_rupee_rounded,
                                color: AppColors.accentAmber,
                                label: a.isFullDay
                                    ? 'Price Per Hour (partial-day)'
                                    : 'Price Per Hour',
                                value: _money(a.pricePerHour),
                              ),
                            ] else ...[
                              const SizedBox(height: 12),
                              _infoRow(
                                icon: Icons.card_giftcard_rounded,
                                color: AppColors.success,
                                label: 'Pricing',
                                value: 'Free for residents',
                              ),
                            ],
                          ],
                        ),
                      ),

                      // ── Description card ───────────────────────────────────
                      if (hasDescription) ...[
                        const SizedBox(height: 16),
                        _card(
                          padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: ModuleColors.amenities,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'About this Amenity',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                a.description!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 15.5,
                                  height: 1.85,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Bookings list ──────────────────────────────────────
                      if (bookings.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _card(
                          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: AppColors.accentAmber,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    a.isMembership
                                        ? 'Memberships (${bookings.length})'
                                        : 'Bookings (${bookings.length})',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...bookings.map(_bookingRow),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Floating delete ───────────────────────────────────────────────
          if (canManage) ...[
            // Fade so content scrolling underneath doesn't collide with the
            // button. Ignores pointers — the scroll view keeps the gestures.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: bottomPad + 104,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.cardBackground.withValues(alpha: 0),
                        AppColors.cardBackground.withValues(alpha: 0.9),
                        AppColors.cardBackground,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomPad + 16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentRed.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _deleting ? null : _confirmDelete,
                    icon: _deleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.delete_outline, size: 20),
                    label: Text(_deleting ? 'Deleting…' : 'Delete Amenity'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentRed,
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor: AppColors.accentRed.withValues(
                        alpha: 0.6,
                      ),
                      disabledForegroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bookingRow(Booking b) {
    final when = b.isMembership
        ? '${b.planName ?? 'Membership'} · ${membershipPeriodLabel(b)}'
        : b.isFullDay
        ? (b.endDate != null && b.endDate != b.date
              ? '${b.date} to ${b.endDate}'
              : b.date)
        : '${b.date} (${b.startTime} - ${b.endTime})';
    // Memberships read Active / Upcoming / Expired, not just Approved.
    final state = b.isMembership ? membershipStateOf(b) : null;
    final pillLabel = state != null
        ? membershipStateLabel(state)
        : _statusLabel(b.status);
    final pillColor = state != null
        ? membershipStateColor(state)
        : _statusColor(b.status);
    final pillBg = state != null
        ? membershipStateBg(state)
        : _statusBgColor(b.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.accentAmber.withValues(alpha: 0.12),
            child: Text(
              (b.userName?.isNotEmpty == true)
                  ? b.userName![0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppColors.accentAmber,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.userName ?? 'Unknown',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  when,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  pillLabel,
                  style: TextStyle(
                    color: pillColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (b.amount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  _money(b.amount),
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
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

  Widget _infoRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
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
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
