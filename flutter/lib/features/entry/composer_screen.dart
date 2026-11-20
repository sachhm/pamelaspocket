import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/copy.dart';
import '../../domain/enums.dart';
import '../../domain/records.dart';
import '../../domain/time.dart';
import '../../session/pocket_scope.dart';
import '../../ui/busy_label.dart';
import '../../ui/entry_label.dart';
import '../../ui/field_error.dart';
import '../../ui/flush_button.dart';
import '../../ui/photo_picker.dart';

const _failed = 'The care service did not answer.';
const _saved = Duration(seconds: 4);
const _noteLines = 4;
const _thumb = 96.0;
const _thumbRadius = 12.0;
const _revealTime = Duration(milliseconds: 200);

/// New diary entry. The fastest path is type, Save.
///
///   Sample transcript              ← only while voice is on
///   ┌ Note ────────────────────┐
///   └──────────────────────────┘
///   [General] [Mood] [Important] [Question] [Moment]
///   [Add photo] [Voice note]
///   ─────────────────────────────
///   Saving as Jordan · 10:42 am
///   [            Save          ]
class ComposerScreen extends StatefulWidget {
  const ComposerScreen({super.key});

  @override
  State<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends State<ComposerScreen> {
  final _note = TextEditingController();
  final _noteKey = GlobalKey();
  final _thumbKey = GlobalKey();
  EntryKind _kind = EntryKind.general;
  VoiceNote _voice = VoiceNote.none;
  String? _photoId;
  Uint8List? _photoBytes;
  Phase _photoPhase = Phase.idle;
  String? _photoError;
  Phase _phase = Phase.idle;
  String? _error;
  // True after a successful commit so PopScope lets the route leave.
  bool _savedOk = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  NewEntry get _draft {
    final photo = _photoId;

    return (
      kind: _kind,
      body: _note.text,
      attachment: photo == null ? Attachment.none : Attachment.photo,
      voice: _voice,
      fileIds: [?photo],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = composeBody(_draft).isEmpty;
    final idle = _phase == Phase.idle && _photoPhase == Phase.idle;

    return PopScope(
      canPop: empty || _savedOk,
      onPopInvokedWithResult: (didPop, _) => _confirmLeave(didPop),
      child: Scaffold(
        appBar: AppBar(title: const Text('New update')),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Keyed so the voice toggle can scroll it back into view.
                  Column(
                    key: _noteKey,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_voice == VoiceNote.sample) ...[
                        Text(
                          'Sample transcript',
                          style: theme.textTheme.labelMedium!.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      TextField(
                        controller: _note,
                        autofocus: true,
                        minLines: _noteLines,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          hintText: 'What should the next person know?',
                          alignLabelWithHint: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final kind in EntryKind.values)
                        ChoiceChip(
                          label: Text(entryLabel(kind)),
                          selected: _kind == kind,
                          onSelected: (_) => setState(() => _kind = kind),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: Text(
                          _photoId == null ? 'Add photo' : 'Photo added',
                        ),
                        selected: _photoId != null,
                        onSelected: _photoPhase == Phase.idle
                            ? (_) => _togglePhoto()
                            : null,
                      ),
                      FilterChip(
                        label: Text(
                          _voice == VoiceNote.none
                              ? 'Voice note'
                              : 'Voice added',
                        ),
                        selected: _voice == VoiceNote.sample,
                        onSelected: (_) => _toggleVoice(),
                      ),
                    ],
                  ),
                  if (_photoBytes case final bytes?) ...[
                    const SizedBox(height: 12),
                    _thumbnail(bytes),
                  ],
                  if (_photoError case final error?) ...[
                    const SizedBox(height: 12),
                    FieldError(error),
                  ],
                ],
              ),
            ),

            // Stays above the keyboard so Save is always one tap away.
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _savingAs(),
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: !empty && idle ? _save : null,
                      child: BusyLabel(
                        _error == null ? 'Save' : 'Try again',
                        phase: _phase,
                      ),
                    ),
                    if (_error case final error?) ...[
                      const SizedBox(height: 12),
                      FieldError(error),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // "Saving as Jordan · 10:42 am". The desk stamps the real time on save.
  String _savingAs() {
    final name = PocketScope.of(context).actor?.name ?? '';
    final now = DateTime.now();
    final time = formatClock(
      When(dayOffset: 0, hour: now.hour, minute: now.minute, seq: 0),
    );

    return 'Saving as $name · $time';
  }

  // The picked photo at thumbnail size, so a wrong pick shows before Save.
  Widget _thumbnail(Uint8List bytes) {
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return Align(
      key: _thumbKey,
      alignment: AlignmentDirectional.centerStart,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_thumbRadius),
        child: Image.memory(
          bytes,
          height: _thumb,
          cacheHeight: (_thumb * dpr).round(),
          fit: BoxFit.cover,
          semanticLabel: 'Photo to add',
        ),
      ),
    );
  }

  // With the keyboard up most of the form is out of view; scroll to what
  // a chip just changed, e.g. the transcript or the new thumbnail.
  void _reveal(GlobalKey key) {
    final target = key.currentContext;

    if (target == null) {
      return;
    }

    final calm = MediaQuery.disableAnimationsOf(context);

    Scrollable.ensureVisible(
      target,
      duration: calm ? Duration.zero : _revealTime,
      curve: Curves.easeOutCubic,
    );
  }

  // Voice is a stand-in: it inserts the sample line, and removes it again.
  void _toggleVoice() {
    final on = _voice == VoiceNote.none;
    final typed = _note.text.replaceAll(sampleVoice, '').trim();
    var next = typed;

    if (on) {
      next = typed.isEmpty ? sampleVoice : '$typed\n\n$sampleVoice';
    }

    setState(() {
      _voice = on ? VoiceNote.sample : VoiceNote.none;
      _note.text = next;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(_noteKey));
  }

  // Picks and stores at once. Cancel leaves the chip off; a failure clears
  // it with a line under the chips, and the note can still be saved.
  Future<void> _togglePhoto() async {
    if (_photoId != null) {
      setState(() {
        _photoId = null;
        _photoBytes = null;
      });
      return;
    }

    setState(() {
      _photoPhase = Phase.busy;
      _photoError = null;
    });

    Uint8List? bytes;
    String? id;
    String? error;

    try {
      bytes = await pickPhoto();
      id = bytes == null ? null : await _scope.storePhoto(bytes);
    } on Object {
      error = _failed;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _photoPhase = Phase.idle;
      _photoId = id;
      _photoBytes = id == null ? null : bytes;
      _photoError = error;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(_thumbKey));
  }

  // Stays open until the commit succeeds; a failure keeps every field.
  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _phase = Phase.busy;
      _error = null;
    });

    try {
      await _scope.addEntry(_draft);
    } on Object {
      if (mounted) {
        setState(() {
          _phase = Phase.idle;
          _error = _failed;
        });
      }

      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Update saved'), duration: _saved),
    );

    // Allow PopScope on the next frame, then leave via go_router.
    setState(() => _savedOk = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.pop();
      }
    });
  }

  Future<void> _confirmLeave(bool didPop) async {
    if (didPop) {
      return;
    }

    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this update?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep writing'),
          ),
          TextButton(
            style: dangerButton,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (leave == true && mounted) {
      context.pop();
    }
  }

  PocketScope get _scope => PocketScope.of(context);
}
