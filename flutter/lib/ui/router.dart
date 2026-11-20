import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/enums.dart';
import '../features/about/about_screen.dart';
import '../features/about/ask_screen.dart';
import '../features/about/works_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/chat/guide_screen.dart';
import '../features/entry/composer_screen.dart';
import '../features/entry/entry_screen.dart';
import '../features/family/appointment_form.dart';
import '../features/family/appointment_leaf.dart';
import '../features/family/family_screen.dart';
import '../features/family/request_screen.dart';
import '../features/more/more_screen.dart';
import '../features/more/report_form.dart';
import '../features/more/report_leaf.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/pin/pin_screen.dart';
import '../features/sign_in/sign_in_screen.dart';
import '../features/today/today_screen.dart';
import '../features/welcome/welcome_screen.dart';
import '../session/pocket_scope.dart';
import 'paths.dart';
import 'shell.dart';

// Signed-out screens. Anyone signed in is sent on from these.
const _outside = {Paths.welcome, Paths.signIn, Paths.pin};

// Route prefixes staff may not open. A deep link lands on Today.
const _householdOnly = [
  Paths.family,
  Paths.guide,
  Paths.request,
  '/appointment/',
  '/report/',
  '${Paths.about}/${Paths.ask}',
  Paths.onboarding,
];

const _ownerOnly = [Paths.request, Paths.onboarding];

// While first-run is pending, owner may also sit on More (Show the QR).
const _pendingOk = {Paths.onboarding, Paths.more};

/// Routes from 01-navigation. Tabs share one shell; leaves cover it.
/// `new` routes are listed before their `:id` siblings so they win.
GoRouter buildRouter(PocketScope scope) {
  final root = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: root,
    initialLocation: Paths.welcome,
    // Scope notifies on onboarded / access too, not only who.
    refreshListenable: scope,
    redirect: (_, state) => _guard(scope, state.uri.path),
    routes: [
      GoRoute(path: Paths.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(
        path: Paths.signIn,
        builder: (_, state) {
          final family = state.uri.queryParameters['role'] == Role.family.name;

          return SignInScreen(role: family ? Role.family : Role.owner);
        },
      ),
      GoRoute(path: Paths.pin, builder: (_, _) => const PinScreen()),

      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => PocketShell(shell: shell),
        branches: [
          _branch(Paths.today, const TodayScreen()),
          _branch(
            Paths.about,
            const AboutScreen(),
            leaves: [
              GoRoute(
                path: Paths.ask,
                parentNavigatorKey: root,
                builder: (_, state) =>
                    AskScreen(id: state.uri.queryParameters['id']),
              ),
            ],
          ),
          _branch(Paths.chat, const ChatScreen()),
          _branch(Paths.family, const FamilyScreen()),
          _branch(Paths.more, const MoreScreen()),
        ],
      ),

      GoRoute(path: Paths.entryNew, builder: (_, _) => const ComposerScreen()),
      GoRoute(
        path: Paths.entry,
        builder: (_, state) => EntryScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Paths.works,
        builder: (_, state) => WorksScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: Paths.guide, builder: (_, _) => const GuideScreen()),
      GoRoute(path: Paths.request, builder: (_, _) => const RequestScreen()),
      GoRoute(
        path: Paths.appointmentNew,
        builder: (_, _) => const AppointmentForm(),
      ),
      GoRoute(
        path: Paths.appointment,
        builder: (_, state) =>
            AppointmentLeaf(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Paths.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(path: Paths.reportNew, builder: (_, _) => const ReportForm()),
      GoRoute(
        path: Paths.report,
        builder: (_, state) => ReportLeaf(id: state.pathParameters['id']!),
      ),
    ],
  );
}

String? _guard(PocketScope scope, String path) {
  final role = scope.actor?.role;
  final outside = _outside.contains(path);
  final pending = scope.state?.onboarded == Onboarding.pending;

  if (role == null) {
    return outside ? null : Paths.welcome;
  }

  if (outside) {
    if (role == Role.owner && pending) {
      return Paths.onboarding;
    }

    return Paths.today;
  }

  // First-run: stay on onboarding / More until Later or the walk ends.
  if (role == Role.owner && pending && !_pendingOk.contains(path)) {
    if (!path.startsWith('/report')) {
      return Paths.onboarding;
    }
  }

  if (path == Paths.onboarding &&
      (role != Role.owner || !pending)) {
    return Paths.today;
  }

  if (role == Role.staff && _householdOnly.any(path.startsWith)) {
    return Paths.today;
  }

  if (role != Role.owner && _ownerOnly.any(path.startsWith)) {
    return Paths.today;
  }

  return null;
}

StatefulShellBranch _branch(
  String path,
  Widget body, {
  List<RouteBase> leaves = const [],
}) {
  return StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (_, _) => body, routes: leaves)],
  );
}
