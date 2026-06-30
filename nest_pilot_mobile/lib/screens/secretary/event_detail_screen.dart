import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_page_header.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event;
  const EventDetailScreen({super.key, required this.event});

  Color get _typeColor {
    switch (event.eventType) {
      case 'MEETING':     return AppColors.accentBlue;
      case 'SOCIAL':      return AppColors.accentPurple;
      case 'CULTURAL':    return AppColors.accentPink;
      case 'SPORTS':      return AppColors.accentGreen;
      case 'MAINTENANCE': return AppColors.accentAmber;
      default:            return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final date = DateFormat('EEE, dd MMM yyyy').format(event.eventDate);
    final timeRange = event.endTime != null
        ? '${event.startTime} – ${event.endTime}'
        : event.startTime;
    final hasDescription = event.description != null && event.description!.isNotEmpty;
    final authorName = event.createdByName;
    final authorInitial = (authorName != null && authorName.isNotEmpty)
        ? authorName[0].toUpperCase()
        : 'A';
    final typeColor = _typeColor;
    final registeredCount = event.attendeeCount;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppPageHeader(
              icon: const Icon(Icons.event_outlined, color: AppColors.white, size: 28),
              title: 'Event',
              subtitle: event.eventType,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 22, 16, bottomPad + 40),
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
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: typeColor.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_outlined, size: 13, color: typeColor),
                              const SizedBox(width: 6),
                              Text(
                                event.eventType,
                                style: TextStyle(color: typeColor, fontSize: 12, fontWeight: FontWeight.w700),
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
                            value: '$registeredCount / ${event.maxAttendees} attendees',
                          ),
                        ],

                        // Author
                        if (authorName != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.accentIndigo.withValues(alpha: 0.12),
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
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      authorName,
                                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w800),
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
                              .map((a) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: AppColors.accentAmber.withValues(alpha: 0.12),
                                          child: Text(
                                            (a.userName?.isNotEmpty == true) ? a.userName![0].toUpperCase() : '?',
                                            style: const TextStyle(color: AppColors.accentAmber, fontSize: 12, fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            a.userName ?? 'Unknown',
                                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        if (a.userMobile != null)
                                          Text(a.userMobile!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                      ],
                                    ),
                                  )),
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
              Text(label, style: TextStyle(color: color.withValues(alpha: 0.75), fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding, Color? borderColor}) {
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
