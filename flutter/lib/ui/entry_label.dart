import '../domain/enums.dart';

/// How an entry kind reads, in the brief's order, e.g. "A lovely moment".
String entryLabel(EntryKind kind) {
  return switch (kind) {
    EntryKind.general => 'General update',
    EntryKind.mood => 'Mood or behaviour',
    EntryKind.important => 'Something important',
    EntryKind.question => 'Question or concern',
    EntryKind.moment => 'A lovely moment',
  };
}
