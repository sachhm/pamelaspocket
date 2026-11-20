import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/copy.dart';
import '../../domain/enums.dart';
import '../../session/pocket_scope.dart';
import '../../ui/announced.dart';
import '../../ui/busy_label.dart';
import '../../ui/field_error.dart';

const _failed = 'The care service did not answer.';
const _posted = 'Request posted';
const _posting = 'Posting…';

// Same slot as the chevron, so the row does not jump when the post starts.
const _spinner = 24.0;
const _stroke = 2.0;

/// Owner picks one of the three fixed help sentences, then pops.
class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  Phase _phase = Phase.idle;
  RequestKind? _kind;
  String? _error;
  String? _done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ask for help')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?_notice(theme),
          Expanded(child: _choices(theme)),
        ],
      ),
    );
  }

  // Posted and failed sit above the sentences so the three rows stay put.
  Widget? _notice(ThemeData theme) {
    if (_phase == Phase.busy) {
      return null;
    }

    if (_done case final done?) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Announced(
          text: done,
          child: Text(done, style: theme.textTheme.bodyLarge),
        ),
      );
    }

    if (_error case final error?) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: FieldError(error),
      );
    }

    return null;
  }

  Widget _choices(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final (index, kind) in RequestKind.values.indexed) ...[
          if (index > 0) const Divider(),
          _choice(theme, kind),
        ],
      ],
    );
  }

  // Spinner replaces the chevron on the tapped sentence. Every row ignores
  // taps until the post finishes, so a second tap cannot send another ask.
  Widget _choice(ThemeData theme, RequestKind kind) {
    final posting = _phase == Phase.busy && _kind == kind;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(requestText(kind), style: theme.textTheme.bodyLarge),
      trailing: posting
          ? const _Posting()
          : Icon(Icons.chevron_right, color: theme.colorScheme.secondary),
      onTap: _phase == Phase.idle ? () => _post(kind) : null,
    );
  }

  Future<void> _post(RequestKind kind) async {
    setState(() {
      _phase = Phase.busy;
      _kind = kind;
      _error = null;
      _done = null;
    });

    try {
      await PocketScope.of(context).postRequest(kind);
    } on Object {
      if (mounted) {
        setState(() {
          _phase = Phase.idle;
          _kind = null;
          _error = _failed;
        });
      }

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _phase = Phase.idle;
      _kind = null;
      _done = _posted;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (mounted) {
      context.pop();
    }
  }
}

/// Spoken as "Posting…" without a loose line under the sentences.
class _Posting extends StatelessWidget {
  const _Posting();

  @override
  Widget build(BuildContext context) {
    // Own node, so the sentence tile does not swallow the status.
    return Semantics(
      container: true,
      label: _posting,
      child: const SizedBox.square(
        dimension: _spinner,
        child: CircularProgressIndicator(strokeWidth: _stroke),
      ),
    );
  }
}
