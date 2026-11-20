import 'dart:async';
import 'dart:typed_data';

import '../domain/chat.dart';
import '../domain/commands.dart';
import '../domain/copy.dart';
import '../domain/enums.dart';
import '../domain/records.dart';
import '../domain/time.dart';
import '../ports/auth_port.dart';
import '../ports/file_port.dart';
import '../ports/model_port.dart';
import '../ports/notify_port.dart';
import '../ports/record_port.dart';
import '../ports/scan_port.dart';

/// What `load` hands the session: who is signed in, and the household.
typedef Held = ({Actor? actor, PocketState state});

/// Silent NotifyPort when tests omit one. Compose wires LocalNotify.
class _QuietNotify implements NotifyPort {
  @override
  Future<void> set(String appointmentId, When when, Reminder reminder) async {}
}

/// Silent ScanPort when tests omit one. Compose wires LocalScan.
class _QuietScan implements ScanPort {
  @override
  Future<({ScanStatus status, String? token})> capture() async {
    return (status: ScanStatus.cancelled, token: null);
  }
}

// File-only reports have no sentences to quote.
const _fileOnlySummary = 'The original document is attached.';
const _unnamedAuthor = 'Not named';

/// Use cases. Holds no Flutter types. Each method checks its gate, then calls
/// ports. The desk is the only caller of the ports.
///
///   PocketScope ──▶ CareDesk ──▶ AuthPort, RecordPort ──▶ local | HTTP
class CareDesk {
  CareDesk(
    this._auth,
    this._records,
    this._model,
    this._files, {
    NotifyPort? notify,
    ScanPort? scan,
    this._clock = DateTime.now,
  }) : _notify = notify ?? _QuietNotify(),
       _scan = scan ?? _QuietScan();

  final AuthPort _auth;
  final RecordPort _records;
  final ModelPort _model;
  final FilePort _files;
  final NotifyPort _notify;
  final ScanPort _scan;
  final DateTime Function() _clock;

  // Runs one use case at a time so two taps cannot overwrite each other.
  Future<void> _tail = Future.value();

  Future<Held> load() {
    return _step(() async {
      final actor = await _auth.current();
      final state = _forCaller(actor, await _records.load());

      return (actor: actor, state: state);
    });
  }

  Future<AuthOutcome> signIn(Role role, String email, String password) {
    return _step(() => _gatedSignIn(role, email, password, signUp: false));
  }

  Future<AuthOutcome> signUp(Role role, String email, String password) {
    return _step(() => _gatedSignIn(role, email, password, signUp: true));
  }

  // Family sign-in also needs that member’s access still on.
  Future<AuthOutcome> _gatedSignIn(
    Role role,
    String email,
    String password, {
    required bool signUp,
  }) async {
    final outcome = signUp
        ? await _auth.signUp(role, email, password)
        : await _auth.signIn(role, email, password);

    if (outcome.result != SignInResult.ok || outcome.actor == null) {
      return outcome;
    }

    if (role != Role.family) {
      return outcome;
    }

    final person = (await _records.load()).people
        .where((p) => p.name == outcome.actor!.name && p.role == Role.family)
        .firstOrNull;

    if (person == null || person.access == AccessState.revoked) {
      await _auth.signOut();

      return AuthOutcome(SignInResult.rejected, null);
    }

    return outcome;
  }

  /// PIN screen stand-in for the camera. Returns the household token or cancel.
  Future<({ScanStatus status, String? token})> scan() {
    return _step(_scan.capture);
  }

  // Access lives on the household record, so read it before checking the PIN.
  Future<StaffOutcome> enterStaff(String pin, String name) {
    return _step(() async {
      final state = await _records.load();

      return _auth.enterStaff(pin, state.access, name);
    });
  }

  Future<void> signOut() {
    return _step(_auth.signOut);
  }

  Future<Actor> previewAs(Role role) {
    return _step(() => _auth.preview(role));
  }

  /// Owner only. Null when the gate fails; nothing is written.
  Future<PocketState?> setAccess(AccessState access) {
    return _step(() async {
      final held = await _hold(Gate.owner);

      if (held == null) {
        return null;
      }

      return _commit(held.actor!, AccessSet(access));
    });
  }

  /// Owner only. Family rows only; staff use the household PIN.
  Future<PocketState?> setMember(String name, AccessState access) {
    return _step(() async {
      final held = await _hold(Gate.owner);

      if (held == null) {
        return null;
      }

      final person = held.state.people
          .where((p) => p.name == name && p.role == Role.family)
          .firstOrNull;

      if (person == null) {
        return null;
      }

      return _commit(held.actor!, MemberSet(name, access));
    });
  }

  /// Owner only. Marks first-run onboarding finished (Later, or last prompt).
  Future<PocketState?> finishOnboarding() {
    return _owner(const OnboardingSet(Onboarding.done));
  }

  /// Owner only. Hides Today’s story cue until the empty count changes.
  Future<PocketState?> dismissStory() {
    return _step(() async {
      final held = await _hold(Gate.owner);

      if (held == null) {
        return null;
      }

      final empty = held.state.prompts
          .where(
            (p) =>
                p.section == StorySection.life && p.answer.trim().isEmpty,
          )
          .length;

      return _commit(held.actor!, StoryDismiss(empty));
    });
  }

  /// Any role. The desk stamps author, role, and time; a question starts
  /// open. Null when there is nothing to save. The handover refresh is a
  /// separate call so the composer can close before it runs.
  Future<PocketState?> addEntry(NewEntry draft) {
    return _step(() async {
      final held = await _hold(Gate.any);
      final body = composeBody(draft);

      if (held == null || body.isEmpty) {
        return null;
      }

      final stamp = stampNow(held.state.tick, _clock());
      final actor = held.actor!;
      final entry = DiaryEntry(
        id: makeId('entry', stamp.tick),
        kind: draft.kind,
        body: body,
        authorName: actor.name,
        authorRole: actor.role,
        when: stamp.when,
        attachment: draft.attachment,
        voice: draft.voice,
        question: draft.kind == EntryKind.question ? QuestionState.open : null,
        fileIds: draft.fileIds,
      );

      return _commit(actor, EntryAdd(entry));
    });
  }

  /// Any role. Summarises diary entries only, never guide notes, and
  /// credits the result to AI.
  Future<PocketState?> refreshHandover() {
    return _step(() async {
      final held = await _hold(Gate.any);

      if (held == null) {
        return null;
      }

      final text = await _model.summariseDiary(held.state.entries);

      return _commit(held.actor!, HandoverSet(text, const HandoverBy.ai()));
    });
  }

  /// Owner only. Kind, author, and time stay.
  Future<PocketState?> editEntry(String id, String body) {
    return _owner(EntryEdit(id, body.trim()));
  }

  /// Owner only.
  Future<PocketState?> removeEntry(String id) {
    return _owner(EntryRemove(id));
  }

  /// Owner only. Resolving is the owner's approval.
  Future<PocketState?> resolveQuestion(String id) {
    return _owner(QuestionResolve(id));
  }

  /// Owner or family. Replaces the answer and the photo of one prompt.
  Future<PocketState?> saveAnswer(String id, String text, String? photoId) {
    return _step(() async {
      final held = await _hold(Gate.household);

      if (held == null) {
        return null;
      }

      return _commit(
        held.actor!,
        AnswerSave(id, text.trim(), photoId: photoId),
      );
    });
  }

  /// Any role. The line is signed, e.g. "Jordan: Coat by the door.". Null
  /// when the line is empty.
  Future<PocketState?> addObservation(String worksId, String text) {
    return _step(() async {
      final held = await _hold(Gate.any);
      final line = text.trim();

      if (held == null || line.isEmpty) {
        return null;
      }

      return _commit(
        held.actor!,
        ObservationAdd(worksId, '${held.actor!.name}: $line'),
      );
    });
  }

  /// Any role. Asks the model; stores nothing. Null when the card is gone.
  Future<String?> suggestPattern(String worksId) {
    return _step(() async {
      final held = await _hold(Gate.any);
      final card = held?.state.works.where((w) => w.id == worksId).firstOrNull;

      if (held == null || card == null) {
        return null;
      }

      return _model.suggestPattern(card, held.state.entries);
    });
  }

  /// Any role. Appends the person's question and the AI answer on care.
  Future<PocketState?> sendChat(String text) {
    return _step(() async {
      final held = await _hold(Gate.any);
      final trimmed = text.trim();

      if (held == null || trimmed.isEmpty) {
        return null;
      }

      final answer = await _model.answerCare(trimmed, held.state.entries);
      final first = stampNow(held.state.tick, _clock());
      final second = stampNow(first.tick, _clock());
      final actor = held.actor!;

      return _commit(
        actor,
        MessagesAdd([
          _personNote(Thread.care, actor.name, trimmed, first.when),
          Note(
            id: makeId('note', second.tick),
            thread: Thread.care,
            source: MessageSource.ai,
            author: 'Pocket',
            body: answer.body,
            when: second.when,
            known: answer.known,
            escalation: answer.known == Known.no ? Escalation.none : null,
            asked: trimmed,
            owner: null,
          ),
        ]),
      );
    });
  }

  /// Not the owner. Marks an unknown AI note sent and appends a human note
  /// addressed to [name] (Alex, Chris, …).
  Future<PocketState?> sendToPerson(String id, String name) {
    return _step(() async {
      final held = await _hold(Gate.any);
      final actor = held?.actor;

      if (held == null || actor == null || actor.role == Role.owner) {
        return null;
      }

      final note = held.state.messages.where((n) => n.id == id).firstOrNull;

      if (note == null ||
          note.asked == null ||
          note.known != Known.no ||
          note.escalation == Escalation.sent) {
        return _forCaller(actor, held.state);
      }

      final stamped = stampNow(held.state.tick, _clock());
      final message = _personNote(
        Thread.care,
        actor.name,
        'Asked $name: ${note.asked}',
        stamped.when,
      );

      return _commit(actor, MessageSent(id, message));
    });
  }

  /// Owner or family. Guide thread only; both notes carry [owner] = actor.
  /// Commits `messages.add` only — never an entry.
  Future<PocketState?> sendGuide(String text) {
    return _step(() async {
      final held = await _hold(Gate.household);
      final trimmed = text.trim();

      if (held == null || trimmed.isEmpty) {
        return null;
      }

      final actor = held.actor!;
      final spoken = held.state.messages
          .where(
            (n) =>
                n.thread == Thread.guide &&
                n.source == MessageSource.person &&
                n.owner == actor.name,
          )
          .length;

      // A handover starter gets a diary-ready draft; other lines rotate.
      final draft = trimmed == guideHandover;
      final reply = draft ? handoverDraft : await _model.guideReply(spoken);
      final first = stampNow(held.state.tick, _clock());
      final second = stampNow(first.tick, _clock());

      return _commit(
        actor,
        MessagesAdd([
          _personNote(
            Thread.guide,
            actor.name,
            trimmed,
            first.when,
            owner: actor.name,
          ),
          Note(
            id: makeId('note', second.tick),
            thread: Thread.guide,
            source: MessageSource.ai,
            author: 'Pocket',
            body: reply,
            when: second.when,
            known: null,
            escalation: null,
            asked: draft ? diaryDraftAsk : null,
            owner: actor.name,
          ),
        ]),
      );
    });
  }

  /// Owner or family. After confirm: one diary entry from the draft body.
  /// The guide thread keeps every note.
  Future<PocketState?> saveDraft(String noteId) {
    return _step(() async {
      final held = await _hold(Gate.household);

      if (held == null) {
        return null;
      }

      final note = held.state.messages.where((n) => n.id == noteId).firstOrNull;

      if (note == null || !isDiaryDraft(note)) {
        return null;
      }

      final actor = held.actor!;
      final stamp = stampNow(held.state.tick, _clock());
      final entry = DiaryEntry(
        id: makeId('entry', stamp.tick),
        kind: EntryKind.general,
        body: note.body,
        authorName: actor.name,
        authorRole: actor.role,
        when: stamp.when,
        attachment: Attachment.none,
        voice: VoiceNote.none,
        question: null,
        fileIds: const [],
      );

      return _commit(actor, EntryAdd(entry));
    });
  }

  /// Owner or family. One acceptor; a taken request keeps its first name.
  Future<PocketState?> acceptHelp(String id) {
    return _step(() async {
      final held = await _hold(Gate.household);

      if (held == null) {
        return null;
      }

      final actor = held.actor!;

      return _commit(actor, HelpAccept(id, actor.name));
    });
  }

  /// Owner. Posts one of the three fixed sentences, or no-ops if still open.
  Future<PocketState?> postRequest(RequestKind kind) {
    return _step(() async {
      final held = await _hold(Gate.owner);

      if (held == null) {
        return null;
      }

      final open = held.state.requests.any(
        (r) => r.kind == kind && r.acceptedBy == null && r.appointmentId == null,
      );

      if (open) {
        return _forCaller(held.actor, held.state);
      }

      final stamp = stampNow(held.state.tick, _clock());

      return _commit(
        held.actor!,
        HelpPost(
          HelpRequest(
            id: makeId('help', stamp.tick),
            kind: kind,
            text: requestText(kind),
            acceptedBy: null,
            appointmentId: null,
          ),
        ),
      );
    });
  }

  /// Owner. Lift request linked to one appointment.
  Future<PocketState?> askFamilyHelp(String appointmentId) {
    return _step(() async {
      final held = await _hold(Gate.owner);

      if (held == null) {
        return null;
      }

      final item = held.state.appointments
          .where((a) => a.id == appointmentId)
          .firstOrNull;

      if (item == null || item.volunteer != null) {
        return _forCaller(held.actor, held.state);
      }

      final linked = held.state.requests.any(
        (r) => r.appointmentId == appointmentId && r.acceptedBy == null,
      );

      if (linked) {
        return _forCaller(held.actor, held.state);
      }

      final stamp = stampNow(held.state.tick, _clock());

      return _commit(
        held.actor!,
        HelpPost(
          HelpRequest(
            id: makeId('help', stamp.tick),
            kind: RequestKind.appointment,
            text: appointmentHelpText(item, _clock()),
            acceptedBy: null,
            appointmentId: appointmentId,
          ),
        ),
      );
    });
  }

  /// Owner drops a request, open or accepted.
  Future<PocketState?> removeRequest(String id) {
    return _owner(RequestRemove(id));
  }

  /// Owner or family. Stores the appointment; no calendar booking.
  Future<PocketState?> addAppointment({
    required When when,
    required String place,
    required String reason,
    required String transport,
    required String notes,
  }) {
    return _step(() async {
      final held = await _hold(Gate.household);
      final trimmedPlace = place.trim();
      final trimmedReason = reason.trim();

      if (held == null || trimmedPlace.isEmpty || trimmedReason.isEmpty) {
        return null;
      }

      final stamp = stampNow(held.state.tick, _clock());
      // Keep the chosen day/time; only seq comes from the stamp.
      final at = When(
        dayOffset: when.dayOffset,
        hour: when.hour,
        minute: when.minute,
        seq: stamp.tick,
      );

      return _commit(
        held.actor!,
        AppointmentAdd(
          Appointment(
            id: makeId('appt', stamp.tick),
            when: at,
            place: trimmedPlace,
            reason: trimmedReason,
            transport: transport.trim(),
            notes: notes.trim(),
            reminder: Reminder.off,
            volunteer: null,
          ),
        ),
      );
    });
  }

  /// Owner or family. Flips the flag and tells NotifyPort (no OS prompt).
  Future<PocketState?> toggleReminder(String id) {
    return _step(() async {
      final held = await _hold(Gate.household);

      if (held == null) {
        return null;
      }

      final item = held.state.appointments.where((a) => a.id == id).firstOrNull;

      if (item == null) {
        return _forCaller(held.actor, held.state);
      }

      final next = item.reminder == Reminder.on ? Reminder.off : Reminder.on;
      await _notify.set(id, item.when, next);

      return _commit(held.actor!, ReminderSet(id, next));
    });
  }

  /// Owner or family. First volunteer wins.
  Future<PocketState?> volunteer(String id) {
    return _step(() async {
      final held = await _hold(Gate.household);

      if (held == null) {
        return null;
      }

      return _commit(held.actor!, VolunteerSet(id, held.actor!.name));
    });
  }

  /// Owner or family. Summarises the text (or names the attached file).
  Future<PocketState?> addReport({
    required String title,
    required String author,
    required String note,
    required String original,
    String? fileId,
  }) {
    return _step(() async {
      final held = await _hold(Gate.household);
      final trimmedTitle = title.trim();
      final trimmedOriginal = original.trim();

      if (held == null || trimmedTitle.isEmpty) {
        return null;
      }

      // Save needs a title and either pasted text or a file.
      if (trimmedOriginal.isEmpty && fileId == null) {
        return null;
      }

      final summary = trimmedOriginal.isEmpty
          ? _fileOnlySummary
          : await _model.summariseReport(trimmedOriginal);
      final stamp = stampNow(held.state.tick, _clock());

      return _commit(
        held.actor!,
        ReportAdd(
          Report(
            id: makeId('report', stamp.tick),
            when: stamp.when,
            author: author.trim().isEmpty ? _unnamedAuthor : author.trim(),
            title: trimmedTitle,
            note: note.trim(),
            original: trimmedOriginal,
            summary: summary,
            fileId: fileId,
          ),
        ),
      );
    });
  }

  /// Any role. The composer stores a photo as soon as it is picked.
  Future<StoredFile?> storeFile(FileKind kind, String label, Uint8List bytes) {
    return _step(() async {
      final held = await _hold(Gate.any);

      if (held == null) {
        return null;
      }

      return _files.put(kind, label, bytes);
    });
  }

  /// Any role. Null when the file is missing or nobody is signed in.
  Future<Uint8List?> readFile(String id) async {
    if (await _auth.current() == null) {
      return null;
    }

    return _files.read(id);
  }

  Future<PocketState?> _owner(CareCommand command) {
    return _step(() async {
      final held = await _hold(Gate.owner);

      if (held == null) {
        return null;
      }

      return _commit(held.actor!, command);
    });
  }

  Future<Held?> _hold(Gate gate) async {
    final actor = await _auth.current();

    if (actor == null || !_passes(actor, gate)) {
      return null;
    }

    // Raw household record; guide filtering happens on the way out.
    return (actor: actor, state: await _records.load());
  }

  Future<PocketState> _commit(Actor actor, CareCommand command) async {
    return _forCaller(actor, await _records.commit(command));
  }

  // Each person only sees their own guide notes. Staff see none.
  PocketState _forCaller(Actor? actor, PocketState state) {
    final messages = [
      for (final note in state.messages)
        if (note.thread != Thread.guide)
          note
        else if (actor != null &&
            actor.role != Role.staff &&
            note.owner == actor.name)
          note,
    ];

    return state.copyWith(messages: messages);
  }

  Note _personNote(
    Thread thread,
    String author,
    String body,
    When when, {
    String? owner,
  }) {
    return Note(
      id: makeId('note', when.seq),
      thread: thread,
      source: MessageSource.person,
      author: author,
      body: body,
      when: when,
      known: null,
      escalation: null,
      asked: null,
      owner: owner,
    );
  }

  bool _passes(Actor actor, Gate gate) {
    return switch (gate) {
      Gate.any => true,
      Gate.household => actor.role != Role.staff,
      Gate.owner => actor.role == Role.owner,
    };
  }

  // A failed step still releases the tail for the next one.
  Future<T> _step<T>(Future<T> Function() work) {
    final run = _tail.then((_) => work());
    _tail = run.then((_) {}, onError: (Object _) {});

    return run;
  }
}
