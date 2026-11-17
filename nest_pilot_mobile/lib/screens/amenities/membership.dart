import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nest_pilot_mobile/models/community_models.dart';
import 'package:nest_pilot_mobile/services/community_service.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_field_card.dart';
import '../../widgets/app_form_sheet.dart';
import '../../widgets/glare_button.dart';

// Shared pieces for MEMBERSHIP amenities (gym, pool…): how a membership
// booking reads today, and the Join / Renew sheet residents buy one from.

/// Where a membership stands today.
enum MembershipState {
  pending,
  scheduled,
  active,
  expired,
  rejected,
  cancelled,
}

DateTime _today() => DateUtils.dateOnly(DateTime.now());

DateTime? _parse(String? value) =>
    value == null ? null : DateTime.tryParse(value);

/// Days from [a] to [b], counted in UTC so a DST shift can't skew it.
int _daysBetween(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

MembershipState membershipStateOf(Booking b) {
  if (b.status == 'REJECTED') return MembershipState.rejected;
  if (b.status == 'CANCELLED') return MembershipState.cancelled;
  final today = _today();
  final start = _parse(b.date);
  final end = _parse(b.endDate ?? b.date);
  if (end != null && end.isBefore(today)) return MembershipState.expired;
  if (b.status == 'PENDING') return MembershipState.pending;
  if (start != null && start.isAfter(today)) return MembershipState.scheduled;
  return MembershipState.active;
}

/// Still to come or running (pending counts — it holds the dates).
bool isLiveMembership(Booking b) {
  final s = membershipStateOf(b);
  return s == MembershipState.pending ||
      s == MembershipState.scheduled ||
      s == MembershipState.active;
}

/// Days left including today (an active membership ending today has 1).
int membershipDaysLeft(Booking b) {
  final end = _parse(b.endDate ?? b.date);
  return end == null ? 0 : _daysBetween(_today(), end) + 1;
}

/// Share of the membership already used, 0–1 (for the progress bar).
double membershipProgress(Booking b) {
  final start = _parse(b.date);
  final end = _parse(b.endDate ?? b.date);
  if (start == null || end == null) return 0;
  final total = _daysBetween(start, end) + 1;
  final used = _daysBetween(start, _today());
  return (used / total).clamp(0.0, 1.0);
}

/// The resident's latest still-running membership of [amenityId], if any —
/// a renewal starts the day after it ends.
Booking? latestLiveMembership(int amenityId, Iterable<Booking> bookings) {
  Booking? latest;
  for (final b in bookings) {
    if (!b.isMembership || b.amenityId != amenityId) continue;
    if (!isLiveMembership(b)) continue;
    if (latest == null ||
        (b.endDate ?? b.date).compareTo(latest.endDate ?? latest.date) > 0) {
      latest = b;
    }
  }
  return latest;
}

/// "16 Nov – 15 Dec 2026", or with both years when they differ.
String membershipPeriodLabel(Booking b) {
  final start = _parse(b.date);
  final end = _parse(b.endDate ?? b.date);
  if (start == null || end == null) return b.date;
  return periodLabel(start, end);
}

String periodLabel(DateTime start, DateTime end) {
  final full = DateFormat('d MMM yyyy');
  if (start.year == end.year) {
    return '${DateFormat('d MMM').format(start)} – ${full.format(end)}';
  }
  return '${full.format(start)} – ${full.format(end)}';
}

String membershipStateLabel(MembershipState s) => switch (s) {
  MembershipState.pending => 'Pending',
  MembershipState.scheduled => 'Upcoming',
  MembershipState.active => 'Active',
  MembershipState.expired => 'Expired',
  MembershipState.rejected => 'Rejected',
  MembershipState.cancelled => 'Cancelled',
};

Color membershipStateColor(MembershipState s) => switch (s) {
  MembershipState.pending => AppColors.warning,
  MembershipState.scheduled => AppColors.accentBlue,
  MembershipState.active => AppColors.success,
  MembershipState.expired => AppColors.textMuted,
  MembershipState.rejected || MembershipState.cancelled => AppColors.accentRed,
};

Color membershipStateBg(MembershipState s) => switch (s) {
  MembershipState.pending => AppColors.accentOrange.withValues(alpha: 0.12),
  MembershipState.scheduled => AppColors.accentBlue.withValues(alpha: 0.12),
  MembershipState.active => AppColors.accentGreen.withValues(alpha: 0.12),
  MembershipState.expired => AppColors.border.withValues(alpha: 0.6),
  MembershipState.rejected ||
  MembershipState.cancelled => AppColors.accentRed.withValues(alpha: 0.12),
};

/// Prices come back as doubles — drop the ".00" tail on whole rupees.
String membershipMoney(double value) => value == value.roundToDouble()
    ? '₹${NumberFormat('#,##,##0', 'en_IN').format(value)}'
    : '₹${NumberFormat('#,##,##0.00', 'en_IN').format(value)}';

/// "From ₹500" for a paid membership amenity, "Free" otherwise.
String membershipPriceLabel(Amenity a) {
  if (!a.isPaid) return 'Free';
  final low = a.lowestPlanPrice;
  if (low == null) return 'Paid';
  return a.plans.length == 1
      ? '${membershipMoney(low)} / ${a.plans.first.durationLabel}'
      : 'From ${membershipMoney(low)}';
}

/// "Open 6:00 AM – 10:00 PM" from the amenity's display hours, or null.
String? membershipHoursLabel(Amenity a) {
  TimeOfDay? parse(String? v) {
    final parts = (v ?? '').split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    return h == null || m == null ? null : TimeOfDay(hour: h, minute: m);
  }

  final open = parse(a.startTime);
  final close = parse(a.endTime);
  if (open == null || close == null) return null;
  String fmt(TimeOfDay t) =>
      DateFormat('h:mm a').format(DateTime(2000, 1, 1, t.hour, t.minute));
  return 'Open ${fmt(open)} – ${fmt(close)}';
}

// ─── Join / Renew sheet ──────────────────────────────────────────────────────

/// Lets a resident pick a plan and start date, shows the exact validity and
/// price, and sends the request. Pops `true` once the server accepts.
/// [current] is their still-running membership — the new one is queued to
/// start the day after it ends.
Future<bool?> showMembershipSheet(
  BuildContext context, {
  required Amenity amenity,
  Booking? current,
}) {
  return showAppFormSheet<bool>(
    context: context,
    builder: (_) => _MembershipSheet(amenity: amenity, current: current),
  );
}

class _MembershipSheet extends StatefulWidget {
  final Amenity amenity;
  final Booking? current;

  const _MembershipSheet({required this.amenity, this.current});

  @override
  State<_MembershipSheet> createState() => _MembershipSheetState();
}

class _MembershipSheetState extends State<_MembershipSheet> {
  static final Color _ink = Color.lerp(
    ModuleColors.amenities,
    AppColors.black,
    0.3,
  )!;

  late AmenityPlan? _plan = widget.amenity.plans.isEmpty
      ? null
      : widget.amenity.plans.first;

  /// Earliest allowed start: today, or the day after the current one ends.
  late final DateTime _earliest = _computeEarliest();
  late DateTime _start = _earliest;

  bool _saving = false;
  String? _error;

  DateTime _computeEarliest() {
    final today = _today();
    final currentEnd = _parse(widget.current?.endDate);
    if (currentEnd == null) return today;
    final next = DateTime(
      currentEnd.year,
      currentEnd.month,
      currentEnd.day + 1,
    );
    return next.isAfter(today) ? next : today;
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: _earliest,
      lastDate: _today().add(const Duration(days: 730)),
      helpText: 'Membership starts on',
      builder: appPickerTheme,
    );
    if (picked != null) setState(() => _start = DateUtils.dateOnly(picked));
  }

  Future<void> _submit() async {
    final plan = _plan;
    if (plan == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await CommunityService().bookAmenity({
        'amenity_id': widget.amenity.id,
        'plan_id': plan.id,
        'date': DateFormat('yyyy-MM-dd').format(_start),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.amenity;
    final plan = _plan;
    final renewing = widget.current != null;
    final currentEnd = _parse(widget.current?.endDate);
    final hours = membershipHoursLabel(a);

    return AppFormSheet(
      accentColor: ModuleColors.amenities,
      icon: renewing ? Icons.autorenew_rounded : Icons.card_membership_rounded,
      title: renewing ? 'Renew ${a.name}' : 'Join ${a.name}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            AppSheetErrorBanner(_error!),
            const SizedBox(height: 14),
          ],
          if (renewing && currentEnd != null) ...[
            _note(
              icon: Icons.autorenew_rounded,
              color: AppColors.accentBlue,
              text:
                  'Your membership runs until '
                  '${DateFormat('d MMM yyyy').format(currentEnd)} — the new '
                  'one starts after it, so there is no gap.',
            ),
            const SizedBox(height: 18),
          ] else if (hours != null) ...[
            _note(
              icon: Icons.schedule_rounded,
              color: AppColors.accentBlue,
              text: '$hours · use it any time — no slot booking needed.',
            ),
            const SizedBox(height: 18),
          ],
          const AppSectionHeader('Choose a plan'),
          const SizedBox(height: 12),
          if (a.plans.isEmpty)
            _note(
              icon: Icons.info_outline_rounded,
              color: AppColors.accentOrange,
              text: 'No plans are available yet — please check back later.',
            )
          else
            for (final p in a.plans) ...[
              _planOption(p, selected: p.id == plan?.id),
              const SizedBox(height: 10),
            ],
          if (plan != null) ...[
            const SizedBox(height: 14),
            const AppSectionHeader('Start date'),
            const SizedBox(height: 12),
            AppPickerCard(
              icon: Icons.event_rounded,
              label: 'Starts On',
              value: DateFormat('EEE, d MMM yyyy').format(_start),
              hint: 'Pick a date',
              onTap: _pickStart,
            ),
            const SizedBox(height: 14),
            _summary(plan),
            const SizedBox(height: 14),
            a.isPaid
                ? _note(
                    icon: Icons.hourglass_top_rounded,
                    color: AppColors.accentAmber,
                    text:
                        'Your membership starts once the society admin '
                        'confirms your payment.',
                  )
                : _note(
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.accentGreen,
                    text: 'Free — your membership is active right away.',
                  ),
            const SizedBox(height: 24),
            GlarePrimaryButton(
              text: a.isPaid ? 'Request Membership' : 'Start Membership',
              isLoading: _saving,
              onPressed: _submit,
            ),
          ],
        ],
      ),
    );
  }

  Widget _planOption(AmenityPlan p, {required bool selected}) {
    final a = widget.amenity;
    final months = p.months;
    final perMonth = a.isPaid && months != null && months > 1
        ? ' · ${membershipMoney((p.price / months).roundToDouble())}/month'
        : '';

    return GestureDetector(
      onTap: () => setState(() => _plan = p),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        decoration: BoxDecoration(
          color: selected
              ? ModuleColors.amenities.withValues(alpha: 0.08)
              : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? ModuleColors.amenities : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? ModuleColors.amenities : AppColors.border,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: ModuleColors.amenities,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${p.durationLabel}$perMonth',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              a.isPaid ? membershipMoney(p.price) : 'Free',
              style: TextStyle(
                color: selected ? _ink : AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(AmenityPlan plan) {
    final end = plan.endDateFor(_start);
    final days = _daysBetween(_start, end) + 1;
    return Container(
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
            icon: Icons.date_range_rounded,
            color: AppColors.accentBlue,
            label: 'Valid',
            value: periodLabel(_start, end),
            hint: '$days ${days == 1 ? 'day' : 'days'} · ${plan.durationLabel}',
          ),
          const Divider(height: 1, color: AppColors.border),
          _summaryRow(
            icon: Icons.currency_rupee_rounded,
            color: AppColors.accentAmber,
            label: 'Amount',
            value: widget.amenity.isPaid ? membershipMoney(plan.price) : 'Free',
          ),
        ],
      ),
    );
  }

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
}
