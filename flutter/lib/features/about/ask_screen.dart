import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/enums.dart';
import '../../domain/records.dart';
import '../../domain/story.dart';
import '../../session/pocket_scope.dart';
import '../../ui/busy_label.dart';
import '../../ui/field_error.dart';
import '../../ui/paths.dart';
import '../../ui/photo_picker.dart';
import '../../ui/stored_photo.dart';

const _failed = 'The care service did not answer.';
const _answerLines = 4;

/// One prompt, one field. A life prompt may also keep a photo.
///
///   Where did Pamela grow up?
///   ┌ Answer ──────────────────┐
///   └──────────────────────────┘
///   [Add photo]                     ← life prompts only
///   ─────────────────────────────
///   [            Save          ]
class AskScreen extends StatefulWidget {
  const AskScreen({super.key, this.id});

  /// The prompt to answer. Null opens the next one in the story.
  final String? id;

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final _answer = TextEditingController();
  Prompt? _prompt;
  String? _photoId;
  Phase _photoPhase = Phase.idle;
  String? _photoError;
  Phase _phase = Phase.idle;
  String? _error;

  // The prompt is fixed on open, so a save elsewhere cannot swap the
  // question under the person's typing.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_prompt != null) {
      return;
    }

    final prompts = PocketScope.of(context).state?.prompts ?? const [];
    final id = widget.id;
    final prompt = id == null
        ? (prompts.isEmpty ? null : nextAsk(prompts))
        : prompts.where((p) => p.id == id).firstOrNull;

    _prompt = prompt;
    _answer.text = prompt?.answer ?? '';
    _photoId = prompt?.photoId;
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prompt = _prompt;

    if (prompt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pamela’s story')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'That question is not in Pamela’s story.',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    final photo = _photoId;
    final empty = _answer.text.trim().isEmpty && photo == null;
    final idle = _phase == Phase.idle && _photoPhase == Phase.idle;

    return Scaffold(
      appBar: AppBar(title: const Text('Pamela’s story')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Semantics(
                  header: true,
                  child: Text(prompt.ask, style: theme.textTheme.titleLarge),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _answer,
                  autofocus: true,
                  minLines: _answerLines,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Answer',
                    alignLabelWithHint: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                if (prompt.section == StorySection.life) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilterChip(
                      // "Adding…" while the bytes are stored, so the wait
                      // is not a silent disabled chip.
                      label: Text(
                        _photoPhase == Phase.busy
                            ? 'Adding…'
                            : photo == null
                            ? 'Add photo'
                            : 'Photo added',
                      ),
                      selected: photo != null && _photoPhase == Phase.idle,
                      onSelected: _photoPhase == Phase.idle
                          ? (_) => _togglePhoto()
                          : null,
                    ),
                  ),
                  if (photo != null) ...[
                    const SizedBox(height: 12),
                    StoredPhoto(
                      key: ValueKey(photo),
                      id: photo,
                      label: 'Photo with this memory',
                      size: PhotoSize.thumb,
                    ),
                  ],
                  if (_photoError case final error?) ...[
                    const SizedBox(height: 12),
                    FieldError(error),
                  ],
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
    );
  }

  // Picks and stores at once. Cancel leaves the chip as it was; tapping
  // "Photo added" takes the photo off this prompt.
  Future<void> _togglePhoto() async {
    if (_photoId != null) {
      setState(() => _photoId = null);
      return;
    }

    setState(() {
      _photoPhase = Phase.busy;
      _photoError = null;
    });

    final scope = _scope;
    String? id;
    String? error;

    try {
      final bytes = await pickPhoto();
      id = bytes == null ? null : await scope.storePhoto(bytes);
    } on Object {
      error = _failed;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _photoPhase = Phase.idle;
      _photoId = id;
      _photoError = error;
    });
  }

  // Stays open until the commit succeeds; a failure keeps the answer.
  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _phase = Phase.busy;
      _error = null;
    });

    try {
      await _scope.saveAnswer(_prompt!.id, _answer.text, _photoId);
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

    // pop() stays here after the diary write refreshes the router.
    context.go(Paths.about);
  }

  PocketScope get _scope => PocketScope.of(context);
}
