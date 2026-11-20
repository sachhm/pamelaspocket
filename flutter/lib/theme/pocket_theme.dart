import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

// Brand palette plus olive ink. Brand olive fails as text (3.2:1 on ivory),
// so meta text uses the darker olive ink instead.
const _brown = Color(0xFF7B3E19);
const _ivory = Color(0xFFF8F9F0);
const _petal = Color(0xFFF8DBC9);
const _olive = Color(0xFF839073);
const _bronze = Color(0xFFEAAC8B);
const _oliveInk = Color(0xFF5C6650);
const _sheet = Color(0xFFFFFCF7);

const _serif = 'Literata';

const _cardRadius = 12.0;
const _minTarget = 48.0;

// Flat press dim. A spreading splash reads as Android on an iPhone layout.
const _press = Color(0x29000000);
const _focus = Color(0x147B3E19);

/// Light Material 3 theme for Pamela’s Pocket. No dark variant by design.
class PocketTheme {
  const PocketTheme._();

  /// Sand band for a note. Darker than ivory, duller than petal.
  /// Olive ink fails here, so meta on a note uses brown.
  static const group = Color(0xFFD9D0BF);

  /// Red for actions that lose something. Brown reads as ordinary.
  /// 6.2:1 on ivory, 6.4:1 on a sheet.
  static const danger = Color(0xFFB3261E);

  /// The handover paragraph only: sans 20, roomy lines, brown.
  static const handover = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: _brown,
  );

  static ThemeData light() {
    final scheme = _scheme();
    final text = _text();

    // Pressed controls dim in place. Focus keeps a brown wash for the web column.
    final overlay = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.pressed)) {
        return _press;
      }

      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return _focus;
      }

      return null;
    });

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: _ivory,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: _press,

      // Flat surfaces: no tint wash, no shadows.
      appBarTheme: AppBarTheme(
        backgroundColor: _ivory,
        foregroundColor: _brown,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.headlineSmall,
      ),
      cardTheme: const CardThemeData(
        color: _ivory,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(_cardRadius)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _olive,
        thickness: 1,
        space: 1,
      ),

      // Bar: petal pill, brown when active, olive icon and olive-ink label when not.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _ivory,
        indicatorColor: _petal,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _brown);
          }

          return const IconThemeData(color: _olive);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return text.labelMedium!.copyWith(color: _brown);
          }

          return text.labelMedium!.copyWith(color: _oliveInk);
        }),
      ),

      // One filled button per screen; everything else is a text button.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(_minTarget, _minTarget),
          textStyle: text.labelLarge,
          shape: const StadiumBorder(),
          // Disabled Send must stay readable on ivory (default washes out).
          disabledBackgroundColor: _bronze.withValues(alpha: 0.45),
          disabledForegroundColor: _oliveInk,
        ).copyWith(overlayColor: overlay),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(_minTarget, _minTarget),
          textStyle: text.labelLarge,
        ).copyWith(overlayColor: overlay),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(_minTarget, _minTarget),
        ).copyWith(overlayColor: overlay),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom().copyWith(overlayColor: overlay),
      ),
      // Entry-kind chips: brown fill when picked, ivory with olive edge when not.
      chipTheme: ChipThemeData(
        color: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _brown;
          }

          return _ivory;
        }),
        labelStyle: text.labelLarge!.copyWith(
          color: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _ivory;
            }

            return _brown;
          }),
        ),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BorderSide.none;
          }

          return const BorderSide(color: _olive);
        }),
        checkmarkColor: _ivory,
        elevation: 0,
        pressElevation: 0,
      ),

      // Outlined fields, brown focus, errors in brown under the field.
      inputDecorationTheme: InputDecorationTheme(
        border: _field(_olive),
        enabledBorder: _field(_olive),
        focusedBorder: _field(_brown, width: 2),
        errorBorder: _field(_brown),
        focusedErrorBorder: _field(_brown, width: 2),
        labelStyle: text.bodyLarge!.copyWith(color: _oliveInk),
        hintStyle: text.bodyLarge!.copyWith(color: _oliveInk),
        errorStyle: text.bodyMedium!.copyWith(color: _brown),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: _brown,
        contentTextStyle: text.bodyMedium!.copyWith(color: _ivory),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: _brown),
      pageTransitionsTheme: _transitions(),
    );
  }

  // Platform default transitions, each wrapped to honour reduce motion.
  static PageTransitionsTheme _transitions() {
    final defaults = const PageTransitionsTheme().builders;

    return PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: _CalmTransitions(
            defaults[platform] ?? const ZoomPageTransitionsBuilder(),
          ),
      },
    );
  }

  // Brand roles from 04-theme. Surface containers fall back to ivory.
  static ColorScheme _scheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: _brown,
      onPrimary: _ivory,
      primaryContainer: _petal,
      onPrimaryContainer: _brown,
      secondary: _olive,
      onSecondary: _ivory,
      tertiary: _bronze,
      onTertiary: _brown,
      error: _brown,
      onError: _ivory,
      surface: _ivory,
      onSurface: _brown,
      onSurfaceVariant: _oliveInk,
      surfaceContainerLowest: _sheet,
      outline: _olive,
      outlineVariant: _bronze,
      inverseSurface: _brown,
      onInverseSurface: _ivory,
      surfaceTint: Colors.transparent,
    );
  }

  // Type scale: Literata for display, headline and section titles; platform
  // sans for the rest. Small slots are raised so nothing renders under 14.
  static TextTheme _text() {
    const serif600 = TextStyle(fontFamily: _serif, fontWeight: FontWeight.w600);
    const sans600 = TextStyle(fontWeight: FontWeight.w600);
    const sans400 = TextStyle(fontWeight: FontWeight.w400);

    return TextTheme(
      displaySmall: serif600.copyWith(fontSize: 32),
      headlineSmall: serif600.copyWith(fontSize: 26),
      titleLarge: const TextStyle(
        fontFamily: _serif,
        fontWeight: FontWeight.w400,
        fontSize: 22,
      ),
      titleMedium: sans600.copyWith(fontSize: 18),
      titleSmall: sans600.copyWith(fontSize: 16),
      bodyLarge: sans400.copyWith(fontSize: 18),
      bodyMedium: sans400.copyWith(fontSize: 16),
      bodySmall: sans400.copyWith(fontSize: 14),
      labelLarge: sans600.copyWith(fontSize: 16),
      labelMedium: sans600.copyWith(fontSize: 14),
      labelSmall: sans600.copyWith(fontSize: 14),
    ).apply(bodyColor: _brown, displayColor: _brown);
  }

  static OutlineInputBorder _field(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(_cardRadius)),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// Cuts instead of animating when the platform asks for reduced motion.
/// The iOS builder is kept so the edge-swipe back gesture survives.
class _CalmTransitions extends PageTransitionsBuilder {
  const _CalmTransitions(this._platform);

  final PageTransitionsBuilder _platform;

  @override
  Duration get transitionDuration => _platform.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _platform.reverseTransitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final calm = MediaQuery.disableAnimationsOf(context);

    if (calm && _platform is! CupertinoPageTransitionsBuilder) {
      return child;
    }

    return _platform.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
