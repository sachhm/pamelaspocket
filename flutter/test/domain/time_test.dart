import 'package:flutter_test/flutter_test.dart';
import 'package:pocket/domain/records.dart';
import 'package:pocket/domain/time.dart';

void main() {
  final sunday = DateTime(2026, 11, 15, 10, 42);

  test('formats today, yesterday, and other days in en_AU', () {
    expect(
      formatWhen(const When(dayOffset: 0, hour: 9, minute: 40, seq: 1), sunday),
      'Today, 9:40 am',
    );
    expect(
      formatWhen(
        const When(dayOffset: -1, hour: 16, minute: 5, seq: 1),
        sunday,
      ),
      'Yesterday, 4:05 pm',
    );
    expect(
      formatWhen(const When(dayOffset: 2, hour: 0, minute: 0, seq: 1), sunday),
      'Tue 17 Nov, 12:00 am',
    );
    expect(
      formatWhen(
        const When(dayOffset: 3, hour: 12, minute: 30, seq: 1),
        sunday,
      ),
      'Wed 18 Nov, 12:30 pm',
    );
  });

  test('compares by offset, hour, minute, then seq', () {
    const a = When(dayOffset: -1, hour: 23, minute: 59, seq: 9);
    const b = When(dayOffset: 0, hour: 8, minute: 0, seq: 1);
    const c = When(dayOffset: 0, hour: 8, minute: 0, seq: 2);

    expect(compareWhen(a, b), lessThan(0));
    expect(compareWhen(b, c), lessThan(0));
    expect(compareWhen(c, c), 0);
  });

  test('stampNow reads the clock and takes the next seq', () {
    final stamp = stampNow(20, sunday);

    expect(stamp.tick, 21);
    expect(stamp.when.dayOffset, 0);
    expect(stamp.when.hour, 10);
    expect(stamp.when.minute, 42);
    expect(stamp.when.seq, 21);
  });

  test('formatDay spells the weekday and month', () {
    expect(formatDay(sunday), 'Sunday 15 November');
  });

  test('formatClock gives the time alone', () {
    expect(
      formatClock(const When(dayOffset: -3, hour: 21, minute: 7, seq: 1)),
      '9:07 pm',
    );
  });

  test('makeId starts with the prefix and tick', () {
    expect(makeId('entry', 21), startsWith('entry-21-'));
    expect(makeId('entry', 21), isNot(makeId('entry', 21)));
  });
}
