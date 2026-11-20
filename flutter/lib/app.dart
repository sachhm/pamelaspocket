import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'session/pocket_scope.dart';
import 'theme/pocket_theme.dart';
import 'ui/fault_bar.dart';
import 'ui/router.dart';

// Browser builds are a phone column, not a desktop layout.
const _webColumn = 430.0;

class PocketApp extends StatefulWidget {
  const PocketApp({super.key, required this.scope});

  final PocketScope scope;

  @override
  State<PocketApp> createState() => _PocketAppState();
}

class _PocketAppState extends State<PocketApp> {
  late final GoRouter _router = buildRouter(widget.scope);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PocketHost(
      scope: widget.scope,
      child: MaterialApp.router(
        title: 'Pamela’s Pocket',
        debugShowCheckedModeBanner: false,
        theme: PocketTheme.light(),
        themeMode: ThemeMode.light,
        routerConfig: _router,
        builder: (context, child) => _column(context, _ready(context, child!)),
      ),
    );
  }

  // Until the first load succeeds there is nothing to route to: show the
  // fault with "Try again" instead.
  Widget _ready(BuildContext context, Widget child) {
    final scope = PocketScope.of(context);
    final fault = scope.fault;

    if (scope.state != null) {
      return child;
    }

    return Material(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: fault == null
              ? null
              : FaultBar(text: fault, onRetry: scope.retry),
        ),
      ),
    );
  }

  // Web: centre a 430-wide column on petal. Phone: full width.
  Widget _column(BuildContext context, Widget child) {
    if (!kIsWeb) {
      return child;
    }

    final media = MediaQuery.of(context);
    final width = math.min(media.size.width, _webColumn);

    return ColoredBox(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Center(
        child: SizedBox(
          width: width,
          child: MediaQuery(
            data: media.copyWith(size: Size(width, media.size.height)),
            child: ClipRect(child: child),
          ),
        ),
      ),
    );
  }
}
