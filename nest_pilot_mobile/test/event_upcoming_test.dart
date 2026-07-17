import 'package:flutter_test/flutter_test.dart';
import 'package:nest_pilot_mobile/models/event_model.dart';

EventModel ev(String date, String start, [String? end]) => EventModel(
      id: 1, societyId: 1, createdBy: 1, title: 't',
      eventDate: DateTime.parse(date), startTime: start, endTime: end,
      location: 'l', eventType: 'OTHER', isActive: true,
      createdAt: DateTime.parse('2026-07-16'),
    );

void main() {
  // "now" = today, 18:00
  final now = DateTime(2026, 7, 16, 18, 0);

  test('today, start already passed, no end -> NOT upcoming', () {
    expect(ev('2026-07-16', '09:00').isUpcoming(now), isFalse);
  });
  test('today, start later -> upcoming', () {
    expect(ev('2026-07-16', '20:00').isUpcoming(now), isTrue);
  });
  test('today, in progress (started, ends later) -> upcoming', () {
    expect(ev('2026-07-16', '17:00', '19:00').isUpcoming(now), isTrue);
  });
  test('today, already ended -> NOT upcoming', () {
    expect(ev('2026-07-16', '09:00', '10:30').isUpcoming(now), isFalse);
  });
  test('yesterday -> NOT upcoming', () {
    expect(ev('2026-07-15', '23:00').isUpcoming(now), isFalse);
  });
  test('tomorrow, early -> upcoming', () {
    expect(ev('2026-07-17', '08:00').isUpcoming(now), isTrue);
  });
  test('HH:mm:ss form parses', () {
    expect(ev('2026-07-16', '09:00:00').isUpcoming(now), isFalse);
    expect(ev('2026-07-16', '20:00:00').isUpcoming(now), isTrue);
  });
  test('unparseable time -> upcoming for rest of its day', () {
    expect(ev('2026-07-16', '').isUpcoming(now), isTrue);
    expect(ev('2026-07-15', 'garbage').isUpcoming(now), isFalse);
  });
  test('month rollover end-of-day fallback', () {
    expect(ev('2026-07-31', '').isUpcoming(DateTime(2026, 7, 31, 23, 59)), isTrue);
    expect(ev('2026-07-31', '').isUpcoming(DateTime(2026, 8, 1, 0, 1)), isFalse);
  });

  test('phase: in progress -> live', () {
    expect(ev('2026-07-16', '17:00', '19:00').phase(now), EventPhase.live);
  });
  test('phase: started exactly now -> live', () {
    expect(ev('2026-07-16', '18:00', '19:00').phase(now), EventPhase.live);
  });
  test('phase: already ended -> over', () {
    expect(ev('2026-07-16', '09:00', '10:30').phase(now), EventPhase.over);
  });
  test('phase: past day -> over', () {
    expect(ev('2026-07-15', '23:00').phase(now), EventPhase.over);
  });
  test('phase: no end time, start passed -> over', () {
    expect(ev('2026-07-16', '09:00').phase(now), EventPhase.over);
  });
  test('phase: later today -> today', () {
    expect(ev('2026-07-16', '20:00').phase(now), EventPhase.today);
  });
  test('phase: future day -> upcoming', () {
    expect(ev('2026-07-17', '08:00').phase(now), EventPhase.upcoming);
  });
  test('phase: unparseable time today -> today, not live', () {
    expect(ev('2026-07-16', '').phase(now), EventPhase.today);
  });

  // ── Display order ──────────────────────────────────────────────────────────

  EventModel titled(String title, String date, String start, [String? end]) =>
      EventModel(
        id: 1, societyId: 1, createdBy: 1, title: title,
        eventDate: DateTime.parse(date), startTime: start, endTime: end,
        location: 'l', eventType: 'OTHER', isActive: true,
        createdAt: DateTime.parse('2026-07-16'),
      );

  List<String> order(List<EventModel> events) =>
      eventsInDisplayOrder(events, now).map((e) => e.title).toList();

  test('past events sink below active ones', () {
    expect(
      order([
        titled('old', '2026-07-01', '10:00'),
        titled('tomorrow', '2026-07-17', '08:00'),
        titled('yesterday', '2026-07-15', '10:00'),
        titled('later today', '2026-07-16', '20:00'),
      ]),
      ['later today', 'tomorrow', 'yesterday', 'old'],
    );
  });

  test('active run soonest-first, past run most-recent-first', () {
    expect(
      order([
        titled('old', '2026-07-01', '10:00'),
        titled('next week', '2026-07-23', '09:00'),
        titled('yesterday', '2026-07-15', '10:00'),
        titled('tomorrow', '2026-07-17', '08:00'),
      ]),
      ['tomorrow', 'next week', 'yesterday', 'old'],
    );
  });

  test('live event leads the active group', () {
    expect(
      order([
        titled('tomorrow', '2026-07-17', '08:00'),
        titled('later today', '2026-07-16', '20:00'),
        titled('live', '2026-07-16', '17:00', '19:00'),
      ]),
      ['live', 'later today', 'tomorrow'],
    );
  });

  test('same day ordered by start time', () {
    expect(
      order([
        titled('evening', '2026-07-17', '20:00'),
        titled('morning', '2026-07-17', '08:00'),
      ]),
      ['morning', 'evening'],
    );
  });

  test('unparseable start time falls back to its day', () {
    expect(
      order([
        titled('tomorrow', '2026-07-17', '08:00'),
        titled('today garbage', '2026-07-16', ''),
      ]),
      ['today garbage', 'tomorrow'],
    );
  });

  test('empty list', () {
    expect(order([]), isEmpty);
  });

  // ── Parsing ────────────────────────────────────────────────────────────────

  // The API's attendee include selects only ['id', 'user_id', 'status'], so
  // event_id never arrives. This is the exact payload shape the events list
  // returns once an event has a registration.
  test('parses an attendee payload that omits event_id', () {
    final event = EventModel.fromJson({
      'id': 1,
      'society_id': 1,
      'created_by': 1,
      'title': 'AGM',
      'event_date': '2026-07-20',
      'start_time': '18:00',
      'location': 'Hall',
      'event_type': 'MEETING',
      'is_active': true,
      'created_at': '2026-07-16T00:00:00.000Z',
      'attendees': [
        {
          'id': 7,
          'user_id': 42,
          'status': 'REGISTERED',
          'user': {'id': 42, 'full_name': 'Asha', 'mobile': '99999'},
        },
      ],
    });

    expect(event.attendees.single.userId, 42);
    expect(event.attendeeCount, 1);
    expect(event.isRegistered(42), isTrue);
    expect(event.isRegistered(43), isFalse);
  });
}
