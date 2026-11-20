import 'dart:math';

import 'commands.dart';
import 'enums.dart';
import 'records.dart';

/// Pure transition: one command in, the next state out. Adapters persist the
/// result; they never reimplement these rules. The switch is exhaustive, so a
/// new command kind does not compile until it is handled here.
PocketState apply(PocketState s, CareCommand command) {
  return switch (command) {
    // Newest first; the stamped seq becomes the tick so the next stamp is unique.
    EntryAdd(:final entry) => s.copyWith(
      tick: max(s.tick, entry.when.seq),
      entries: [entry, ...s.entries],
    ),
    QuestionResolve(:final id) => s.copyWith(
      entries: [
        for (final e in s.entries)
          e.id == id ? e.copyWith(question: QuestionState.resolved) : e,
      ],
    ),
    AnswerSave(:final id, :final text, :final photoId) => s.copyWith(
      prompts: [
        for (final p in s.prompts) p.id == id ? p.answered(text, photoId) : p,
      ],
    ),
    ObservationAdd(:final worksId, :final line) => s.copyWith(
      works: [
        for (final w in s.works)
          w.id == worksId
              ? w.copyWith(observations: [...w.observations, line])
              : w,
      ],
    ),
    MessagesAdd(:final notes) => s.copyWith(
      tick: notes.fold<int>(s.tick, (tick, n) => max(tick, n.when.seq)),
      messages: [...s.messages, ...notes],
    ),
    MessageSent(:final id, :final note) => s.copyWith(
      tick: max(s.tick, note.when.seq),
      messages: [
        for (final n in s.messages)
          n.id == id ? n.copyWith(escalation: Escalation.sent) : n,
        note,
      ],
    ),

    // One acceptor: a taken request keeps its first name.
    HelpAccept(:final id, :final name) => s.copyWith(
      requests: [
        for (final r in s.requests)
          r.id == id && r.acceptedBy == null ? r.copyWith(acceptedBy: name) : r,
      ],
    ),
    HelpPost(:final request) => s.copyWith(requests: [request, ...s.requests]),
    RequestRemove(:final id) => s.copyWith(
      requests: [
        for (final r in s.requests)
          if (r.id != id) r,
      ],
    ),
    ReminderSet(:final id, :final reminder) => s.copyWith(
      appointments: [
        for (final a in s.appointments)
          a.id == id ? a.copyWith(reminder: reminder) : a,
      ],
    ),
    VolunteerSet(:final id, :final name) => s.copyWith(
      appointments: [
        for (final a in s.appointments)
          a.id == id && a.volunteer == null ? a.copyWith(volunteer: name) : a,
      ],
    ),
    AppointmentAdd(:final appointment) => s.copyWith(
      tick: max(s.tick, appointment.when.seq),
      appointments: [...s.appointments, appointment],
    ),
    HandoverSet(:final text, :final by) => s.copyWith(
      handover: text,
      handoverBy: by,
    ),
    AccessSet(:final access) => s.copyWith(access: access),

    // Staff use the household PIN, so only family rows carry their own access.
    MemberSet(:final name, :final access) => s.copyWith(
      people: [
        for (final p in s.people)
          p.name == name && p.role == Role.family
              ? p.copyWith(access: access)
              : p,
      ],
    ),
    ReportAdd(:final report) => s.copyWith(
      tick: max(s.tick, report.when.seq),
      reports: [report, ...s.reports],
    ),

    // Owner edits replace the body only; kind, author and time stay.
    EntryEdit(:final id, :final body) => s.copyWith(
      entries: [
        for (final e in s.entries) e.id == id ? e.copyWith(body: body) : e,
      ],
    ),
    EntryRemove(:final id) => s.copyWith(
      entries: [
        for (final e in s.entries)
          if (e.id != id) e,
      ],
    ),
    OnboardingSet(:final onboarded) => s.copyWith(onboarded: onboarded),
    StoryDismiss(:final count) => s.copyWith(storyDismissed: count),
  };
}
