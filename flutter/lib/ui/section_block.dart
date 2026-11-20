import 'package:flutter/material.dart';

import '../theme/pocket_theme.dart';

const _inset = 16.0;

/// A note is one piece of prose. A list is repeating rows.
enum SectionTone { note, list }

/// A list that opens the screen has nothing above it to rule off.
enum SectionPlace { after, first }

/// Notes are a sand card, cut like the handover's petal card so their
/// edges line up. Lists stay on ivory under a rule.
///
///   ┌ petal card ┐
///   ┌ sand card  ┐
///   ─────────────
///     list rows
class SectionBlock extends StatelessWidget {
  const SectionBlock({
    super.key,
    required this.tone,
    required this.child,
    this.place = SectionPlace.after,
  });

  final SectionTone tone;
  final Widget child;
  final SectionPlace place;

  @override
  Widget build(BuildContext context) {
    return switch (tone) {
      SectionTone.note => _note(),
      SectionTone.list => _list(context),
    };
  }

  Widget _note() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_inset, 20, _inset, 0),
      child: Card(
        color: PocketTheme.group,
        child: Padding(
          padding: const EdgeInsets.all(_inset),
          child: child,
        ),
      ),
    );
  }

  // The rule sits above the heading, with more room above than below.
  Widget _list(BuildContext context) {
    if (place == SectionPlace.first) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _inset),
        child: child,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(_inset, 28, _inset, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
