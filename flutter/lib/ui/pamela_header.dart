import 'package:flutter/material.dart';

import '../domain/time.dart';

const _avatar = 56.0;

/// Today's large title: Pamela's avatar, her name, and the date. It sits at
/// the top of the list, so it follows the reading size and scrolls away.
///
///   ( P )  Pamela
///          Sunday 15 November
class PamelaHeader extends StatelessWidget {
  const PamelaHeader({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    // Top-aligned, so the avatar stays beside her name when the date wraps.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Decorative: her name sits beside it. The initial keeps the circle's
        // size, or it spills out at large text.
        ExcludeSemantics(
          child: MediaQuery.withNoTextScaling(
            child: CircleAvatar(
              radius: _avatar / 2,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(name.characters.first, style: text.headlineSmall),
            ),
          ),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // One word never breaks mid-name; it shrinks only past the row.
              Semantics(
                header: true,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(name, style: text.displaySmall),
                ),
              ),
              Text(
                formatDay(DateTime.now()),
                style: text.bodyMedium!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
