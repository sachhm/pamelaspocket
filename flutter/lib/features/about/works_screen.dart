import 'package:flutter/material.dart';

import '../../session/pocket_scope.dart';
import '../../ui/ai_chip.dart';
import '../../ui/announced.dart';
import '../../ui/busy_label.dart';
import '../../ui/fault_bar.dart';
import '../../ui/field_error.dart';

const _failed = 'The care service did not answer.';
const _lineLines = 4;
const _revealTime = Duration(milliseconds: 200);

/// One What Works card. The human lines are plain; only the suggestion,
/// which may quote nothing but Pamela's notes, is petal with the AI chip.
///
///   Becomes upset when someone uses their phone.
///   What helps / What does not help
///   Seen on a shift                 newest last
///   ░ • AI suggestion ░             absent while it is asked for
///   ┌ Add what worked ─────────┐
///   [            Add           ]
class WorksScreen extends StatefulWidget {
  const WorksScreen({super.key, required this.id});

  final String id;

  @override
  State<WorksScreen> createState() => _WorksScreenState();
}

class _WorksScreenState extends State<WorksScreen> {
  final _line = TextEditingController();
  final _fieldKey = GlobalKey();
  final _focus = FocusNode();
  Phase _phase = Phase.idle;
  String? _error;

  // Ask once the leaf is up; the suggestion is never stored on the card.
  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        PocketScope.of(context).suggestPattern(widget.id);
      }
    });
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _line.dispose();
    super.dispose();
  }

  // With the keyboard up the field can sit under the fold; bring it back.
  void _onFocus() {
    if (_focus.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealField());
    }
  }

  void _revealField() {
    final field = _fieldKey.currentContext;

    if (field == null) {
      return;
    }

    final calm = MediaQuery.disableAnimationsOf(context);

    Scrollable.ensureVisible(
      field,
      duration: calm ? Duration.zero : _revealTime,
      curve: Curves.easeOutCubic,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = PocketScope.of(context);
    final theme = Theme.of(context);
    final fault = scope.fault;
    final card = scope.state?.works.where((w) => w.id == widget.id).firstOrNull;

    if (card == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('What works')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'That note is not on Pamela’s list.',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    final pattern = scope.patternOf(card.id);
    final empty = _line.text.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('What works')),
      body: Column(
        children: [
          if (fault != null) FaultBar(text: fault, onRetry: scope.retry),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    card.situation,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 24),

                _Lines(label: 'What helps', lines: [card.helps]),
                const SizedBox(height: 16),
                _Lines(label: 'What does not help', lines: [card.hinders]),

                if (card.observations.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _Lines(label: 'Seen on a shift', lines: card.observations),
                ],

                if (pattern != null) ...[
                  const SizedBox(height: 24),
                  _Suggestion(pattern),
                ],

                const SizedBox(height: 24),
                TextField(
                  key: _fieldKey,
                  focusNode: _focus,
                  controller: _line,
                  minLines: _lineLines,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Add what worked',
                    hintText: 'What happened, and what helped?',
                    alignLabelWithHint: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),

          // Stays above the keyboard so Add is always one tap away.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: !empty && _phase == Phase.idle ? _add : null,
                    child: BusyLabel(
                      _error == null ? 'Add' : 'Try again',
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

  // Clears the field once the line is on the card; a failure keeps it.
  Future<void> _add() async {
    final scope = PocketScope.of(context);

    setState(() {
      _phase = Phase.busy;
      _error = null;
    });

    String? error;

    try {
      await scope.addObservation(widget.id, _line.text);
      _line.clear();
    } on Object {
      error = _failed;
    }

    if (mounted) {
      setState(() {
        _phase = Phase.idle;
        _error = error;
      });
    }
  }
}

/// An olive-ink label over the person-written lines it names.
class _Lines extends StatelessWidget {
  const _Lines({required this.label, required this.lines});

  final String label;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.labelMedium!.copyWith(color: ink)),
        for (final line in lines) ...[
          const SizedBox(height: 4),
          Text(line, style: text.bodyLarge),
        ],
      ],
    );
  }
}

/// Petal card: chip, the quoted sentence, and where it came from. Reads as
/// one node: "AI suggestion. Becomes upset… From Pamela's own notes…".
class _Suggestion extends StatelessWidget {
  const _Suggestion(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Speaks when the suggestion first lands; the card itself stays quiet
    // after that so the person can keep reading the human lines.
    return Announced(
      text: text,
      child: Card(
        color: theme.colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AiChip(AiLabel.suggestion, ground: ChipGround.petal),
                const SizedBox(height: 12),
                Text(text, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),
                Text(
                  'From Pamela’s own notes. Not a diagnosis.',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
