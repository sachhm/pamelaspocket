import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket/theme/pocket_theme.dart';

// WCAG AA for body text.
const _textContrast = 4.5;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;

  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final theme = PocketTheme.light();
  final s = theme.colorScheme;

  // Every text-on-background pair the theme spec allows.
  final pairs = <String, (Color, Color)>{
    'onPrimary on primary': (s.onPrimary, s.primary),
    'onPrimaryContainer on primaryContainer': (
      s.onPrimaryContainer,
      s.primaryContainer,
    ),
    'body text on surface': (s.onSurface, s.surface),
    'olive ink on surface': (s.onSurfaceVariant, s.surface),
    'olive ink on primaryContainer': (s.onSurfaceVariant, s.primaryContainer),
    'body text on surfaceContainerLowest': (
      s.onSurface,
      s.surfaceContainerLowest,
    ),
    'error on surface': (s.error, s.surface),
    'snackbar text': (s.onInverseSurface, s.inverseSurface),
    'handover on primaryContainer': (
      PocketTheme.handover.color!,
      s.primaryContainer,
    ),
  };

  for (final MapEntry(key: name, value: (fg, bg)) in pairs.entries) {
    test('$name meets 4.5:1', () {
      expect(_contrast(fg, bg), greaterThanOrEqualTo(_textContrast));
    });
  }

  test('light Material 3 with no tint wash', () {
    expect(theme.useMaterial3, isTrue);
    expect(s.brightness, Brightness.light);
    expect(s.surfaceTint, Colors.transparent);
  });

  test('titles use bundled Literata, nothing below 14', () {
    // Unset slots take their size from typography once the theme is localised.
    final geometry = theme.typography.geometryThemeFor(
      ScriptCategory.englishLike,
    );
    final t = ThemeData.localize(theme, geometry).textTheme;

    expect(t.displaySmall!.fontFamily, 'Literata');
    expect(t.headlineSmall!.fontFamily, 'Literata');
    expect(t.titleLarge!.fontFamily, 'Literata');

    final styles = [
      t.displayLarge,
      t.displayMedium,
      t.displaySmall,
      t.headlineLarge,
      t.headlineMedium,
      t.headlineSmall,
      t.titleLarge,
      t.titleMedium,
      t.titleSmall,
      t.bodyLarge,
      t.bodyMedium,
      t.bodySmall,
      t.labelLarge,
      t.labelMedium,
      t.labelSmall,
    ];
    for (final style in styles) {
      expect(style!.fontSize, greaterThanOrEqualTo(14));
    }
  });
}
