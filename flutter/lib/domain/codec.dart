import 'commands.dart';
import 'enums.dart';
import 'records.dart';

/// Hand-written JSON for the household and the actor. Field names match the
/// Expo models. Fields the Expo app never wrote fall back to safe defaults,
/// e.g. a missing `fileIds` becomes `[]` and a missing `onboarded` is done.
typedef Json = Map<String, Object?>;

/// Diary entry for model / command payloads.
Json encodeEntry(DiaryEntry e) => _entry(e);

/// What Works card for `/v1/model/pattern`.
Json encodeWork(WorkCard w) => _work(w);

/// One command for `POST /v1/records/commands`.
Json encodeCommand(CareCommand command) {
  return switch (command) {
    EntryAdd(:final entry) => {'kind': 'entry.add', 'entry': _entry(entry)},
    QuestionResolve(:final id) => {'kind': 'question.resolve', 'id': id},
    AnswerSave(:final id, :final text, :final photoId) => {
      'kind': 'answer.save',
      'id': id,
      'text': text,
      'photoId': photoId,
    },
    ObservationAdd(:final worksId, :final line) => {
      'kind': 'observation.add',
      'worksId': worksId,
      'line': line,
    },
    MessagesAdd(:final notes) => {
      'kind': 'messages.add',
      'notes': [for (final n in notes) _note(n)],
    },
    MessageSent(:final id, :final note) => {
      'kind': 'message.sent',
      'id': id,
      'note': _note(note),
    },
    HelpAccept(:final id, :final name) => {
      'kind': 'help.accept',
      'id': id,
      'name': name,
    },
    HelpPost(:final request) => {
      'kind': 'help.post',
      'request': _request(request),
    },
    ReminderSet(:final id, :final reminder) => {
      'kind': 'reminder.set',
      'id': id,
      'reminder': reminder.name,
    },
    VolunteerSet(:final id, :final name) => {
      'kind': 'volunteer.set',
      'id': id,
      'name': name,
    },
    HandoverSet(:final text, :final by) => {
      'kind': 'handover.set',
      'text': text,
      'by': {'source': by.source.name, 'name': by.name},
    },
    AccessSet(:final access) => {
      'kind': 'access.set',
      'access': access.name,
    },
    ReportAdd(:final report) => {
      'kind': 'report.add',
      'report': _report(report),
    },
    MemberSet(:final name, :final access) => {
      'kind': 'member.set',
      'name': name,
      'access': access.name,
    },
    EntryEdit(:final id, :final body) => {
      'kind': 'entry.edit',
      'id': id,
      'body': body,
    },
    EntryRemove(:final id) => {'kind': 'entry.remove', 'id': id},
    RequestRemove(:final id) => {'kind': 'request.remove', 'id': id},
    AppointmentAdd(:final appointment) => {
      'kind': 'appointment.add',
      'appointment': _appointment(appointment),
    },
    OnboardingSet(:final onboarded) => {
      'kind': 'onboarding.set',
      'onboarded': onboarded.name,
    },
    StoryDismiss(:final count) => {
      'kind': 'story.dismiss',
      'count': count,
    },
  };
}

// ── State ────────────────────────────────────────────────────────────────

Json encodeState(PocketState s) {
  return {
    'tick': s.tick,
    'access': s.access.name,
    'recipient': {'name': s.recipient.name, 'photoId': s.recipient.photoId},
    'handover': s.handover,
    'handoverBy': {
      'source': s.handoverBy.source.name,
      'name': s.handoverBy.name,
    },
    'onboarded': s.onboarded.name,
    'storyDismissed': s.storyDismissed,
    'nextVisit': s.nextVisit,
    'familyStatus': s.familyStatus,
    'people': [for (final p in s.people) _person(p)],
    'entries': [for (final e in s.entries) _entry(e)],
    'prompts': [for (final p in s.prompts) _prompt(p)],
    'works': [for (final w in s.works) _work(w)],
    'messages': [for (final n in s.messages) _note(n)],
    'requests': [for (final r in s.requests) _request(r)],
    'appointments': [for (final a in s.appointments) _appointment(a)],
    'reports': [for (final r in s.reports) _report(r)],
  };
}

PocketState decodeState(Json j) {
  return PocketState(
    tick: j['tick']! as int,
    access: AccessState.values.byName(j['access']! as String),
    recipient: _toRecipient(j['recipient']),
    handover: j['handover']! as String,
    handoverBy: _toHandoverBy(j['handoverBy']),
    onboarded: _enumOr(Onboarding.values, j['onboarded'], Onboarding.done),
    storyDismissed: j['storyDismissed'] as int? ?? 0,
    nextVisit: j['nextVisit']! as String,
    familyStatus: j['familyStatus']! as String,
    people: _list(j['people'], _toPerson),
    entries: _list(j['entries'], _toEntry),
    prompts: _list(j['prompts'], _toPrompt),
    works: _list(j['works'], _toWork),
    messages: _list(j['messages'], _toNote),
    requests: _list(j['requests'], _toRequest),
    appointments: _list(j['appointments'], _toAppointment),
    reports: _list(j['reports'], _toReport),
  );
}

// ── Actor ────────────────────────────────────────────────────────────────

Json? encodeActor(Actor? actor) {
  if (actor == null) {
    return null;
  }

  return {'role': actor.role.name, 'name': actor.name};
}

/// Null for anything that is not a well-formed actor, so a bad save signs out.
Actor? decodeActor(Object? raw) {
  if (raw is! Map) {
    return null;
  }

  final role = Role.values.asNameMap()[raw['role']];
  final name = raw['name'];

  if (role == null || name is! String) {
    return null;
  }

  return Actor(role: role, name: name);
}

// ── Records ──────────────────────────────────────────────────────────────

Json _when(When w) {
  return {
    'dayOffset': w.dayOffset,
    'hour': w.hour,
    'minute': w.minute,
    'seq': w.seq,
  };
}

When _toWhen(Object? raw) {
  final j = raw! as Json;

  return When(
    dayOffset: j['dayOffset']! as int,
    hour: j['hour']! as int,
    minute: j['minute']! as int,
    seq: j['seq']! as int,
  );
}

Recipient _toRecipient(Object? raw) {
  if (raw is! Map) {
    return const Recipient(name: 'Pamela', photoId: null);
  }

  return Recipient(
    name: raw['name']! as String,
    photoId: raw['photoId'] as String?,
  );
}

HandoverBy _toHandoverBy(Object? raw) {
  if (raw is! Map) {
    return const HandoverBy.person('Alex');
  }

  if (raw['source'] == HandoverSource.ai.name) {
    return const HandoverBy.ai();
  }

  return HandoverBy.person(raw['name'] as String? ?? 'Alex');
}

Json _person(Person p) {
  return {'name': p.name, 'role': p.role.name, 'access': p.access.name};
}

Person _toPerson(Json j) {
  return Person(
    name: j['name']! as String,
    role: Role.values.byName(j['role']! as String),
    access: _enumOr(AccessState.values, j['access'], AccessState.active),
  );
}

Json _entry(DiaryEntry e) {
  return {
    'id': e.id,
    'kind': e.kind.name,
    'body': e.body,
    'authorName': e.authorName,
    'authorRole': e.authorRole.name,
    'when': _when(e.when),
    'attachment': e.attachment.name,
    'voice': e.voice.name,
    'question': e.question?.name,
    'fileIds': e.fileIds,
  };
}

DiaryEntry _toEntry(Json j) {
  return DiaryEntry(
    id: j['id']! as String,
    kind: EntryKind.values.byName(j['kind']! as String),
    body: j['body']! as String,
    authorName: j['authorName']! as String,
    authorRole: Role.values.byName(j['authorRole']! as String),
    when: _toWhen(j['when']),
    attachment: _enumOr(Attachment.values, j['attachment'], Attachment.none),
    voice: _enumOr(VoiceNote.values, j['voice'], VoiceNote.none),
    question: _enumOrNull(QuestionState.values, j['question']),
    fileIds: _strings(j['fileIds']),
  );
}

Json _prompt(Prompt p) {
  return {
    'id': p.id,
    'section': p.section.name,
    'ask': p.ask,
    'answer': p.answer,
    'year': p.year,
    'photoId': p.photoId,
  };
}

Prompt _toPrompt(Json j) {
  return Prompt(
    id: j['id']! as String,
    section: StorySection.values.byName(j['section']! as String),
    ask: j['ask']! as String,
    answer: j['answer']! as String,
    year: j['year'] as String? ?? '',
    photoId: j['photoId'] as String?,
  );
}

Json _work(WorkCard w) {
  return {
    'id': w.id,
    'situation': w.situation,
    'helps': w.helps,
    'hinders': w.hinders,
    'observations': w.observations,
    'pattern': w.pattern,
  };
}

WorkCard _toWork(Json j) {
  return WorkCard(
    id: j['id']! as String,
    situation: j['situation']! as String,
    helps: j['helps']! as String,
    hinders: j['hinders']! as String,
    observations: _strings(j['observations']),
    pattern: j['pattern'] as String? ?? '',
  );
}

Json _note(Note n) {
  return {
    'id': n.id,
    'thread': n.thread.name,
    'source': n.source.name,
    'author': n.author,
    'body': n.body,
    'when': _when(n.when),
    'known': n.known?.name,
    'escalation': n.escalation?.name,
    'asked': n.asked,
    'owner': n.owner,
  };
}

Note _toNote(Json j) {
  return Note(
    id: j['id']! as String,
    thread: Thread.values.byName(j['thread']! as String),
    source: MessageSource.values.byName(j['source']! as String),
    author: j['author']! as String,
    body: j['body']! as String,
    when: _toWhen(j['when']),
    known: _enumOrNull(Known.values, j['known']),
    escalation: _enumOrNull(Escalation.values, j['escalation']),
    asked: j['asked'] as String?,
    owner: j['owner'] as String?,
  );
}

Json _request(HelpRequest r) {
  return {
    'id': r.id,
    'kind': r.kind.name,
    'text': r.text,
    'acceptedBy': r.acceptedBy,
    'appointmentId': r.appointmentId,
  };
}

HelpRequest _toRequest(Json j) {
  return HelpRequest(
    id: j['id']! as String,
    kind: RequestKind.values.byName(j['kind']! as String),
    text: j['text']! as String,
    acceptedBy: j['acceptedBy'] as String?,
    appointmentId: j['appointmentId'] as String?,
  );
}

Json _appointment(Appointment a) {
  return {
    'id': a.id,
    'when': _when(a.when),
    'place': a.place,
    'reason': a.reason,
    'transport': a.transport,
    'notes': a.notes,
    'reminder': a.reminder.name,
    'volunteer': a.volunteer,
  };
}

Appointment _toAppointment(Json j) {
  return Appointment(
    id: j['id']! as String,
    when: _toWhen(j['when']),
    place: j['place']! as String,
    reason: j['reason']! as String,
    transport: j['transport'] as String? ?? '',
    notes: j['notes'] as String? ?? '',
    reminder: _enumOr(Reminder.values, j['reminder'], Reminder.off),
    volunteer: j['volunteer'] as String?,
  );
}

Json _report(Report r) {
  return {
    'id': r.id,
    'when': _when(r.when),
    'author': r.author,
    'title': r.title,
    'note': r.note,
    'original': r.original,
    'summary': r.summary,
    'fileId': r.fileId,
  };
}

Report _toReport(Json j) {
  return Report(
    id: j['id']! as String,
    when: _toWhen(j['when']),
    author: j['author']! as String,
    title: j['title']! as String,
    note: j['note'] as String? ?? '',
    original: j['original']! as String,
    summary: j['summary']! as String,
    fileId: j['fileId'] as String?,
  );
}

// ── Helpers ──────────────────────────────────────────────────────────────

List<T> _list<T>(Object? raw, T Function(Json) decode) {
  return [for (final item in raw as List? ?? const []) decode(item as Json)];
}

List<String> _strings(Object? raw) {
  return List<String>.from(raw as List? ?? const []);
}

T _enumOr<T extends Enum>(List<T> values, Object? raw, T fallback) {
  return values.asNameMap()[raw] ?? fallback;
}

T? _enumOrNull<T extends Enum>(List<T> values, Object? raw) {
  return values.asNameMap()[raw];
}
