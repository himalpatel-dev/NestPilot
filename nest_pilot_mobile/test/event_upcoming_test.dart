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
}
