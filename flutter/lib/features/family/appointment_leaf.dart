import 'package:flutter/material.dart';

import '../../domain/enums.dart';
import '../../domain/time.dart';
import '../../session/pocket_scope.dart';
import '../../ui/flush_button.dart';

/// One appointment. Reminder, volunteer, and owner ask-for-lift.
class AppointmentLeaf extends StatelessWidget {
  const AppointmentLeaf({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final scope = PocketScope.of(context);
    final actor = scope.actor;
    final state = scope.state;
    final theme = Theme.of(context);

    if (actor == null || state == null) {
      return const SizedBox.shrink();
    }

    final item = state.appointments.where((a) => a.id == id).firstOrNull;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Appointment')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('That appointment is not on the list.'),
        ),
      );
    }

    final today = DateTime.now();
    final owner = actor.role == Role.owner;
    final reminderOn = item.reminder == Reminder.on;
    // Linked ask from this leaf, if the owner already posted one.
    final help = state.requests
        .where((r) => r.appointmentId == item.id)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(item.reason, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            formatWhen(item.when, today),
            style: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(item.place, style: theme.textTheme.bodyLarge),
          if (item.transport.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(item.transport, style: theme.textTheme.bodyLarge),
          ],
          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(item.notes, style: theme.textTheme.bodyLarge),
          ],
          const SizedBox(height: 24),
          if (item.volunteer != null)
            Text(
              '${item.volunteer} can help with the trip.',
              style: theme.textTheme.bodyLarge,
            )
          else
            FilledButton(
              onPressed: () => scope.volunteer(item.id),
              child: const Text('I can take Mum'),
            ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              reminderOn ? 'Reminder on' : 'Reminder off',
              style: theme.textTheme.bodyLarge,
            ),
            value: reminderOn,
            onChanged: (_) => scope.toggleReminder(item.id),
          ),
          Text(
            'This is a note, not a calendar booking. The reminder stays on this device.',
            style: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (owner && item.volunteer == null) ...[
            const SizedBox(height: 24),
            if (help != null)
              Text(
                help.acceptedBy != null
                    ? '${help.acceptedBy} can help'
                    : 'Asked the family to help',
                style: theme.textTheme.bodyLarge,
              )
            else
              TextButton(
                style: flushButton,
                onPressed: () => scope.askFamilyHelp(item.id),
                child: const Text('Ask the family to help'),
              ),
          ],
        ],
      ),
    );
  }
}
