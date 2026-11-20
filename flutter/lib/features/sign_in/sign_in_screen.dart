import 'package:flutter/material.dart';

import '../../domain/auth.dart';
import '../../domain/enums.dart';
import '../../session/pocket_scope.dart';
import '../../ui/busy_label.dart';
import '../../ui/field_error.dart';
import '../../ui/role_label.dart';

// The sample household is the path a visitor takes. Email stays available.

const _rejected = 'That email or password was not accepted.';
const _noAnswer = 'The sign-in service did not answer.';

/// Which button started the running sign-in, so only it shows progress.
enum _Pending { none, demo, form }

/// Email and password for the owner or family. Success stores the actor and
/// the router moves on to Today; errors sit under the button.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.role});

  final Role role;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  _Pending _pending = _Pending.none;
  String? _error;

  // Demo credentials are public; iOS should not offer to save them.
  AutofillContextAction _onDispose = AutofillContextAction.commit;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final idle = _pending == _Pending.none;
    final person = actorFor(widget.role).name;

    return Scaffold(
      appBar: AppBar(title: Text(roleLabel(widget.role))),
      body: AutofillGroup(
        onDisposeAction: _onDispose,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton(
              onPressed: idle ? _demo : null,
              child: BusyLabel(
                'Continue as $person',
                phase: _phaseOf(_Pending.demo),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sample household. Look around, then sign out.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Text('Or sign in', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _clear(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.go,
              onChanged: (_) => _clear(),
              onSubmitted: (_) => _continue(),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: idle ? _continue : null,
              child: BusyLabel('Continue', phase: _phaseOf(_Pending.form)),
            ),
            if (_error case final error?) ...[
              const SizedBox(height: 12),
              FieldError(error),
            ],
          ],
        ),
      ),
    );
  }

  Phase _phaseOf(_Pending button) {
    return _pending == button ? Phase.busy : Phase.idle;
  }

  void _clear() {
    if (_error == null) {
      return;
    }

    setState(() => _error = null);
  }

  // Fills the role's demo account so the reviewer sees what was used.
  Future<void> _demo() {
    _email.text = emailFor(widget.role);
    _password.text = demoPassword;
    _onDispose = AutofillContextAction.cancel;

    return _submit(_Pending.demo, PocketScope.of(context).signIn);
  }

  Future<void> _continue() {
    return _submit(_Pending.form, PocketScope.of(context).signUp);
  }

  Future<void> _submit(
    _Pending button,
    Future<SignInResult> Function(Role, String, String) send,
  ) async {
    // Drops the keyboard so the error under the button is not hidden.
    FocusScope.of(context).unfocus();

    setState(() {
      _pending = button;
      _error = null;
    });

    String? error;

    try {
      final result = await send(widget.role, _email.text, _password.text);
      error = result == SignInResult.ok ? null : _rejected;
    } on Object {
      error = _noAnswer;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _pending = _Pending.none;
      _error = error;
    });
  }
}
