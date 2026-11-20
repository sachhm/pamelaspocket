import 'package:flutter/widgets.dart';

/// Whether a leaf route is covering the tab shell.
enum ShellShade { open, covered }

/// The shell publishes this so a note saved under the composer
/// settles as that page leaves, not while it is still hidden.
class ShellCover extends InheritedNotifier<ValueNotifier<ShellShade>> {
  const ShellCover({
    super.key,
    required ValueNotifier<ShellShade> shade,
    required super.child,
  }) : super(notifier: shade);

  static ShellShade shadeOf(BuildContext context) {
    final cover = context.dependOnInheritedWidgetOfExactType<ShellCover>();

    return cover?.notifier?.value ?? ShellShade.open;
  }
}
