import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket/domain/codec.dart';
import 'package:pocket/domain/enums.dart';
import 'package:pocket/domain/records.dart';
import 'package:pocket/domain/seed.dart';

void main() {
  test('seed survives a JSON round trip', () {
    final seed = createSeed();
    final text = jsonEncode(encodeState(seed));
    final back = decodeState(jsonDecode(text) as Map<String, Object?>);

    expect(jsonEncode(encodeState(back)), text);
  });

  test('field names match the Expo models', () {
    final json = encodeState(createSeed());
    final entry = (json['entries']! as List).first as Map<String, Object?>;
    final note = (json['messages']! as List).first as Map<String, Object?>;

    expect(
      json.keys,
      containsAll(['tick', 'access', 'handover', 'nextVisit', 'familyStatus']),
    );
    expect(
      entry.keys,
      containsAll(['authorName', 'authorRole', 'fileIds', 'question']),
    );
    expect(entry['kind'], 'question');
    expect(entry['when'], {'dayOffset': 0, 'hour': 12, 'minute': 5, 'seq': 5});
    expect(note['thread'], 'care');
  });

  test('missing fileIds and fileId become empty list and null', () {
    final json = encodeState(createSeed());
    final entries = json['entries']! as List;
    final reports = json['reports']! as List;

    for (final e in entries) {
      (e as Map<String, Object?>).remove('fileIds');
    }
    for (final r in reports) {
      (r as Map<String, Object?>).remove('fileId');
    }

    final back = decodeState(json);

    expect(back.entries.every((e) => e.fileIds.isEmpty), isTrue);
    expect(back.reports.every((r) => r.fileId == null), isTrue);
  });

  test('an Expo-shaped save without rebuild fields still decodes', () {
    final json = encodeState(createSeed());

    for (final key in [
      'recipient',
      'handoverBy',
      'onboarded',
      'storyDismissed',
    ]) {
      json.remove(key);
    }

    final back = decodeState(json);

    expect(back.recipient.name, 'Pamela');
    expect(back.handoverBy.source, HandoverSource.person);
    expect(back.onboarded, Onboarding.done);
  });

  test('actor round trip, null stays null', () {
    const actor = Actor(role: Role.staff, name: 'Sam');
    final back = decodeActor(jsonDecode(jsonEncode(encodeActor(actor))));

    expect(back?.name, 'Sam');
    expect(back?.role, Role.staff);
    expect(decodeActor(null), isNull);
    expect(decodeActor({'role': 'ghost', 'name': 'X'}), isNull);
  });
}
