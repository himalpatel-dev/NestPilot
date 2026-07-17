/// Where an event sits in its lifecycle, derived from the clock. There is no
/// cancelled phase: the backend has no status column, and `is_active: false`
/// is a soft delete the list query filters out, so a cancelled event never
/// reaches the app.
enum EventPhase { over, live, today, upcoming }

class EventModel {
  final int id;
  final int societyId;
  final int createdBy;
  final String title;
  final String? description;
  final DateTime eventDate;
  final String startTime;
  final String? endTime;
  final String location;
  final String eventType;
  final int? maxAttendees;
  final bool isActive;
  final DateTime createdAt;
  final String? createdByName;
  final List<EventAttendee> attendees;

  EventModel({
    required this.id,
    required this.societyId,
    required this.createdBy,
    required this.title,
    this.description,
    required this.eventDate,
    required this.startTime,
    this.endTime,
    required this.location,
    required this.eventType,
    this.maxAttendees,
    required this.isActive,
    required this.createdAt,
    this.createdByName,
    this.attendees = const [],
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: (json['id'] as num).toInt(),
      societyId: (json['society_id'] as num).toInt(),
      createdBy: (json['created_by'] as num).toInt(),
      title: json['title'] ?? '',
      description: json['description'],
      eventDate: DateTime.parse(json['event_date']),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'],
      location: json['location'] ?? '',
      eventType: json['event_type'] ?? 'OTHER',
      maxAttendees: json['max_attendees'] != null
          ? (json['max_attendees'] as num).toInt()
          : null,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(
        json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      createdByName: json['createdBy'] != null
          ? json['createdBy']['full_name'] as String?
          : null,
      attendees: (json['attendees'] as List? ?? [])
          .map((a) => EventAttendee.fromJson(a))
          .toList(),
    );
  }

  int get attendeeCount =>
      attendees.where((a) => a.status == 'REGISTERED').length;

  bool get isFull =>
      maxAttendees != null && attendeeCount >= maxAttendees!;

  // start_time / end_time are free-form strings on the backend. The app writes
  // 'HH:mm', so tolerate a stray 'HH:mm:ss' and give up on anything else.
  DateTime? _momentOf(String? time) {
    if (time == null) return null;
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      hour,
      minute,
    );
  }

  DateTime? get startsAt => _momentOf(startTime);

  DateTime? get endsAt => _momentOf(endTime);

  /// True until the event is over — past [endTime] when one was set, otherwise
  /// past [startTime]. An event whose time won't parse counts as upcoming for
  /// the rest of its day rather than vanishing from the count.
  bool isUpcoming([DateTime? asOf]) {
    final now = asOf ?? DateTime.now();
    final until = endsAt ?? startsAt;
    if (until != null) return until.isAfter(now);
    final endOfDay = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day + 1,
    );
    return endOfDay.isAfter(now);
  }

  bool isOn(DateTime day) =>
      eventDate.year == day.year &&
      eventDate.month == day.month &&
      eventDate.day == day.day;

  /// Lifecycle stage as of [asOf], following the same parsing rules as
  /// [isUpcoming]. An event only reads as [EventPhase.live] once a parsed
  /// [startTime] has passed while it is still upcoming — which in practice
  /// means it had an [endTime], since without one it is over at its start.
  EventPhase phase([DateTime? asOf]) {
    final now = asOf ?? DateTime.now();
    if (!isUpcoming(now)) return EventPhase.over;
    final start = startsAt;
    if (start != null && !start.isAfter(now)) return EventPhase.live;
    return isOn(now) ? EventPhase.today : EventPhase.upcoming;
  }

  bool isRegistered(int userId) =>
      attendees.any((a) => a.userId == userId && a.status == 'REGISTERED');
}

/// Events ordered for a list view: everything still live/today/upcoming first,
/// soonest first, with finished events sunk to the bottom, most recent first.
/// The API returns a plain ascending-by-date list, which floats long-finished
/// events above what is actually coming up.
List<EventModel> eventsInDisplayOrder(
  List<EventModel> events, [
  DateTime? asOf,
]) {
  final now = asOf ?? DateTime.now();
  final active = <EventModel>[];
  final over = <EventModel>[];
  for (final e in events) {
    (e.phase(now) == EventPhase.over ? over : active).add(e);
  }
  // Sorted here rather than leaning on the API's ordering, so the grouping
  // holds even if that ordering changes.
  active.sort((a, b) => _startKey(a).compareTo(_startKey(b)));
  over.sort((a, b) => _startKey(b).compareTo(_startKey(a)));
  return [...active, ...over];
}

/// Falls back to midnight on the event's day when [startTime] won't parse.
DateTime _startKey(EventModel e) => e.startsAt ?? e.eventDate;

class EventAttendee {
  final int id;
  final int userId;
  final String status;
  final String? userName;
  final String? userMobile;

  // No event_id: the API's attendee include selects only id/user_id/status,
  // and attendees only ever arrive nested under the event they belong to.
  EventAttendee({
    required this.id,
    required this.userId,
    required this.status,
    this.userName,
    this.userMobile,
  });

  factory EventAttendee.fromJson(Map<String, dynamic> json) {
    return EventAttendee(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      status: json['status'] ?? 'REGISTERED',
      userName: json['user'] != null ? json['user']['full_name'] as String? : null,
      userMobile: json['user'] != null ? json['user']['mobile'] as String? : null,
    );
  }
}
