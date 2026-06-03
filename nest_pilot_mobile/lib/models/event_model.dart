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
