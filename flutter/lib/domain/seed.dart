import 'enums.dart';
import 'records.dart';

// Transcribed from the Expo src/domain/seed.ts. Do not rewrite the copy.

When _at(int dayOffset, int hour, int minute, int seq) {
  return When(dayOffset: dayOffset, hour: hour, minute: minute, seq: seq);
}

DiaryEntry _entry(
  String id,
  EntryKind kind,
  String body,
  String author,
  Role role,
  When when,
) {
  return DiaryEntry(
    id: id,
    kind: kind,
    body: body,
    authorName: author,
    authorRole: role,
    when: when,
    attachment: Attachment.none,
    voice: VoiceNote.none,
    question: kind == EntryKind.question ? QuestionState.open : null,
    fileIds: const [],
  );
}

Prompt _prompt(
  String id,
  StorySection section,
  String ask,
  String answer, [
  String year = '',
]) {
  return Prompt(
    id: id,
    section: section,
    ask: ask,
    answer: answer,
    year: year,
    photoId: null,
  );
}

Note _note(
  String id,
  Thread thread,
  MessageSource source,
  String author,
  String body,
  When when, {
  Known? known,
  String? asked,
  String? owner,
}) {
  return Note(
    id: id,
    thread: thread,
    source: source,
    author: author,
    body: body,
    when: when,
    known: known,
    escalation: null,
    asked: asked,
    owner: owner,
  );
}

/// Pamela's household. Offsets, not dates, so Today stays today whenever
/// the demo is opened.
PocketState createSeed() {
  final breakfast = _entry(
    'entry-breakfast',
    EntryKind.general,
    'Pamela slept through the night. Porridge with honey at breakfast, and tea with milk. She was cheerful.',
    'Jordan',
    Role.staff,
    _at(0, 8, 10, 1),
  );
  final phone = _entry(
    'entry-phone',
    EntryKind.mood,
    'A phone rang in the lounge and she became upset. I stepped outside and told her first. She settled.',
    'Jordan',
    Role.staff,
    _at(0, 9, 40, 2),
  );
  final garden = _entry(
    'entry-garden',
    EntryKind.moment,
    'She hummed along to Vera Lynn while we watered the herbs.',
    'Alex',
    Role.owner,
    _at(0, 11, 15, 3),
  );
  final lift = _entry(
    'entry-lift',
    EntryKind.important,
    'GP visit is coming up. She needs a lift and likes to leave with time to spare.',
    'Sam',
    Role.staff,
    _at(-1, 16, 5, 4),
  );
  final cushion = _entry(
    'entry-cushion',
    EntryKind.question,
    'Has the new cushion arrived for her chair?',
    'Chris',
    Role.family,
    _at(0, 12, 5, 5),
  );

  return PocketState(
    tick: 20,
    access: AccessState.active,
    recipient: const Recipient(name: 'Pamela', photoId: null),
    handover:
        'Pamela slept well and ate porridge with honey this morning. A phone call in the lounge upset her. Stepping outside, after telling her first, settled her. She has a GP visit coming up and will need a lift.',
    handoverBy: const HandoverBy.person('Alex'),
    onboarded: Onboarding.done,
    storyDismissed: 0,
    nextVisit:
        'Spare clothes are in the hall cupboard, second shelf. Give her time before leaving the house. She likes the radio low.',
    familyStatus:
        'Pamela had a gentle morning. A phone call unsettled her, then the garden settled her again.',
    people: const [
      Person(name: 'Alex', role: Role.owner, access: AccessState.active),
      Person(name: 'Jordan', role: Role.staff, access: AccessState.active),
      Person(name: 'Sam', role: Role.staff, access: AccessState.active),
      Person(name: 'Chris', role: Role.family, access: AccessState.active),
    ],
    entries: [cushion, garden, phone, breakfast, lift],
    prompts: [
      _prompt(
        'grew-up',
        StorySection.life,
        'Where did Pamela grow up?',
        'Fremantle, in a weatherboard house near the harbour.',
        '1948',
      ),
      _prompt(
        'work',
        StorySection.life,
        'What did she do for work?',
        'Primary school teacher for thirty years.',
        '1966',
      ),
      _prompt(
        'milestones',
        StorySection.life,
        'What are the important milestones?',
        'Married David in 1968. Alex and Chris came along. She moved to the hills after she retired.',
        '1968',
      ),
      _prompt(
        'people',
        StorySection.life,
        'Who are the significant people in her life?',
        'David, who died in 2019. Alex most days, Chris on weekends, and Joan next door with the lemons.',
      ),
      _prompt(
        'proud',
        StorySection.life,
        'What is she proud of?',
        'The school garden she started, and raising her children.',
        '1996',
      ),
      _prompt(
        'stories',
        StorySection.life,
        'What stories does she like to tell?',
        'The class rabbit that escaped on sports day. She laughs at the same line every time.',
      ),
      _prompt(
        'laugh',
        StorySection.personality,
        'What makes her laugh?',
        'Silly mix-ups, and that rabbit story.',
      ),
      _prompt(
        'music',
        StorySection.personality,
        'What music, television, or activities does she enjoy?',
        'Vera Lynn, the ABC in the morning, and watering the herbs.',
      ),
      _prompt(
        'comfort',
        StorySection.personality,
        'What makes her feel comfortable?',
        'Her own mug, a warm rug, and someone sitting nearby without rushing.',
      ),
      _prompt(
        'dislike',
        StorySection.personality,
        'What does she dislike?',
        'Phones in front of her, being hurried, and a loud television.',
      ),
      _prompt(
        'phrases',
        StorySection.personality,
        'What familiar phrases does she use?',
        '"We\'ll get there." and "Cup of tea first."',
      ),
      _prompt(
        'herself',
        StorySection.personality,
        'What makes her feel like herself?',
        'Talking about the garden, as a teacher rather than a patient.',
      ),
      _prompt(
        'good-day',
        StorySection.routines,
        'What does a good day look like?',
        'Slow breakfast, the radio low, a walk to the letterbox, then the herbs if the weather is kind.',
      ),
      _prompt(
        'hard-day',
        StorySection.routines,
        'What does a difficult day look like?',
        'Noise, surprise visitors, and a morning out of order.',
      ),
      _prompt(
        'distress',
        StorySection.routines,
        'What situations cause distress or confusion?',
        'A phone in the room, being left without a word, or a rush to the car.',
      ),
      _prompt(
        'helps',
        StorySection.routines,
        'What usually helps?',
        'Explain before leaving. Step outside for calls. One step at a time.',
      ),
      _prompt(
        'not-worked',
        StorySection.routines,
        'What approaches have not worked?',
        'Sharp corrections, calls taken in front of her, and turning the television up.',
      ),
      _prompt(
        'spoken',
        StorySection.routines,
        'How does she prefer to be spoken to?',
        'Calm, adult, and unhurried. Include her in the decision.',
      ),
    ],
    works: const [
      WorkCard(
        id: 'phone-calls',
        situation: 'Becomes upset when someone uses their phone.',
        helps: 'Step outside to take calls and explain calmly before leaving.',
        hinders: 'Taking calls directly in front of her.',
        observations: [
          'Jordan: Stepping into the hall and saying "I\'ll be two minutes" worked this morning.',
        ],
        pattern:
            'When a phone call upsets Pamela, leaving the room after a short explanation has helped.',
      ),
      WorkCard(
        id: 'leaving',
        situation: 'Gets anxious when it is time to go out.',
        helps: 'Lay the coat out early and say where you are going, once.',
        hinders: 'Repeating the plan many times, or rushing her to the car.',
        observations: [],
        pattern: '',
      ),
    ],
    messages: [
      _note(
        'note-clothes',
        Thread.care,
        MessageSource.person,
        'Jordan',
        'Where are the spare clothes?',
        _at(0, 8, 20, 6),
      ),
      _note(
        'note-clothes-ai',
        Thread.care,
        MessageSource.ai,
        'Pocket',
        'Spare clothes are in the hall cupboard, on the second shelf.',
        _at(0, 8, 20, 7),
        known: Known.yes,
        asked: 'Where are the spare clothes?',
      ),
      _note(
        'note-cardigan',
        Thread.care,
        MessageSource.person,
        'Alex',
        'Thanks. The blue cardigan is the one she asks for.',
        _at(0, 8, 32, 8),
      ),
      _note(
        'note-guide',
        Thread.guide,
        MessageSource.ai,
        'Pocket',
        'This space is just for you. It is not medical advice, and nothing you write here is added to the shared diary.',
        _at(0, 7, 0, 9),
        owner: 'Alex',
      ),
    ],
    requests: const [
      HelpRequest(
        id: 'help-appointment',
        kind: RequestKind.appointment,
        text: 'Can someone take Mum to her appointment?',
        acceptedBy: null,
        appointmentId: null,
      ),
      HelpRequest(
        id: 'help-visit',
        kind: RequestKind.visit,
        text: 'Who can visit this weekend?',
        acceptedBy: null,
        appointmentId: null,
      ),
      HelpRequest(
        id: 'help-script',
        kind: RequestKind.prescription,
        text: 'Can someone collect a prescription?',
        acceptedBy: 'Chris',
        appointmentId: null,
      ),
    ],
    appointments: [
      Appointment(
        id: 'appt-gp',
        when: _at(3, 10, 30, 10),
        place: 'Hills Medical',
        reason: 'Routine check',
        transport: 'Lift there and back',
        notes: 'She likes to arrive early.',
        reminder: Reminder.on,
        volunteer: null,
      ),
      Appointment(
        id: 'appt-hair',
        when: _at(12, 14, 0, 11),
        place: 'Marie in town',
        reason: 'Haircut',
        transport: 'Chris usually drives',
        notes: 'Afternoon, after lunch.',
        reminder: Reminder.off,
        volunteer: 'Chris',
      ),
    ],
    reports: [
      Report(
        id: 'report-nurse',
        when: _at(-6, 11, 0, 12),
        author: 'Priya Shah',
        title: 'Nurse visit',
        note: 'Home visit after a restless night.',
        original:
            'Visit completed at the home. Pamela was unsettled on arrival and settled after a cup of tea and a quiet chat about the garden. No wounds. Family to continue the usual morning routine. Follow-up in four weeks.',
        summary:
            'The nurse visited Pamela at home. She was unsettled at first, then settled with tea and a chat about the garden. There were no wounds. Keep the usual morning routine. The next visit is in four weeks.',
        fileId: null,
      ),
      Report(
        id: 'report-gp',
        when: _at(-20, 9, 30, 13),
        author: 'Dr Nguyen',
        title: 'Clinic letter',
        note: 'After the last clinic visit.',
        original:
            'Seen in clinic with her daughter. The current home routine can continue. A review was suggested in six months, sooner if the family is worried.',
        summary:
            'The clinic said to keep the current home routine. They suggested another visit in six months, or sooner if the family is worried.',
        fileId: null,
      ),
    ],
  );
}
