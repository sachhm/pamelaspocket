import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../care/desk.dart';
import '../domain/copy.dart';
import '../domain/enums.dart';
import '../domain/records.dart';
import '../ports/scan_port.dart';

const _serviceDown = 'The care service did not answer.';
const _photoLabel = 'Photo';

/// The session widgets talk to. Created once at the root; it calls the desk
/// and nothing else.
///
/// Mutations return their failure to the screen that started them, so the
/// screen can keep its input. Background calls (load) set [fault] instead,
/// and [retry] re-runs the last one that failed.
class PocketScope extends ChangeNotifier {
  PocketScope(this._desk);

  final CareDesk _desk;

  // Its own notifier, so the router re-checks routes only when the person
  // changes, not on every diary write.
  final _who = ValueNotifier<Actor?>(null);
  PocketState? _state;
  String? _fault;
  Future<void> Function()? _retry;
  bool _refreshing = false;

  // The entry the latest successful add committed. Today settles that
  // row onto the page; other writes leave it alone.
  String? _addedId;

  // What Works suggestions by card id. Asked for, never stored on the card.
  final _patterns = <String, String>{};

  Actor? get actor => _who.value;

  /// Fires when someone signs in or out. The router listens to this.
  Listenable get who => _who;
  PocketState? get state => _state;
  String? get fault => _fault;

  /// True while the handover is being rewritten.
  bool get refreshing => _refreshing;

  /// Id of the diary entry the latest successful add committed.
  String? get addedEntryId => _addedId;

  /// The card's AI suggestion. Null while it is being asked for.
  String? patternOf(String worksId) => _patterns[worksId];

  static PocketScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PocketHost>()!.notifier!;
  }

  @override
  void dispose() {
    _who.dispose();
    super.dispose();
  }

  Future<void> load() {
    return _background(() async {
      final held = await _desk.load();
      _who.value = held.actor;
      _state = held.state;
    });
  }

  Future<void> retry() async {
    final again = _retry;

    if (again != null) {
      await again();
    }
  }

  Future<SignInResult> signIn(Role role, String email, String password) async {
    final outcome = await _desk.signIn(role, email, password);
    _enter(outcome.actor);

    return outcome.result;
  }

  Future<SignInResult> signUp(Role role, String email, String password) async {
    final outcome = await _desk.signUp(role, email, password);
    _enter(outcome.actor);

    return outcome.result;
  }

  Future<PinResult> enterStaff(String pin, String name) async {
    final outcome = await _desk.enterStaff(pin, name);
    _enter(outcome.actor);

    return outcome.result;
  }

  Future<void> previewAs(Role role) async {
    _enter(await _desk.previewAs(role));
  }

  // The diary stays on the device; only the actor goes.
  Future<void> signOut() async {
    await _desk.signOut();
    _who.value = null;
    notifyListeners();
  }

  Future<void> setAccess(AccessState access) async {
    _keep(await _desk.setAccess(access));
  }

  Future<void> setMember(String name, AccessState access) async {
    _keep(await _desk.setMember(name, access));
  }

  Future<void> finishOnboarding() async {
    _keep(await _desk.finishOnboarding());
  }

  Future<void> dismissStory() async {
    _keep(await _desk.dismissStory());
  }

  Future<({ScanStatus status, String? token})> scan() {
    return _desk.scan();
  }

  /// Throws when the save fails, so the composer keeps the text. The
  /// handover refresh runs after, in the background.
  Future<void> addEntry(NewEntry draft) async {
    final before = _state;
    final next = await _desk.addEntry(draft);

    _markAdded(before, next);
    _keep(next);
    unawaited(_refresh());
  }

  Future<void> editEntry(String id, String body) async {
    _keep(await _desk.editEntry(id, body));
    unawaited(_refresh());
  }

  Future<void> removeEntry(String id) async {
    _keep(await _desk.removeEntry(id));
    unawaited(_refresh());
  }

  Future<void> resolveQuestion(String id) async {
    _keep(await _desk.resolveQuestion(id));
  }

  /// Throws when the save fails, so the question keeps the answer.
  Future<void> saveAnswer(String id, String text, String? photoId) async {
    _keep(await _desk.saveAnswer(id, text, photoId));
  }

  /// Throws when the save fails. The old suggestion goes at once and a new
  /// one is asked for, because the new line may change it.
  Future<void> addObservation(String worksId, String text) async {
    final next = await _desk.addObservation(worksId, text);

    _patterns.remove(worksId);
    _keep(next);
    unawaited(suggestPattern(worksId));
  }

  /// A failure shows the fault bar; "Try again" asks again.
  Future<void> suggestPattern(String worksId) {
    return _background(() async {
      final text = await _desk.suggestPattern(worksId);

      if (text != null) {
        _patterns[worksId] = text;
      }
    });
  }

  /// Throws when send fails, so the composer keeps the text.
  Future<void> sendChat(String text) async {
    _keep(await _desk.sendChat(text));
  }

  /// Staff or family: send an unknown answer to [name].
  Future<void> sendToPerson(String id, String name) async {
    _keep(await _desk.sendToPerson(id, name));
  }

  /// Owner or family. Guide thread only.
  Future<void> sendGuide(String text) async {
    _keep(await _desk.sendGuide(text));
  }

  /// After confirm: one diary entry from a handover draft.
  Future<void> saveDraft(String noteId) async {
    final before = _state;
    final next = await _desk.saveDraft(noteId);

    _markAdded(before, next);
    _keep(next);
    unawaited(_refresh());
  }

  Future<void> acceptHelp(String id) async {
    _keep(await _desk.acceptHelp(id));
  }

  Future<void> postRequest(RequestKind kind) async {
    _keep(await _desk.postRequest(kind));
  }

  Future<void> askFamilyHelp(String appointmentId) async {
    _keep(await _desk.askFamilyHelp(appointmentId));
  }

  Future<void> removeRequest(String id) async {
    _keep(await _desk.removeRequest(id));
  }

  Future<void> addAppointment({
    required When when,
    required String place,
    required String reason,
    required String transport,
    required String notes,
  }) async {
    _keep(
      await _desk.addAppointment(
        when: when,
        place: place,
        reason: reason,
        transport: transport,
        notes: notes,
      ),
    );
  }

  Future<void> toggleReminder(String id) async {
    _keep(await _desk.toggleReminder(id));
  }

  Future<void> volunteer(String id) async {
    _keep(await _desk.volunteer(id));
  }

  /// Owner or family. Returns the new report id, or null when refused.
  Future<String?> addReport({
    required String title,
    required String author,
    required String note,
    required String original,
    String? fileId,
  }) async {
    final next = await _desk.addReport(
      title: title,
      author: author,
      note: note,
      original: original,
      fileId: fileId,
    );

    if (next == null) {
      return null;
    }

    _keep(next);

    return next.reports.first.id;
  }

  /// Stores a picked photo and returns its id. Throws when it fails.
  Future<String?> storePhoto(Uint8List bytes) async {
    final stored = await _desk.storeFile(FileKind.photo, _photoLabel, bytes);

    return stored?.id;
  }

  /// Stores a report attachment (PDF stand-in or photo) as a document file.
  Future<String?> storeDocument(String label, Uint8List bytes) async {
    final stored = await _desk.storeFile(FileKind.document, label, bytes);

    return stored?.id;
  }

  Future<Uint8List?> readFile(String id) {
    return _desk.readFile(id);
  }

  // Today keeps the old handover and reads "Updating…" while this runs.
  // A failure shows the fault bar; "Try again" re-runs it.
  Future<void> _refresh() {
    return _background(() async {
      _refreshing = true;
      notifyListeners();

      try {
        _keep(await _desk.refreshHandover());
      } finally {
        _refreshing = false;
      }
    });
  }

  void _enter(Actor? actor) {
    if (actor == null) {
      return;
    }

    _who.value = actor;
    notifyListeners();
  }

  // One new diary row means that note is the one to set down.
  void _markAdded(PocketState? before, PocketState? next) {
    if (next == null) {
      return;
    }

    final oldIds = before?.entries.map((entry) => entry.id).toSet() ?? {};
    final added = next.entries.where((entry) => !oldIds.contains(entry.id));

    if (added.length != 1) {
      return;
    }

    _addedId = added.first.id;
  }

  // Null means the desk's gate refused; there is nothing new to show.
  void _keep(PocketState? next) {
    if (next == null) {
      return;
    }

    _state = next;
    notifyListeners();
  }

  Future<void> _background(Future<void> Function() work) async {
    try {
      await work();
      _fault = null;
      _retry = null;
    } on Object {
      _fault = _serviceDown;
      _retry = () => _background(work);
    }

    notifyListeners();
  }
}

/// Hands [PocketScope] down the tree and rebuilds readers when it changes.
class PocketHost extends InheritedNotifier<PocketScope> {
  const PocketHost({
    super.key,
    required PocketScope scope,
    required super.child,
  }) : super(notifier: scope);
}
