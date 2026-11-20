import 'package:flutter_test/flutter_test.dart';
import 'package:pocket/domain/apply.dart';
import 'package:pocket/domain/commands.dart';
import 'package:pocket/domain/enums.dart';
import 'package:pocket/domain/records.dart';
import 'package:pocket/domain/seed.dart';

const _late = When(dayOffset: 0, hour: 13, minute: 0, seq: 30);

DiaryEntry _entry({EntryKind kind = EntryKind.general, String id = 'e-new'}) {
  return DiaryEntry(
    id: id,
    kind: kind,
    body: 'Is the cushion here?',
    authorName: 'Jordan',
    authorRole: Role.staff,
    when: _late,
    attachment: Attachment.none,
    voice: VoiceNote.none,
    question: kind == EntryKind.question ? QuestionState.open : null,
    fileIds: const [],
  );
}

Note _note(Thread thread, {String owner = 'Alex'}) {
  return Note(
    id: 'n-${thread.name}',
    thread: thread,
    source: MessageSource.person,
    author: owner,
    body: 'A long day.',
    when: _late,
    known: null,
    escalation: null,
    asked: null,
    owner: thread == Thread.guide ? owner : null,
  );
}

void main() {
  final seed = createSeed();

  group('entry.add', () {
    test('stores author and an open question, newest first, bumps tick', () {
      final next = apply(seed, EntryAdd(_entry(kind: EntryKind.question)));
      final first = next.entries.first;

      expect(first.id, 'e-new');
      expect(first.authorName, 'Jordan');
      expect(first.authorRole, Role.staff);
      expect(first.question, QuestionState.open);
      expect(next.entries.length, seed.entries.length + 1);
      expect(next.tick, 30);
    });

    test('does not change the input state', () {
      apply(seed, EntryAdd(_entry()));

      expect(seed.entries.length, 5);
    });
  });

  test('guide notes are not entries', () {
    final next = apply(
      seed,
      MessagesAdd([_note(Thread.guide), _note(Thread.guide)]),
    );

    expect(next.entries, seed.entries);
    expect(next.messages.length, seed.messages.length + 2);
    expect(next.messages.last.owner, 'Alex');
  });

  test('question.resolve resolves only that question', () {
    final next = apply(seed, const QuestionResolve('entry-cushion'));
    final cushion = next.entries.firstWhere((e) => e.id == 'entry-cushion');

    expect(cushion.question, QuestionState.resolved);
    expect(
      next.entries.where((e) => e.question == QuestionState.open),
      isEmpty,
    );
  });

  test('answer.save replaces one answer', () {
    final next = apply(seed, const AnswerSave('laugh', 'Puns.'));

    expect(next.prompts.firstWhere((p) => p.id == 'laugh').answer, 'Puns.');
    expect(
      next.prompts.firstWhere((p) => p.id == 'music').answer,
      seed.prompts[7].answer,
    );
  });

  test('observation.add appends to one card', () {
    final next = apply(
      seed,
      const ObservationAdd('leaving', 'Sam: Coat by the door helped.'),
    );

    expect(next.works.firstWhere((w) => w.id == 'leaving').observations, [
      'Sam: Coat by the door helped.',
    ]);
    expect(
      next.works.firstWhere((w) => w.id == 'phone-calls').observations.length,
      1,
    );
  });

  test('messages.add appends and bumps tick', () {
    final next = apply(seed, MessagesAdd([_note(Thread.care)]));

    expect(next.messages.last.id, 'n-care');
    expect(next.tick, 30);
  });

  test('message.sent marks the question sent and appends the note', () {
    final next = apply(
      seed,
      MessageSent('note-clothes-ai', _note(Thread.care)),
    );

    expect(
      next.messages.firstWhere((m) => m.id == 'note-clothes-ai').escalation,
      Escalation.sent,
    );
    expect(next.messages.last.id, 'n-care');
  });

  test('help.accept sets the acceptor only once', () {
    final once = apply(seed, const HelpAccept('help-visit', 'Chris'));
    final twice = apply(once, const HelpAccept('help-visit', 'Alex'));
    final taken = apply(seed, const HelpAccept('help-script', 'Alex'));

    expect(
      twice.requests.firstWhere((r) => r.id == 'help-visit').acceptedBy,
      'Chris',
    );
    expect(
      taken.requests.firstWhere((r) => r.id == 'help-script').acceptedBy,
      'Chris',
    );
  });

  test('help.post puts the request first', () {
    const request = HelpRequest(
      id: 'help-new',
      kind: RequestKind.appointment,
      text: 'Can someone take Mum to her appointment?',
      acceptedBy: null,
      appointmentId: 'appt-gp',
    );
    final next = apply(seed, const HelpPost(request));

    expect(next.requests.first.id, 'help-new');
    expect(next.requests.first.appointmentId, 'appt-gp');
  });

  test('reminder.set turns one reminder off', () {
    final next = apply(seed, const ReminderSet('appt-gp', Reminder.off));

    expect(
      next.appointments.firstWhere((a) => a.id == 'appt-gp').reminder,
      Reminder.off,
    );
  });

  test('volunteer.set fills an empty volunteer only', () {
    final gp = apply(seed, const VolunteerSet('appt-gp', 'Chris'));
    final hair = apply(seed, const VolunteerSet('appt-hair', 'Alex'));

    expect(
      gp.appointments.firstWhere((a) => a.id == 'appt-gp').volunteer,
      'Chris',
    );
    expect(
      hair.appointments.firstWhere((a) => a.id == 'appt-hair').volunteer,
      'Chris',
    );
  });

  test('handover.set replaces the text and records the source', () {
    final next = apply(
      seed,
      const HandoverSet('She had tea.', HandoverBy.ai()),
    );

    expect(next.handover, 'She had tea.');
    expect(next.handoverBy.source, HandoverSource.ai);
    expect(next.handoverBy.name, isNull);
  });

  test('access.set revokes and restores', () {
    final off = apply(seed, const AccessSet(AccessState.revoked));
    final on = apply(off, const AccessSet(AccessState.active));

    expect(off.access, AccessState.revoked);
    expect(on.access, AccessState.active);
  });

  test('report.add puts the report first and bumps tick', () {
    const report = Report(
      id: 'report-new',
      when: _late,
      author: 'Alex',
      title: 'Physio',
      note: '',
      original: 'Walked well.',
      summary: 'Walked well.',
      fileId: null,
    );
    final next = apply(seed, const ReportAdd(report));

    expect(next.reports.first.id, 'report-new');
    expect(next.tick, 30);
  });

  test('member.set changes a family login only', () {
    final chris = apply(seed, const MemberSet('Chris', AccessState.revoked));
    final jordan = apply(seed, const MemberSet('Jordan', AccessState.revoked));

    expect(
      chris.people.firstWhere((p) => p.name == 'Chris').access,
      AccessState.revoked,
    );
    expect(
      jordan.people.firstWhere((p) => p.name == 'Jordan').access,
      AccessState.active,
    );
  });

  test('entry.edit replaces the body only', () {
    final next = apply(seed, const EntryEdit('entry-phone', 'Edited.'));
    final before = seed.entries.firstWhere((e) => e.id == 'entry-phone');
    final after = next.entries.firstWhere((e) => e.id == 'entry-phone');

    expect(after.body, 'Edited.');
    expect(after.kind, before.kind);
    expect(after.authorName, before.authorName);
    expect(after.when.seq, before.when.seq);
  });

  test('entry.remove drops that entry', () {
    final next = apply(seed, const EntryRemove('entry-phone'));

    expect(next.entries.any((e) => e.id == 'entry-phone'), isFalse);
    expect(next.entries.length, 4);
  });

  test('request.remove drops that request', () {
    final next = apply(seed, const RequestRemove('help-visit'));

    expect(next.requests.any((r) => r.id == 'help-visit'), isFalse);
  });

  test('appointment.add appends', () {
    const appointment = Appointment(
      id: 'appt-new',
      when: _late,
      place: 'Hills Medical',
      reason: 'GP',
      transport: '',
      notes: '',
      reminder: Reminder.off,
      volunteer: null,
    );
    final next = apply(seed, const AppointmentAdd(appointment));

    expect(next.appointments.last.id, 'appt-new');
  });

  test('onboarding.set and story.dismiss store their values', () {
    final pending = apply(seed, const OnboardingSet(Onboarding.pending));
    final dismissed = apply(seed, const StoryDismiss(3));

    expect(pending.onboarded, Onboarding.pending);
    expect(dismissed.storyDismissed, 3);
  });
}
