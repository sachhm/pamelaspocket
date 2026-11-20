import 'enums.dart';
import 'records.dart';
import 'time.dart';

/// The voice stand-in. No microphone opens; the demo inserts this line.
const sampleVoice = 'She said the lemons from Joan were the best this year.';

const _photoOnly = 'Photo from the visit.';

/// Exact sentences the owner picks on Ask for help.
String requestText(RequestKind kind) {
  return switch (kind) {
    RequestKind.appointment => 'Can someone take Mum to her appointment?',
    RequestKind.visit => 'Who can visit this weekend?',
    RequestKind.prescription => 'Can someone collect a prescription?',
  };
}

/// Linked lift request from an appointment leaf.
/// e.g. "Can someone take Mum to Hills Medical on Thursday 10:30 am?"
String appointmentHelpText(Appointment item, DateTime today) {
  final day = DateTime(today.year, today.month, today.day + item.when.dayOffset);
  final weekday = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][day.weekday - 1];

  return 'Can someone take Mum to ${item.place} on $weekday ${formatClock(item.when)}?';
}

/// What a screen hands the desk. Author, role, and time are the desk's job.
typedef NewEntry = ({
  EntryKind kind,
  String body,
  Attachment attachment,
  VoiceNote voice,
  List<String> fileIds,
});

/// The body that will be saved. Voice and photo can stand in for typed text.
/// Empty means there is nothing to save.
String composeBody(NewEntry draft) {
  final typed = draft.body.trim();
  final voice = draft.voice == VoiceNote.sample;

  if (voice && typed.contains(sampleVoice)) {
    return typed;
  }

  if (voice && typed.isNotEmpty) {
    return '$typed\n\n$sampleVoice';
  }

  if (voice) {
    return sampleVoice;
  }

  if (typed.isNotEmpty) {
    return typed;
  }

  if (draft.attachment == Attachment.photo) {
    return _photoOnly;
  }

  return '';
}
