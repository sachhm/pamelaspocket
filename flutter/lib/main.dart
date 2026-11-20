import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'care/compose.dart';
import 'session/pocket_scope.dart';

// Load before the first frame so a saved actor opens straight on Today.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final scope = PocketScope(composeDesk(prefs));
  await scope.load();

  runApp(PocketApp(scope: scope));
}
