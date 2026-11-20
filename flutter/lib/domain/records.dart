import 'enums.dart';

/// A moment relative to the day the app is opened: offset 0 is today.
/// `seq` orders two events in the same minute.
class When {
  const When({
    required this.dayOffset,
    required this.hour,
    required this.minute,
    required this.seq,
  });

  final int dayOffset;
  final int hour;
  final int minute;
  final int seq;
}

class Actor {
  const Actor({required this.role, required this.name});

  final Role role;
  final String name;
}

/// Staff rows stay active; the household PIN lives on PocketState.access.
class Person {
  const Person({required this.name, required this.role, required this.access});

  final String name;
  final Role role;
  final AccessState access;

  Person copyWith({AccessState? access}) {
    return Person(name: name, role: role, access: access ?? this.access);
  }
}

class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.kind,
    required this.body,
    required this.authorName,
    required this.authorRole,
    required this.when,
    required this.attachment,
    required this.voice,
    required this.question,
    required this.fileIds,
  });

  final String id;
  final EntryKind kind;
  final String body;
  final String authorName;
  final Role authorRole;
  final When when;
  final Attachment attachment;
  final VoiceNote voice;

  /// Null unless [kind] is a question.
  final QuestionState? question;
  final List<String> fileIds;

  DiaryEntry copyWith({String? body, QuestionState? question}) {
    return DiaryEntry(
      id: id,
      kind: kind,
      body: body ?? this.body,
      authorName: authorName,
      authorRole: authorRole,
      when: when,
      attachment: attachment,
      voice: voice,
      question: question ?? this.question,
      fileIds: fileIds,
    );
  }
}

class Prompt {
  const Prompt({
    required this.id,
    required this.section,
    required this.ask,
    required this.answer,
    required this.year,
    required this.photoId,
  });

  final String id;
  final StorySection section;
  final String ask;
  final String answer;
  final String year;
  final String? photoId;

  /// The same prompt with a new answer and photo; null [photoId] clears it.
  Prompt answered(String answer, String? photoId) {
    return Prompt(
      id: id,
      section: section,
      ask: ask,
      answer: answer,
      year: year,
      photoId: photoId,
    );
  }
}

class WorkCard {
  const WorkCard({
    required this.id,
    required this.situation,
    required this.helps,
    required this.hinders,
    required this.observations,
    required this.pattern,
  });

  final String id;
  final String situation;
  final String helps;
  final String hinders;
  final List<String> observations;
  final String pattern;

  WorkCard copyWith({List<String>? observations}) {
    return WorkCard(
      id: id,
      situation: situation,
      helps: helps,
      hinders: hinders,
      observations: observations ?? this.observations,
      pattern: pattern,
    );
  }
}

/// A chat line. [owner] is the actor name on guide notes, null on care notes.
class Note {
  const Note({
    required this.id,
    required this.thread,
    required this.source,
    required this.author,
    required this.body,
    required this.when,
    required this.known,
    required this.escalation,
    required this.asked,
    required this.owner,
  });

  final String id;
  final Thread thread;
  final MessageSource source;
  final String author;
  final String body;
  final When when;
  final Known? known;
  final Escalation? escalation;
  final String? asked;
  final String? owner;

  Note copyWith({Escalation? escalation}) {
    return Note(
      id: id,
      thread: thread,
      source: source,
      author: author,
      body: body,
      when: when,
      known: known,
      escalation: escalation ?? this.escalation,
      asked: asked,
      owner: owner,
    );
  }
}

class HelpRequest {
  const HelpRequest({
    required this.id,
    required this.kind,
    required this.text,
    required this.acceptedBy,
    required this.appointmentId,
  });

  final String id;
  final RequestKind kind;
  final String text;
  final String? acceptedBy;

  /// Null unless the request was posted from an appointment.
  final String? appointmentId;

  HelpRequest copyWith({String? acceptedBy}) {
    return HelpRequest(
      id: id,
      kind: kind,
      text: text,
      acceptedBy: acceptedBy ?? this.acceptedBy,
      appointmentId: appointmentId,
    );
  }
}

class Appointment {
  const Appointment({
    required this.id,
    required this.when,
    required this.place,
    required this.reason,
    required this.transport,
    required this.notes,
    required this.reminder,
    required this.volunteer,
  });

  final String id;
  final When when;
  final String place;
  final String reason;
  final String transport;
  final String notes;
  final Reminder reminder;
  final String? volunteer;

  Appointment copyWith({Reminder? reminder, String? volunteer}) {
    return Appointment(
      id: id,
      when: when,
      place: place,
      reason: reason,
      transport: transport,
      notes: notes,
      reminder: reminder ?? this.reminder,
      volunteer: volunteer ?? this.volunteer,
    );
  }
}

class Report {
  const Report({
    required this.id,
    required this.when,
    required this.author,
    required this.title,
    required this.note,
    required this.original,
    required this.summary,
    required this.fileId,
  });

  final String id;
  final When when;
  final String author;
  final String title;
  final String note;
  final String original;
  final String summary;
  final String? fileId;
}

class Recipient {
  const Recipient({required this.name, required this.photoId});

  final String name;
  final String? photoId;
}

/// Who wrote the handover: a named person, or the model.
class HandoverBy {
  const HandoverBy.person(String this.name) : source = HandoverSource.person;

  const HandoverBy.ai() : source = HandoverSource.ai, name = null;

  final HandoverSource source;
  final String? name;
}

class Answer {
  const Answer({required this.known, required this.body});

  final Known known;
  final String body;
}

/// The whole household record. Commands produce a new one; nothing mutates.
class PocketState {
  const PocketState({
    required this.tick,
    required this.access,
    required this.recipient,
    required this.handover,
    required this.handoverBy,
    required this.onboarded,
    required this.storyDismissed,
    required this.nextVisit,
    required this.familyStatus,
    required this.people,
    required this.entries,
    required this.prompts,
    required this.works,
    required this.messages,
    required this.requests,
    required this.appointments,
    required this.reports,
  });

  final int tick;
  final AccessState access;
  final Recipient recipient;
  final String handover;
  final HandoverBy handoverBy;
  final Onboarding onboarded;

  /// Empty-prompt count when the owner dismissed the Today story row.
  final int storyDismissed;
  final String nextVisit;
  final String familyStatus;
  final List<Person> people;
  final List<DiaryEntry> entries;
  final List<Prompt> prompts;
  final List<WorkCard> works;
  final List<Note> messages;
  final List<HelpRequest> requests;
  final List<Appointment> appointments;
  final List<Report> reports;

  PocketState copyWith({
    int? tick,
    AccessState? access,
    String? handover,
    HandoverBy? handoverBy,
    Onboarding? onboarded,
    int? storyDismissed,
    List<Person>? people,
    List<DiaryEntry>? entries,
    List<Prompt>? prompts,
    List<WorkCard>? works,
    List<Note>? messages,
    List<HelpRequest>? requests,
    List<Appointment>? appointments,
    List<Report>? reports,
  }) {
    return PocketState(
      tick: tick ?? this.tick,
      access: access ?? this.access,
      recipient: recipient,
      handover: handover ?? this.handover,
      handoverBy: handoverBy ?? this.handoverBy,
      onboarded: onboarded ?? this.onboarded,
      storyDismissed: storyDismissed ?? this.storyDismissed,
      nextVisit: nextVisit,
      familyStatus: familyStatus,
      people: people ?? this.people,
      entries: entries ?? this.entries,
      prompts: prompts ?? this.prompts,
      works: works ?? this.works,
      messages: messages ?? this.messages,
      requests: requests ?? this.requests,
      appointments: appointments ?? this.appointments,
      reports: reports ?? this.reports,
    );
  }
}
