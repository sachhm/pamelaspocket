import 'package:flutter/material.dart';

/// Paper motion. Two moves:
///
///   ink rewritten in place        a new slip set down
///   ┌────────────────────┐        ┌────────────────────┐
///   │ old line           │        │                    │
///   │ new line    (fade) │        │  note ↓ 8px        │
///   └────────────────────┘        └────────────────────┘
///
/// Reduce Motion keeps the fade and drops the travel. No bounce:
/// a diary is a letter, not a toy.

const _inkTime = Duration(milliseconds: 220);
const _settleTime = Duration(milliseconds: 280);
const _calmTime = Duration(milliseconds: 150);

// Decelerates into place. The same arrival as a note being set down.
const _arrive = Cubic(0.16, 1, 0.3, 1);

// How far above its resting line a new slip starts.
const _lift = 8.0;

/// Held invisible under a covering page, then played once that page leaves.
enum SlipPhase { waiting, settling }

/// Crossfades [child] when [token] changes. The card keeps its place;
/// only the words move. The outgoing line is hidden from VoiceOver.
class InkSwap extends StatelessWidget {
  const InkSwap({super.key, required this.token, required this.child});

  final Object token;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final calm = MediaQuery.disableAnimationsOf(context);

    return AnimatedSwitcher(
      duration: calm ? _calmTime : _inkTime,
      switchInCurve: _arrive,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: _stackInk,
      child: KeyedSubtree(key: ValueKey<Object>(token), child: child),
    );
  }
}

Widget _stackInk(Widget? current, List<Widget> previous) {
  return Stack(
    alignment: Alignment.topLeft,
    children: [
      for (final outgoing in previous) ExcludeSemantics(child: outgoing),
      ?current,
    ],
  );
}

/// A new slip fades in and drops [_lift] px onto its line.
/// [SlipPhase.waiting] holds it blank so the move plays in view,
/// not under the page that covered it.
class PaperSlip extends StatefulWidget {
  const PaperSlip({super.key, required this.phase, required this.child});

  final SlipPhase phase;
  final Widget child;

  @override
  State<PaperSlip> createState() => _PaperSlipState();
}

class _PaperSlipState extends State<PaperSlip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  var _calm = false;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(vsync: this, duration: _settleTime);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calm = MediaQuery.disableAnimationsOf(context);
    _motion.duration = _calm ? _calmTime : _settleTime;
    _kick();
  }

  @override
  void didUpdateWidget(PaperSlip old) {
    super.didUpdateWidget(old);
    _kick();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  // Play once. Waiting stays at the blank frame until the phase flips.
  void _kick() {
    if (widget.phase != SlipPhase.settling || _started) {
      return;
    }

    _started = true;
    _motion.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _motion,
      builder: (context, child) {
        final t = _arrive.transform(_motion.value);
        final dy = _calm ? 0.0 : (1 - t) * -_lift;

        return IgnorePointer(
          ignoring: widget.phase == SlipPhase.waiting,
          child: Opacity(
            opacity: t,
            child: Transform.translate(offset: Offset(0, dy), child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Ids present on the first frame stay put. An id that arrives later settles.
/// Used for a thread the person is already looking at.
class FreshSlips extends StatefulWidget {
  const FreshSlips({super.key, required this.ids, required this.item});

  final List<String> ids;
  final Widget Function(String id) item;

  @override
  State<FreshSlips> createState() => _FreshSlipsState();
}

class _FreshSlipsState extends State<FreshSlips> {
  final _known = <String>{};
  final _fresh = <String>{};

  @override
  void initState() {
    super.initState();
    _known.addAll(widget.ids);
  }

  @override
  void didUpdateWidget(FreshSlips old) {
    super.didUpdateWidget(old);

    for (final id in widget.ids) {
      if (_known.add(id)) {
        _fresh.add(id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final id in widget.ids) ...[const SizedBox(height: 12), _one(id)],
      ],
    );
  }

  Widget _one(String id) {
    final child = widget.item(id);

    if (!_fresh.contains(id)) {
      return child;
    }

    return PaperSlip(
      key: ValueKey<String>('slip-$id'),
      phase: SlipPhase.settling,
      child: child,
    );
  }
}
