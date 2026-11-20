import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/auth.dart';
import '../../domain/enums.dart';
import '../../session/pocket_scope.dart';
import '../../ui/busy_label.dart';
import '../../ui/field_error.dart';

const _wrong = 'That PIN is not right.';
const _revoked = 'This code has been turned off.';
const _noAnswer = 'The sign-in service did not answer.';

final _digit = RegExp(r'^[0-9]$');

const _dot = 16.0;
const _keyHeight = 64.0;

// A digit lands in its ring. Reduced motion fades the fill and skips the scale.
const _land = Duration(milliseconds: 160);
const _fillFrom = 0.45;
const _landCurve = Cubic(0.16, 1, 0.3, 1);

/// Staff entry: pick your name, then the code the main carer showed you.
/// The pad stays off until a name is picked. The fourth digit submits.
///
///   The main carer shows you a four-digit code.
///   Who are you?   [Jordan] [Sam]
///        ● ● ○ ○
///   pad…
class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String? _name;
  String _pin = '';
  String? _error;
  Phase _phase = Phase.idle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Support worker')),
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        // The pad stays on screen. The question scrolls when text is large.
        child: Column(
          children: [
            Expanded(
              child: ListView(
                // Names stay built when text is large, so they can be scrolled to.
                cacheExtent: 2000,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  Text(
                    'The main carer shows you a four-digit code.',
                    style: text.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    header: true,
                    child: Text('Who are you?', style: text.titleLarge),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final name in staffNames)
                        ChoiceChip(
                          label: Text(name),
                          selected: _name == name,
                          onSelected: (_) => setState(() => _name = name),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Dots and a wrong-code line stay above the keys, not under the fold.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: _keyHeight / 2),
                child: Center(
                  child: switch (_error) {
                    final error? => FieldError(error),
                    null => _Dots(entered: _pin.length),
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _Pad(onKey: _ready ? _press : null),
            ),
          ],
        ),
      ),
    );
  }

  bool get _ready => _name != null && _phase == Phase.idle;

  // Hardware keyboards (web demo): digits type, Backspace deletes.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || !_ready) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _press(_Pad.delete);
      return KeyEventResult.handled;
    }

    final char = event.character;
    if (char == null || !_digit.hasMatch(char)) {
      return KeyEventResult.ignored;
    }

    _press(char);
    return KeyEventResult.handled;
  }

  // Digits append; Delete trims. Typing again clears a shown error.
  void _press(String key) {
    if (key == _Pad.delete) {
      if (_pin.isEmpty) {
        return;
      }

      _tick(_Tick.digit);
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
      return;
    }

    if (_pin.length >= pinLength) {
      return;
    }

    _tick(_Tick.digit);
    setState(() {
      _error = null;
      _pin += key;
    });

    if (_pin.length == pinLength) {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _phase = Phase.busy);

    String? error;

    try {
      final result = await PocketScope.of(context).enterStaff(_pin, _name!);
      error = switch (result) {
        PinResult.ok => null,
        PinResult.wrong => _wrong,
        PinResult.revoked => _revoked,
      };
    } on Object {
      error = _noAnswer;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _phase = Phase.idle;
      _pin = '';
      _error = error;
    });

    // A wrong code answers in the hand. Success leaves for Today.
    if (error != null) {
      _tick(_Tick.reject);
    }
  }
}

enum _Tick { digit, reject }

// The keypad tick. Tests and the web column have no haptic engine.
void _tick(_Tick kind) {
  final Future<void> played = switch (kind) {
    _Tick.digit => HapticFeedback.selectionClick(),
    _Tick.reject => HapticFeedback.lightImpact(),
  };

  played.then<void>((_) {}, onError: (Object _) {});
}

/// Four dots, filled as digits arrive. Reads as "2 of 4 digits entered".
class _Dots extends StatelessWidget {
  const _Dots({required this.entered});

  final int entered;

  @override
  Widget build(BuildContext context) {
    final brown = Theme.of(context).colorScheme.primary;

    return Semantics(
      label: '$entered of $pinLength digits entered',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < pinLength; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _Dot(filled: i < entered, color: brown),
            ),
        ],
      ),
    );
  }
}

/// The fill grows into the ring. The ring stays put, so the row does not jump.
class _Dot extends StatelessWidget {
  const _Dot({required this.filled, required this.color});

  final bool filled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final calm = MediaQuery.disableAnimationsOf(context);

    return SizedBox(
      width: _dot,
      height: _dot,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: filled ? 1 : 0,
              duration: _land,
              curve: _landCurve,
              child: AnimatedScale(
                // Reduced motion holds the fill at full size and fades it.
                scale: calm ? 1 : (filled ? 1 : _fillFrom),
                duration: calm ? Duration.zero : _land,
                curve: _landCurve,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Phone-style keypad. A null [onKey] disables every key.
class _Pad extends StatelessWidget {
  const _Pad({required this.onKey});

  static const delete = 'Delete';
  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', delete],
  ];

  final ValueChanged<String>? onKey;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium;

    return Column(
      children: [
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: key.isEmpty
                          ? const SizedBox(height: _keyHeight)
                          : _key(key, style),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _key(String key, TextStyle? style) {
    final press = onKey;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(_keyHeight),
        textStyle: style,
      ),
      onPressed: press == null ? null : () => press(key),

      // Shrinks rather than breaking "Delete" mid-word at large text sizes.
      child: FittedBox(fit: BoxFit.scaleDown, child: Text(key)),
    );
  }
}
