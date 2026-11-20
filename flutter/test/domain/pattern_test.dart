import 'package:flutter_test/flutter_test.dart';
import 'package:pocket/domain/pattern.dart';
import 'package:pocket/domain/records.dart';
import 'package:pocket/domain/seed.dart';

final _word = RegExp(r"[A-Za-z']+");

Set<String> _words(String text) {
  return _word.allMatches(text).map((m) => m.group(0)!.toLowerCase()).toSet();
}

WorkCard _card(PocketState state, String id) {
  return state.works.firstWhere((w) => w.id == id);
}

void main() {
  final seed = createSeed();

  test('phone calls: the situation, then a line copied from the notes', () {
    final card = _card(seed, 'phone-calls');
    final text = suggestPattern(card, seed.entries);
    final sources = [
      card.situation,
      card.helps,
      card.hinders,
      ...card.observations,
      for (final e in seed.entries) e.body,
    ];

    expect(text, startsWith(card.situation));
    expect(
      sources.any((s) => s.contains(text.substring(card.situation.length + 1))),
      isTrue,
    );
    expect(_words(text).difference(_words(sources.join(' '))), isEmpty);
  });

  test('leaving: one note or none is no pattern yet', () {
    expect(suggestPattern(_card(seed, 'leaving'), seed.entries), noPattern);
  });

  test('two observations on one card make a pattern', () {
    final card = _card(seed, 'leaving').copyWith(
      observations: [
        'Sam: Coat by the door helped.',
        'Chris: Saying "GP at ten" once was enough.',
      ],
    );

    expect(
      suggestPattern(card, const []),
      '${card.situation} Chris: Saying "GP at ten" once was enough.',
    );
  });

  test('the stored lines are not rewritten', () {
    final card = _card(seed, 'phone-calls');
    final before = [...card.observations];

    suggestPattern(card, seed.entries);

    expect(card.observations, before);
  });
}
