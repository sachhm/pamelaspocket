import 'package:flutter/material.dart';

/// Placeholder body for a tab whose content lands in a later slice.
class TabStub extends StatelessWidget {
  const TabStub({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [Text(text, style: Theme.of(context).textTheme.bodyLarge)],
    );
  }
}
