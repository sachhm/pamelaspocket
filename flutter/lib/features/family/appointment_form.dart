import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/records.dart';
import '../../session/pocket_scope.dart';
import '../../ui/busy_label.dart';
import '../../ui/field_error.dart';
import '../../ui/paths.dart';

const _failed = 'The care service did not answer.';
const _need = 'Add a place and a reason.';

/// New appointment. Save needs place and reason; pops to Family.
class AppointmentForm extends StatefulWidget {
  const AppointmentForm({super.key});

  @override
  State<AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends State<AppointmentForm> {
  final _place = TextEditingController();
  final _reason = TextEditingController();
  final _transport = TextEditingController();
  final _notes = TextEditingController();
  DateTime _day = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _clock = const TimeOfDay(hour: 10, minute: 30);
  Phase _phase = Phase.idle;
  String? _error;

  @override
  void dispose() {
    _place.dispose();
    _reason.dispose();
    _transport.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final whenLabel =
        '${MaterialLocalizations.of(context).formatMediumDate(_day)}'
        ' · ${_clock.format(context)}';

    return Scaffold(
      appBar: AppBar(title: const Text('New appointment')),
      // Fields scroll; Save stays pinned above the IME (diary composer pattern).
      body: Column(
        children: [
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('When', style: theme.textTheme.labelLarge),
                  subtitle: Text(whenLabel, style: theme.textTheme.bodyLarge),
                  trailing: Icon(
                    Icons.event,
                    color: theme.colorScheme.secondary,
                  ),
                  onTap: _pickWhen,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _place,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Place'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reason,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _transport,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Transport'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _phase == Phase.idle ? _save : null,
                    child: BusyLabel('Save', phase: _phase),
                  ),
                  if (_error case final error?) ...[
                    const SizedBox(height: 12),
                    FieldError(error),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickWhen() async {
    final day = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (day == null || !mounted) {
      return;
    }

    final clock = await showTimePicker(context: context, initialTime: _clock);

    if (!mounted) {
      return;
    }

    setState(() {
      _day = day;

      if (clock != null) {
        _clock = clock;
      }
    });
  }

  Future<void> _save() async {
    if (_place.text.trim().isEmpty || _reason.text.trim().isEmpty) {
      setState(() => _error = _need);

      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = DateTime(_day.year, _day.month, _day.day);
    final when = When(
      dayOffset: picked.difference(today).inDays,
      hour: _clock.hour,
      minute: _clock.minute,
      seq: 0,
    );

    setState(() {
      _phase = Phase.busy;
      _error = null;
    });

    try {
      await PocketScope.of(context).addAppointment(
        when: when,
        place: _place.text,
        reason: _reason.text,
        transport: _transport.text,
        notes: _notes.text,
      );
    } on Object {
      if (mounted) {
        setState(() {
          _phase = Phase.idle;
          _error = _failed;
        });
      }

      return;
    }

    if (!mounted) {
      return;
    }

    // pop() stays here after the diary write refreshes the router.
    context.go(Paths.family);
  }
}
