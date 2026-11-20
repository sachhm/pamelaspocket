import 'package:flutter/material.dart';

import 'announced.dart';

/// An error placed under the control it names: icon plus brown text,
/// announced to screen readers when it appears.
class FieldError extends StatelessWidget {
  const FieldError(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Announced(
      text: text,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scales with the text so it stays level with the first line.
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            applyTextScaling: true,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge!.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
