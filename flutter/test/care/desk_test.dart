import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket/adapters/local/local_auth.dart';
import 'package:pocket/adapters/local/local_files.dart';
import 'package:pocket/adapters/local/local_model.dart';
import 'package:pocket/adapters/local/local_records.dart';
import 'package:pocket/care/desk.dart';
import 'package:pocket/domain/auth.dart';
import 'package:pocket/domain/chat.dart';
import 'package:pocket/domain/commands.dart';
import 'package:pocket/domain/copy.dart';
import 'package:pocket/domain/enums.dart';
import 'package:pocket/domain/records.dart';
import 'package:pocket/ports/record_port.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records which command kinds the desk committed.
class _LogPort implements RecordPort {
  _LogPort(this._inner);

  final RecordPort _inner;
  final kinds = <String>[];

  @override
  Future<PocketState> load() => _inner.load();

  @override
  Future<PocketState> commit(CareCommand command) {
    kinds.add(switch (command) {
      EntryAdd() => 'entry.add',
      MessagesAdd() => 'messages.add',
      MessageSent() => 'message.sent',
      _ => command.runtimeType.toString(),
    });

    return _inner.commit(command);
  }
}

// Afternoon, so a new note is the newest of the seeded day.
final _afternoon = DateTime(2026, 11, 15, 14, 30);

NewEntry _note(String body, [EntryKind kind = EntryKind.general]) {
  return (
    kind: kind,
    body: body,
    attachment: Attachment.none,
    voice: VoiceNote.none,
    fileIds: const [],
  );
}

// A fresh desk over the same device storage stands in for a relaunch.
Future<CareDesk> _open() async {
  final prefs = await SharedPreferences.getInstance();

  return CareDesk(
    LocalAuth(prefs),
    LocalRecords(prefs),
    const LocalModel(),
    LocalFiles(PrefsShelf(prefs)),
    clock: () => _afternoon,
  );
}

Future<CareDesk> _as(Role role) async {
  final desk = await _open();
  await desk.load();

  if (role == Role.staff) {
    await desk.enterStaff(demoPin, 'Jordan');
  } else {
    await desk.signIn(role, emailFor(role), demoPassword);
  }

  return desk;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('first load writes the seed and nobody is signed in', () async {
    final desk = await _open();
    final held = await desk.load();
    final prefs = await SharedPreferences.getInstance();

    expect(held.actor, isNull);
    expect(held.state.recipient.name, 'Pamela');
    expect(prefs.getString(recordsKey), isNotNull);
  });

  test('signed-in actor survives a relaunch', () async {
    final desk = await _open();
    await desk.load();

    final outcome = await desk.signIn(Role.owner, ownerEmail, demoPassword);
    final reopened = await (await _open()).load();

    expect(outcome.result, SignInResult.ok);
    expect(reopened.actor?.name, 'Alex');
    expect(reopened.actor?.role, Role.owner);
  });

  test('rejected sign-in stores no actor', () async {
    final desk = await _open();
    await desk.load();

    final outcome = await desk.signIn(Role.owner, ownerEmail, 'wrong');

    expect(outcome.result, SignInResult.rejected);
    expect(outcome.actor, isNull);
    expect((await desk.load()).actor, isNull);
  });

  test('sign-up accepts only the demo accounts', () async {
    final desk = await _open();
    await desk.load();

    final demo = await desk.signUp(Role.family, familyEmail, demoPassword);
    final stranger = await desk.signUp(
      Role.family,
      'new@pocket.demo',
      demoPassword,
    );

    expect(demo.actor?.name, 'Chris');
    expect(stranger.result, SignInResult.rejected);
  });

  test('staff PIN stamps the picked name', () async {
    final desk = await _open();
    await desk.load();

    final outcome = await desk.enterStaff('2580', 'Sam');

    expect(outcome.result, PinResult.ok);
    expect(outcome.actor?.name, 'Sam');
    expect(outcome.actor?.role, Role.staff);
  });

  test('owner revokes access, then the PIN is turned off', () async {
    final desk = await _open();
    await desk.load();
    await desk.signIn(Role.owner, ownerEmail, demoPassword);

    final state = await desk.setAccess(AccessState.revoked);
    await desk.signOut();
    final outcome = await desk.enterStaff('2580', 'Jordan');

    expect(state?.access, AccessState.revoked);
    expect(outcome.result, PinResult.revoked);
    expect(outcome.actor, isNull);
  });

  test('staff cannot change access', () async {
    final desk = await _open();
    await desk.load();
    await desk.enterStaff('2580', 'Jordan');

    final state = await desk.setAccess(AccessState.revoked);

    expect(state, isNull);
    expect((await desk.load()).state.access, AccessState.active);
  });

  test('sign-out clears the actor and keeps the records', () async {
    final desk = await _open();
    await desk.load();
    await desk.signIn(Role.owner, ownerEmail, demoPassword);
    await desk.setAccess(AccessState.revoked);

    await desk.signOut();
    final reopened = await (await _open()).load();

    expect(reopened.actor, isNull);
    expect(reopened.state.access, AccessState.revoked);
    expect(reopened.state.entries.length, 5);
  });

  test('addEntry stamps the author and time; a question starts open', () async {
    final desk = await _as(Role.staff);

    final state = await desk.addEntry(
      _note('Is the heater on a timer?', EntryKind.question),
    );
    final entry = state!.entries.first;

    expect(entry.body, 'Is the heater on a timer?');
    expect(entry.authorName, 'Jordan');
    expect(entry.authorRole, Role.staff);
    expect(entry.when.hour, 14);
    expect(entry.when.minute, 30);
    expect(entry.question, QuestionState.open);
  });

  test('addEntry with nothing to save writes nothing', () async {
    final desk = await _as(Role.staff);

    expect(await desk.addEntry(_note('   ')), isNull);
    expect((await desk.load()).state.entries.length, 5);
  });

  test('handover refresh reads entries only and credits AI', () async {
    final desk = await _as(Role.owner);
    await desk.addEntry(_note('She had tea in the garden.'));

    final state = await desk.refreshHandover();
    final guide = state!.messages.where((note) => note.thread == Thread.guide);

    expect(state.handover, startsWith('She had tea in the garden.'));
    expect(state.handoverBy.source, HandoverSource.ai);
    expect(guide, isNotEmpty);
    for (final note in guide) {
      expect(state.handover, isNot(contains(note.body)));
    }
  });

  test('owner edits and removes; staff cannot', () async {
    final staff = await _as(Role.staff);
    expect(await staff.editEntry('entry-garden', 'Changed.'), isNull);
    expect(await staff.removeEntry('entry-garden'), isNull);
    await staff.signOut();

    final owner = await _as(Role.owner);
    final edited = await owner.editEntry('entry-garden', 'Changed.');
    final removed = await owner.removeEntry('entry-phone');

    expect(
      edited!.entries.firstWhere((e) => e.id == 'entry-garden').body,
      'Changed.',
    );
    expect(removed!.entries.map((e) => e.id), isNot(contains('entry-phone')));
  });

  test('only the owner resolves a question', () async {
    final family = await _as(Role.family);
    expect(await family.resolveQuestion('entry-cushion'), isNull);
    await family.signOut();

    final owner = await _as(Role.owner);
    final state = await owner.resolveQuestion('entry-cushion');

    expect(
      state!.entries.firstWhere((e) => e.id == 'entry-cushion').question,
      QuestionState.resolved,
    );
  });

  test('a stored photo reads back', () async {
    final desk = await _as(Role.staff);
    final bytes = Uint8List.fromList([9, 8, 7]);

    final stored = await desk.storeFile(FileKind.photo, 'Photo', bytes);

    expect(await desk.readFile(stored!.id), bytes);
  });

  test('household saves an answer with a photo; staff cannot', () async {
    final staff = await _as(Role.staff);
    expect(await staff.saveAnswer('laugh', 'Puns.', null), isNull);
    await staff.signOut();

    final family = await _as(Role.family);
    final state = await family.saveAnswer('work', '  Teacher.  ', 'photo-1');
    final work = state!.prompts.firstWhere((p) => p.id == 'work');

    expect(work.answer, 'Teacher.');
    expect(work.photoId, 'photo-1');
  });

  test('any role adds an observation, signed with their name', () async {
    final desk = await _as(Role.staff);

    final state = await desk.addObservation('leaving', ' Coat by the door. ');
    final card = state!.works.firstWhere((w) => w.id == 'leaving');

    expect(card.observations, ['Jordan: Coat by the door.']);
    expect(await desk.addObservation('leaving', '   '), isNull);
  });

  test('the suggestion quotes the card or says no pattern yet', () async {
    final desk = await _as(Role.staff);

    expect(
      await desk.suggestPattern('phone-calls'),
      startsWith('Becomes upset when someone uses their phone.'),
    );
    expect(await desk.suggestPattern('leaving'), 'No pattern yet.');
    expect(await desk.suggestPattern('missing'), isNull);
  });

  test('sendChat answers breakfast and marks unknown dose', () async {
    final desk = await _as(Role.staff);

    final breakfast = await desk.sendChat(
      'What does she usually have for breakfast?',
    );
    final dose = await desk.sendChat('What is her dose?');
    final ai = dose!.messages.where((n) => n.source == MessageSource.ai).last;

    expect(
      breakfast!.messages.where((n) => n.source == MessageSource.ai).last.body,
      contains('porridge'),
    );
    expect(ai.known, Known.no);
    expect(ai.escalation, Escalation.none);
  });

  test('staff can send an unknown answer to Alex or Chris', () async {
    final desk = await _as(Role.staff);
    await desk.sendChat('What is her dose?');
    final unknown = (await desk.load()).state.messages
        .where((n) => n.known == Known.no)
        .last;

    final toChris = await desk.sendToPerson(unknown.id, 'Chris');
    final sent = toChris!.messages.firstWhere((n) => n.id == unknown.id);

    expect(sent.escalation, Escalation.sent);
    expect(toChris.messages.last.body, 'Asked Chris: What is her dose?');
  });

  test('Chris does not see Alex’s guide notes', () async {
    final family = await _as(Role.family);
    final guide = (await family.load()).state.messages.where(
      (n) => n.thread == Thread.guide,
    );

    expect(guide, isEmpty);
  });

  test('sendGuide commits messages.add only', () async {
    final prefs = await SharedPreferences.getInstance();
    final inner = LocalRecords(prefs);
    final log = _LogPort(inner);
    final desk = CareDesk(
      LocalAuth(prefs),
      log,
      const LocalModel(),
      LocalFiles(PrefsShelf(prefs)),
      clock: () => _afternoon,
    );
    await desk.load();
    await desk.signIn(Role.owner, ownerEmail, demoPassword);

    await desk.sendGuide('A hard day');

    expect(log.kinds, ['messages.add']);
    expect(
      (await desk.load()).state.messages.where((n) => n.thread == Thread.guide),
      isNotEmpty,
    );
  });

  test('saveDraft adds one entry and keeps the guide notes', () async {
    final desk = await _as(Role.owner);
    await desk.sendGuide(guideHandover);
    final draft = (await desk.load()).state.messages.where(isDiaryDraft).single;
    final before = (await desk.load()).state.messages
        .where((n) => n.thread == Thread.guide)
        .length;

    final state = await desk.saveDraft(draft.id);

    expect(state!.entries.first.body, handoverDraft);
    expect(
      state.messages.where((n) => n.thread == Thread.guide).length,
      before,
    );
  });

  test('preview switches the actor without a password', () async {
    final desk = await _open();
    await desk.load();

    final actor = await desk.previewAs(Role.family);

    expect(actor.name, 'Chris');
    expect((await desk.load()).actor?.name, 'Chris');
  });
}
