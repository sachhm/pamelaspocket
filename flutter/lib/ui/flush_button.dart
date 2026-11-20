import 'package:flutter/material.dart';

import '../theme/pocket_theme.dart';

/// Text button style without side padding, so the label lines up with the
/// text above it. Height still meets the 48 target.
final flushButton = TextButton.styleFrom(
  padding: EdgeInsets.zero,
  alignment: AlignmentDirectional.centerStart,
);

// Disabled falls through to the theme's grey; press dim stays the theme's.
final _danger = WidgetStateProperty.resolveWith<Color?>((states) {
  if (states.contains(WidgetState.disabled)) {
    return null;
  }

  return PocketTheme.danger;
});

/// Red label for Remove, Discard, and Turn off, in a dialog.
final dangerButton = ButtonStyle(foregroundColor: _danger);

/// [flushButton] with the red label, for the same actions inline.
final flushDanger = flushButton.copyWith(foregroundColor: _danger);
