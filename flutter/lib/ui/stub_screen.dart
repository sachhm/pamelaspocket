import 'package:flutter/material.dart';

/// Placeholder for a route whose screen lands in a later slice.
/// [onAction] adds one filled button, used for the temporary continue.
class StubScreen extends StatelessWidget {
  const StubScreen({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Coming in a later slice.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),

          if (onAction != null) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onAction,
              child: Text(actionLabel ?? 'Continue'),
            ),
          ],
        ],
      ),
    );
  }
}
