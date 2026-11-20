import 'package:flutter/material.dart';

import '../domain/records.dart';
import 'role_label.dart';

const _avatar = 32.0;
const _minTarget = 48.0;

// Material caps the app bar title near this scale; the chip follows so it
// never dwarfs the title at large text sizes.
const _chromeScale = 1.34;

/// App bar chip: initial in a petal circle, then the first name. Opens More.
/// Reads as "Signed in as Jordan, support worker".
class NameChip extends StatelessWidget {
  const NameChip({super.key, required this.actor, required this.onTap});

  final Actor actor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = theme.textTheme.labelLarge;
    final name = actor.name.split(' ').first;
    final role = roleLabel(actor.role).toLowerCase();

    return Semantics(
      button: true,
      label: 'Signed in as $name, $role',
      excludeSemantics: true,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: _chromeScale,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _minTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: _avatar / 2,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(name.characters.first, style: label),
                  ),
                  const SizedBox(width: 8),
                  Text(name, style: label),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
