import 'dart:math';

import 'records.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _idChars = 'abcdefghijklmnopqrstuvwxyz0123456789';
const _idSuffix = 4;
final _random = Random();

/// en_AU wording: "Today, 9:40 am", "Yesterday, 4:05 pm", "Tue 17 Nov, 10:30 am".
/// [today] is the local day the app was opened.
String formatWhen(When when, DateTime today) {
  final time = _clock(when.hour, when.minute);

  if (when.dayOffset == 0) {
    return 'Today, $time';
  }

  if (when.dayOffset == -1) {
    return 'Yesterday, $time';
  }

  final day = DateTime(today.year, today.month, today.day + when.dayOffset);

  return '${_weekdays[day.weekday - 1]} ${day.day} ${_months[day.month - 1]}, $time';
}

/// Today's header line: "Sunday 15 November".
String formatDay(DateTime day) {
  final weekday = _weekdayNames[day.weekday - 1];

  return '$weekday ${day.day} ${_monthNames[day.month - 1]}';
}

/// The time alone, "9:40 am", for meta lines that already imply the day.
String formatClock(When when) {
  return _clock(when.hour, when.minute);
}

/// Offset, then hour, then minute, then seq. Negative when [a] is earlier.
int compareWhen(When a, When b) {
  final keys = [
    a.dayOffset - b.dayOffset,
    a.hour - b.hour,
    a.minute - b.minute,
    a.seq - b.seq,
  ];

  return keys.firstWhere((delta) => delta != 0, orElse: () => 0);
}

/// Write order. Seeded "today" notes carry fixed times, so a note written at
/// 7 am is still the newest even though 11:15 sorts later by the clock.
int compareWritten(When a, When b) {
  return a.seq - b.seq;
}

/// Stamps [now] on today and takes the next seq, so two notes in the same
/// minute still sort. The returned tick is what the state must keep.
({int tick, When when}) stampNow(int tick, DateTime now) {
  final next = tick + 1;

  return (
    tick: next,
    when: When(dayOffset: 0, hour: now.hour, minute: now.minute, seq: next),
  );
}

/// e.g. `entry-21-k3z9`: the tick keeps ids ordered, the suffix keeps them unique.
String makeId(String prefix, int tick) {
  final suffix = List.generate(
    _idSuffix,
    (_) => _idChars[_random.nextInt(_idChars.length)],
  ).join();

  return '$prefix-$tick-$suffix';
}

String _clock(int hour, int minute) {
  final half = hour < 12 ? 'am' : 'pm';
  final twelve = hour % 12 == 0 ? 12 : hour % 12;

  return '$twelve:${minute.toString().padLeft(2, '0')} $half';
}
