import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/enums.dart';
import '../../domain/records.dart';
import '../../domain/story.dart';
import '../../session/pocket_scope.dart';
import '../../ui/busy_label.dart';
import '../../ui/field_error.dart';
import '../../ui/flush_button.dart';
import '../../ui/paths.dart';
import '../../ui/photo_picker.dart';
import '../../ui/stored_photo.dart';

const _failed = 'The care service did not answer.';
const _answerLines = 4;

/// First-run life walk. Later finishes onboarding; empty list leaves to Today.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _answer = TextEditingController();
  int _index = 0;
  String? _photoId;
  Phase _photoPhase = Phase.idle;
  Phase _phase = Phase.idle;
  String? _error;
  var _primed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_primed) {
      return;
    }

    final prompts = PocketScope.of(context).state?.prompts;
    if (prompts == null) {
      return;
    }

    final life = lifePrompts(prompts);
    _primed = true;

    if (life.isNotEmpty) {
      _load(life[_index]);
    }
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = PocketScope.of(context);
    final state = scope.state;
    final theme = Theme.of(context);

    if (state == null) {
      return const SizedBox.shrink();
    }

    final life = lifePrompts(state.prompts);

    // Router should keep us here only while pending; bail if the flag flipped.
    if (state.onboarded != Onboarding.pending || life.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(Paths.today);
        }
      });

      return const Scaffold(body: SizedBox.shrink());
    }

    if (_index >= life.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish(scope));

      return const Scaffold(body: SizedBox.shrink());
    }

    final prompt = life[_index];
    final idle = _phase == Phase.idle && _photoPhase == Phase.idle;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pamela’s story'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_index == 0) {
              _later(scope);
              return;
            }

            setState(() {
              _index -= 1;
              _load(life[_index]);
            });
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '${_index + 1} of ${life.length}',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Text(prompt.ask, style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: _answer,
                  minLines: _answerLines,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Answer',
                    alignLabelWithHint: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    style: flushButton,
                    onPressed: idle ? _togglePhoto : null,
                    child: BusyLabel(
                      _photoId == null ? 'Add photo' : 'Remove photo',
                      phase: _photoPhase,
                    ),
                  ),
                ),
                if (_photoId case final id?) ...[
                  const SizedBox(height: 8),
                  StoredPhoto(
                    id: id,
                    label: 'Photo for this answer',
                    size: PhotoSize.thumb,
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: idle ? () => _saveNext(scope, life) : null,
                    child: BusyLabel('Save and next', phase: _phase),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: idle ? () => _skip(life) : null,
                    child: const Text('Skip'),
                  ),
                  TextButton(
                    onPressed: idle ? () => _later(scope) : null,
                    child: const Text('Later'),
                  ),
                  TextButton(
                    onPressed: idle
                        ? () => context.go(Paths.more)
                        : null,
                    child: const Text('Show the QR'),
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

  void _load(Prompt prompt) {
    _answer.text = prompt.answer;
    _photoId = prompt.photoId;
    _error = null;
  }

  Future<void> _togglePhoto() async {
    if (_photoId != null) {
      setState(() => _photoId = null);
      return;
    }

    setState(() => _photoPhase = Phase.busy);
    final scope = PocketScope.of(context);

    try {
      final bytes = await pickPhoto();
      final id = bytes == null ? null : await scope.storePhoto(bytes);

      if (!mounted) {
        return;
      }

      setState(() {
        _photoPhase = Phase.idle;
        _photoId = id;
      });
    } on Object {
      if (!mounted) {
        return;
      }

      setState(() {
        _photoPhase = Phase.idle;
        _error = _failed;
      });
    }
  }

  Future<void> _saveNext(PocketScope scope, List<Prompt> life) async {
    final prompt = life[_index];

    setState(() {
      _phase = Phase.busy;
      _error = null;
    });

    try {
      await scope.saveAnswer(prompt.id, _answer.text, _photoId);
    } on Object {
      if (!mounted) {
        return;
      }

      setState(() {
        _phase = Phase.idle;
        _error = _failed;
      });
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() => _phase = Phase.idle);
    await _advance(scope, life);
  }

  Future<void> _skip(List<Prompt> life) async {
    await _advance(PocketScope.of(context), life);
  }

  Future<void> _advance(PocketScope scope, List<Prompt> life) async {
    if (_index >= life.length - 1) {
      await _finish(scope);
      return;
    }

    setState(() {
      _index += 1;
      _load(life[_index]);
    });
  }

  Future<void> _later(PocketScope scope) async {
    await _finish(scope);
  }

  Future<void> _finish(PocketScope scope) async {
    await scope.finishOnboarding();

    if (!mounted) {
      return;
    }

    context.go(Paths.today);
  }
}
