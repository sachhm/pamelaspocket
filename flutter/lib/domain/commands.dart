import 'enums.dart';
import 'records.dart';

/// One command, one future HTTP call. The desk builds these after its gate
/// check; `apply` turns them into the next state.
sealed class CareCommand {
  const CareCommand();
}

final class EntryAdd extends CareCommand {
  const EntryAdd(this.entry);

  final DiaryEntry entry;
}

final class QuestionResolve extends CareCommand {
  const QuestionResolve(this.id);

  final String id;
}

/// Replaces one prompt's answer and its photo. Null [photoId] means none.
final class AnswerSave extends CareCommand {
  const AnswerSave(this.id, this.text, {this.photoId});

  final String id;
  final String text;
  final String? photoId;
}

final class ObservationAdd extends CareCommand {
  const ObservationAdd(this.worksId, this.line);

  final String worksId;
  final String line;
}

final class MessagesAdd extends CareCommand {
  const MessagesAdd(this.notes);

  final List<Note> notes;
}

final class MessageSent extends CareCommand {
  const MessageSent(this.id, this.note);

  final String id;
  final Note note;
}

final class HelpAccept extends CareCommand {
  const HelpAccept(this.id, this.name);

  final String id;
  final String name;
}

final class HelpPost extends CareCommand {
  const HelpPost(this.request);

  final HelpRequest request;
}

final class ReminderSet extends CareCommand {
  const ReminderSet(this.id, this.reminder);

  final String id;
  final Reminder reminder;
}

final class VolunteerSet extends CareCommand {
  const VolunteerSet(this.id, this.name);

  final String id;
  final String name;
}

final class HandoverSet extends CareCommand {
  const HandoverSet(this.text, this.by);

  final String text;
  final HandoverBy by;
}

final class AccessSet extends CareCommand {
  const AccessSet(this.access);

  final AccessState access;
}

final class ReportAdd extends CareCommand {
  const ReportAdd(this.report);

  final Report report;
}

final class MemberSet extends CareCommand {
  const MemberSet(this.name, this.access);

  final String name;
  final AccessState access;
}

final class EntryEdit extends CareCommand {
  const EntryEdit(this.id, this.body);

  final String id;
  final String body;
}

final class EntryRemove extends CareCommand {
  const EntryRemove(this.id);

  final String id;
}

final class RequestRemove extends CareCommand {
  const RequestRemove(this.id);

  final String id;
}

final class AppointmentAdd extends CareCommand {
  const AppointmentAdd(this.appointment);

  final Appointment appointment;
}

final class OnboardingSet extends CareCommand {
  const OnboardingSet(this.onboarded);

  final Onboarding onboarded;
}

final class StoryDismiss extends CareCommand {
  const StoryDismiss(this.count);

  final int count;
}
