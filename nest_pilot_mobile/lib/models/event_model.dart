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

  bool isRegistered(int userId) =>
      attendees.any((a) => a.userId == userId && a.status == 'REGISTERED');
}

class EventAttendee {
  final int id;
  final int eventId;
  final int userId;
  final String status;
  final String? userName;
  final String? userMobile;

  EventAttendee({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    this.userName,
    this.userMobile,
  });

  factory EventAttendee.fromJson(Map<String, dynamic> json) {
    return EventAttendee(
      id: (json['id'] as num).toInt(),
      eventId: (json['event_id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      status: json['status'] ?? 'REGISTERED',
      userName: json['user'] != null ? json['user']['full_name'] as String? : null,
      userMobile: json['user'] != null ? json['user']['mobile'] as String? : null,
    );
  }
}
