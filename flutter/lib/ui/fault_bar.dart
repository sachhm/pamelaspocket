import 'package:flutter/material.dart';

import 'announced.dart';

const _edge = 4.0;

/// Shown under the app bar when a background call failed. "Try again"
/// re-runs that call; the bar goes when it succeeds.
class FaultBar extends StatelessWidget {
  const FaultBar({super.key, required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Announced(
      text: text,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          border: Border(
            left: BorderSide(color: scheme.tertiary, width: _edge),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}
