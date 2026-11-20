import 'package:flutter_test/flutter_test.dart';
import 'package:pocket/domain/copy.dart';
import 'package:pocket/domain/enums.dart';
import 'package:pocket/domain/records.dart';

NewEntry _draft(
  String body, {
  VoiceNote voice = VoiceNote.none,
  Attachment photo = Attachment.none,
}) {
  return (
    kind: EntryKind.general,
    body: body,
    attachment: photo,
    voice: voice,
    fileIds: const [],
  );
}

void main() {
  test('typed text is trimmed', () {
    expect(composeBody(_draft('  Tea in the garden.  ')), 'Tea in the garden.');
  });

  test('voice adds the sample once', () {
    expect(composeBody(_draft('', voice: VoiceNote.sample)), sampleVoice);
    expect(
      composeBody(_draft('Tea.', voice: VoiceNote.sample)),
      'Tea.\n\n$sampleVoice',
    );
    expect(
      composeBody(_draft('Tea. $sampleVoice', voice: VoiceNote.sample)),
      'Tea. $sampleVoice',
    );
  });

  test('a photo with no text gets the stand-in line', () {
    expect(
      composeBody(_draft(' ', photo: Attachment.photo)),
      'Photo from the visit.',
    );
  });

  test('nothing written and nothing attached is empty', () {
    expect(composeBody(_draft('   ')), '');
  });

  test('request sentences match the product copy', () {
    expect(
      requestText(RequestKind.appointment),
      'Can someone take Mum to her appointment?',
    );
    expect(requestText(RequestKind.visit), 'Who can visit this weekend?');
    expect(
      requestText(RequestKind.prescription),
      'Can someone collect a prescription?',
    );
  });

  test('appointment help names the place and the time', () {
    final text = appointmentHelpText(
      const Appointment(
        id: 'appt-gp',
        when: When(dayOffset: 3, hour: 10, minute: 30, seq: 1),
        place: 'GP',
        reason: 'Routine check',
        transport: '',
        notes: '',
        reminder: Reminder.off,
        volunteer: null,
      ),
      DateTime(2026, 11, 18),
    );

    expect(text, contains('GP'));
    expect(text, contains('10:30 am'));
    expect(text, startsWith('Can someone take Mum to '));
  });
}
