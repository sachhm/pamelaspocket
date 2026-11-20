import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/auth.dart';
import '../../domain/enums.dart';
import '../../domain/time.dart';
import '../../session/pocket_scope.dart';
import '../../ui/flush_button.dart';
import '../../ui/paths.dart';
import '../../ui/role_label.dart';
import '../../ui/section_block.dart';

const _revokeAsk =
    'Turn the PIN off? Every support worker will need a new code to get in.';

/// Who is on this device, owner access controls, reports, then sign out.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PocketScope.of(context);
    final actor = scope.actor;
    final state = scope.state;
    final theme = Theme.of(context);

    if (actor == null || state == null) {
      return const SizedBox.shrink();
    }

    final staff = actor.role == Role.staff;
    final owner = actor.role == Role.owner;
    final reports = [...state.reports]
      ..sort((a, b) => compareWritten(b.when, a.when));
    final family = state.people.where((p) => p.role == Role.family);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(actor.name, style: theme.textTheme.titleLarge),
                Text(
                  roleLabel(actor.role),
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          if (owner) ...[
            SectionBlock(
              tone: SectionTone.list,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Staff PIN', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Staff pick their name, then enter this PIN.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  const _PinReveal(),
                  const SizedBox(height: 4),
                  Text(
                    'Press and hold to show.',
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.access == AccessState.active
                        ? 'Access is on.'
                        : 'Access is off. The PIN will be refused.',
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      style: state.access == AccessState.active
                          ? flushDanger
                          : flushButton,
                      onPressed: () => state.access == AccessState.active
                          ? _confirmRevoke(context, scope)
                          : scope.setAccess(AccessState.active),
                      child: Text(
                        state.access == AccessState.active
                            ? 'Turn off access'
                            : 'Turn access back on',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SectionBlock(
              tone: SectionTone.list,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Family', style: theme.textTheme.titleMedium),
                  for (final person in family)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(person.name),
                      value: person.access == AccessState.active,
                      onChanged: (on) => on
                          ? scope.setMember(person.name, AccessState.active)
                          : _confirmFamilyOff(context, scope, person.name),
                    ),
                ],
              ),
            ),
          ],

          // Owner and family keep the report folder here; staff do not.
          if (!staff)
            SectionBlock(
              tone: SectionTone.list,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Reports', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      style: flushButton,
                      onPressed: () => context.push(Paths.reportNew),
                      child: const Text('Add a report'),
                    ),
                  ),
                  if (reports.isEmpty)
                    Text(
                      'No reports yet.',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    for (final report in reports) ...[
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(report.title),
                        subtitle: Text(
                          '${report.author} · ${formatWhen(report.when, DateTime.now())}'
                          '${report.note.isEmpty ? '' : '\n${report.note}'}',
                        ),
                        onTap: () => context.push(Paths.reportOf(report.id)),
                      ),
                    ],
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    style: flushButton,
                    onPressed: scope.signOut,
                    child: const Text('Sign out'),
                  ),
                ),

                // Debug builds only: jump roles without a password.
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text('View as', style: theme.textTheme.titleMedium),
                  for (final role in Role.values)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        style: flushButton,
                        onPressed: () => scope.previewAs(role),
                        child: Text(roleLabel(role)),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRevoke(BuildContext context, PocketScope scope) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text(_revokeAsk),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: dangerButton,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Turn off'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await scope.setAccess(AccessState.revoked);
    }
  }

  Future<void> _confirmFamilyOff(
    BuildContext context,
    PocketScope scope,
    String name,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text('Turn off $name’s access?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: dangerButton,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Turn off'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await scope.setMember(name, AccessState.revoked);
    }
  }
}

/// Four dots; press and hold to read the demo digits.
class _PinReveal extends StatefulWidget {
  const _PinReveal();

  @override
  State<_PinReveal> createState() => _PinRevealState();
}

class _PinRevealState extends State<_PinReveal> {
  bool _held = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brown = theme.colorScheme.primary;

    return GestureDetector(
      onLongPressStart: (_) => setState(() => _held = true),
      onLongPressEnd: (_) => setState(() => _held = false),
      onLongPressCancel: () => setState(() => _held = false),
      child: Semantics(
        label: _held ? 'PIN $demoPin' : 'PIN hidden. Press and hold to reveal.',
        child: Text(
          _held ? demoPin : '••••',
          style: theme.textTheme.headlineSmall!.copyWith(
            color: brown,
            letterSpacing: _held ? 4 : 8,
          ),
        ),
      ),
    );
  }
}
