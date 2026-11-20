import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ui/paths.dart';

const _avatar = 56.0;
const _rowHeight = 72.0;

/// First screen when signed out: who is Pamela to you? No form here.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar is decorative: her name sits beside it.
              Row(
                children: [
                  ExcludeSemantics(
                    child: CircleAvatar(
                      radius: _avatar / 2,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text('P', style: text.headlineSmall),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Semantics(
                      header: true,
                      // Shrinks rather than breaking her name at large sizes.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text('Pamela', style: text.displaySmall),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'A shared diary for the people who look after her.',
                style: text.bodyLarge,
              ),
              const SizedBox(height: 32),

              _PathRow(
                label: 'I’m Pamela’s main carer',
                onTap: () => context.push('${Paths.signIn}?role=owner'),
              ),
              const Divider(),
              _PathRow(
                label: 'I’m family',
                onTap: () => context.push('${Paths.signIn}?role=family'),
              ),
              const Divider(),
              _PathRow(
                label: 'I’m a support worker',
                onTap: () => context.push(Paths.pin),
              ),
              const SizedBox(height: 8),
              Text(
                'The main carer gives you a four-digit code.',
                style: text.bodyMedium!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One large tappable path off Welcome.
class _PathRow extends StatelessWidget {
  const _PathRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: _rowHeight,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: Theme.of(context).textTheme.titleMedium),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.secondary,
      ),
      onTap: onTap,
    );
  }
}
