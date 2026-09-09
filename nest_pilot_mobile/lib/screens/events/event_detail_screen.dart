import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/modules.dart';
import '../../config/roles.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../services/permission_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_page_header.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  /// Called after an RSVP so the list can refetch — the attendee count has
  /// moved and a card's FULL chip may have flipped. Mirrors the `onCreated`
  /// hook the create sheet uses; delete still reports itself via `pop(true)`.
  final VoidCallback? onChanged;

  const EventDetailScreen({super.key, required this.event, this.onChanged});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventService _service = EventService();

  /// Starts as the row the list handed over, then gets replaced by a refetch
  /// after an RSVP so the attendee list and count come from the server rather
  /// than a local guess.
  late EventModel _event = widget.event;
  bool _deleting = false;
  bool _rsvpBusy = false;

  // ── RSVP ───────────────────────────────────────────────────────────────────

  /// The session stores the id as a String; attendees key off an int.
  int? get _myUserId => int.tryParse(SessionService().currentUser?.id ?? '');

  bool get _isGoing {
    final id = _myUserId;
    return id != null && _event.isRegistered(id);
  }

  /// Members only — secretaries and guards manage events rather than attend
  /// them. Nothing to answer once the event is over either, and an unknown
  /// user can't be matched against the attendee list.
  bool get _canRsvp =>
      SessionService().currentUser?.role == UserRoles.member &&
      _myUserId != null &&
      _event.phase() != EventPhase.over;

  /// Registers or cancels. Tapping the option that's already selected is a
  /// no-op, which also keeps a never-registered member's "Not going" tap from
  /// firing a DELETE the backend would 404 on.
  Future<void> _setGoing(bool going) async {
    if (_rsvpBusy || going == _isGoing) return;

    setState(() => _rsvpBusy = true);
    try {
      final id = _event.id.toString();
      if (going) {
        await _service.registerForEvent(id);
      } else {
        await _service.cancelRegistration(id);
      }
      final fresh = await _service.getEventDetail(id);
      if (!mounted) return;
      setState(() => _event = fresh);
      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      // Capacity is raced on the server ("Event is fully booked"), so surface
      // whatever it says rather than assuming the tap succeeded.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _rsvpBusy = false);
    }
  }

  /// Deletes the event and pops `true` so the list knows to refetch.
  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                color: AppColors.accentRed,
                child: const Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: AppColors.white,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Delete Event',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Delete "${_event.title}"? This cannot be undone.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: const Text(
                          'Keep',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentRed,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm != true) return;

    setState(() => _deleting = true);
    try {
      await _service.deleteEvent(_event.id.toString());
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

  Color get _typeColor {
    switch (_event.eventType) {
      case 'MEETING':
        return AppColors.accentBlue;
      case 'SOCIAL':
        return AppColors.accentPurple;
      case 'CULTURAL':
        return AppColors.accentPink;
      case 'SPORTS':
        return AppColors.accentGreen;
      case 'MAINTENANCE':
        return AppColors.accentAmber;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    final canDelete = PermissionService().canManage(ModuleCodes.events);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final date = DateFormat('EEE, dd MMM yyyy').format(event.eventDate);
    final timeRange = event.endTime != null
        ? '${event.startTime} – ${event.endTime}'
        : event.startTime;
    final hasDescription =
        event.description != null && event.description!.isNotEmpty;
    final authorName = event.createdByName;
    final authorInitial = (authorName != null && authorName.isNotEmpty)
        ? authorName[0].toUpperCase()
        : 'A';
    final typeColor = _typeColor;
    final registeredCount = event.attendeeCount;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Stack(
        children: [
          Column(
            children: [
              AppPageHeader(
                icon: Icons.event_outlined,
                title: 'Event',
                accentColor: ModuleColors.events,
                subtitle: event.eventType,
              ),

              // Sits outside the scroll view so the gap under the fixed header
              // survives scrolling instead of collapsing with the content.
              const SizedBox(height: 14),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad + (canDelete ? 116 : 40)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Info card ──────────────────────────────────────────
                      _card(
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: typeColor.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event_outlined,
                                    size: 13,
                                    color: typeColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    event.eventType,
                                    style: TextStyle(
                                      color: typeColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Title
                            Text(
                              event.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                height: 1.3,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Date — 1 line
                            _infoRow(
                              icon: Icons.calendar_month_rounded,
                              color: AppColors.accentIndigo,
                              label: 'Date',
                              value: date,
                            ),
                            const SizedBox(height: 12),

                            // Time — 1 line
                            _infoRow(
                              icon: Icons.access_time_rounded,
                              color: const Color(0xFF00897B),
                              label: 'Time',
                              value: timeRange,
                            ),
                            const SizedBox(height: 12),

                            // Location — 1 line
                            _infoRow(
                              icon: Icons.location_on_outlined,
                              color: AppColors.accentPink,
                              label: 'Location',
                              value: event.location,
                            ),

                            // Attendees
                            if (event.maxAttendees != null) ...[
                              const SizedBox(height: 12),
                              _infoRow(
                                icon: Icons.people_outlined,
                                color: AppColors.accentAmber,
                                label: 'Registered',
                                value:
                                    '$registeredCount / ${event.maxAttendees} attendees',
                              ),
                            ],

                            // Author
                            if (authorName != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 13,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7FF),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.accentIndigo
                                          .withValues(alpha: 0.12),
                                      child: Text(
                                        authorInitial,
                                        style: const TextStyle(
                                          color: AppColors.accentIndigo,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 13),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Organized by',
                                          style: TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          authorName,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // ── RSVP ───────────────────────────────────────────────
                      if (_canRsvp) ...[
                        const SizedBox(height: 16),
                        _rsvpCard(),
                      ],

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
                                      color: typeColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'About this Event',
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
                                event.description!,
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

                      // ── Attendees list ─────────────────────────────────────
                      if (event.attendees.isNotEmpty) ...[
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
                                    'Attendees (${event.attendees.where((a) => a.status == 'REGISTERED').length})',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...event.attendees
                                  .where((a) => a.status == 'REGISTERED')
                                  .map(
                                    (a) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: AppColors.accentAmber
                                                .withValues(alpha: 0.12),
                                            child: Text(
                                              (a.userName?.isNotEmpty == true)
                                                  ? a.userName![0].toUpperCase()
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
                                            child: Text(
                                              a.userName ?? 'Unknown',
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (a.userMobile != null)
                                            Text(
                                              a.userMobile!,
                                              style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
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
          if (canDelete) ...[
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
                    label: Text(_deleting ? 'Deleting…' : 'Delete Event'),
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

  Widget _rsvpCard() {
    final going = _isGoing;
    // Already-registered members keep their slot; only newcomers are blocked.
    final full = _event.isFull && !going;

    return _card(
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
                  color: AppColors.accentGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Will you attend?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (_rsvpBusy)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accentGreen,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _rsvpOption(
                  label: 'Going',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.accentGreen,
                  selected: going,
                  onTap: full ? null : () => _setGoing(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _rsvpOption(
                  label: 'Not going',
                  icon: Icons.cancel_outlined,
                  color: AppColors.accentRed,
                  selected: !going,
                  onTap: () => _setGoing(false),
                ),
              ),
            ],
          ),
          if (full) ...[
            const SizedBox(height: 12),
            const Text(
              'This event is fully booked.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _rsvpOption({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: _rsvpBusy ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.4 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected ? color : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? color : AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: selected ? AppColors.white : color),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.white : color,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _card({
    required Widget child,
    EdgeInsets? padding,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? AppColors.border),
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
