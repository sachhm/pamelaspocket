import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/enums.dart';
import '../domain/records.dart';
import '../domain/story.dart';
import '../session/pocket_scope.dart';
import 'fault_bar.dart';
import 'name_chip.dart';
import 'paths.dart';
import 'shell_cover.dart';

// Full-width primary action: a 52 pt pill, above the 44 pt floor.
const _action = 52.0;
// Scrolled this far, the large title's name is under the bar.
const _titleGone = 56.0;
const _fade = Duration(milliseconds: 150);

/// Signed-in frame: serif title and name chip on top, the bar below,
/// one pinned action on tabs that add something.
///
///   ┌──────────────────────────────┐
///   │ Title               (A) Alex │  app bar; Today: name after scroll
///   ├──────────────────────────────┤
///   │   active branch              │  StatefulNavigationShell
///   ├──────────────────────────────┤  bronze hairline
///   │ [       + Add update       ] │  Today; About: Continue the story
///   │ Today About Chat Family More │  Family hidden for staff
///   └──────────────────────────────┘
class PocketShell extends StatefulWidget {
  const PocketShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  State<PocketShell> createState() => _PocketShellState();
}

class _PocketShellState extends State<PocketShell> {
  // Today's large title has scrolled under the bar.
  bool _past = false;

  // Covered while a leaf (composer, guide, a dialog) sits on the shell.
  final _shade = ValueNotifier(ShellShade.open);

  StatefulNavigationShell get shell => widget.shell;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final next = route != null && !route.isCurrent
        ? ShellShade.covered
        : ShellShade.open;

    if (_shade.value != next) {
      _shade.value = next;
    }
  }

  @override
  void dispose() {
    _shade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = PocketScope.of(context);
    final actor = scope.actor;
    final fault = scope.fault;
    final scheme = Theme.of(context).colorScheme;
    final current = Area.values[shell.currentIndex];
    // Free the strip above the IME (Chat composer, fields) from the tab bar.
    final keyed = MediaQuery.viewInsetsOf(context).bottom > 0;

    // Signing out: the router is about to leave the shell.
    if (actor == null) {
      return const SizedBox.shrink();
    }

    // The bar lists only what this role may open; branch indexes stay fixed.
    final areas = Area.values.where((area) {
      if (area.reach == Reach.everyone) {
        return true;
      }

      return actor.role != Role.staff;
    }).toList();
    final selected = areas.indexOf(current);
    final action = _actionFor(current, actor.role, scope.state);

    // System Back on another tab returns to Today before leaving the app.
    return ShellCover(
      shade: _shade,
      child: PopScope(
        canPop: current == Area.today,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            return;
          }

          _open(Area.today);
        },
        child: Scaffold(
          // Today's large title lives in the list; her name takes the bar
          // only once it has scrolled away, as on iOS.
          appBar: AppBar(
            centerTitle: false,
            title: current == Area.today
                ? AnimatedSwitcher(
                    duration: _fade,
                    child: _past
                        ? Text(scope.state?.recipient.name ?? '')
                        : const SizedBox.shrink(),
                  )
                : Text(current.title),
            actions: [
              NameChip(actor: actor, onTap: () => _open(Area.more)),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              if (fault != null) FaultBar(text: fault, onRetry: scope.retry),
              Expanded(
                child: NotificationListener<ScrollUpdateNotification>(
                  onNotification: _onScroll,
                  child: shell,
                ),
              ),
            ],
          ),
          // Add update rides above the bar, so it never covers a row.
          bottomNavigationBar: keyed
              ? null
              : DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: scheme.tertiary)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (action != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: FilledButton.icon(
                            onPressed: () => context.push(action.path),
                            icon: const Icon(Icons.add, applyTextScaling: true),
                            label: Text(action.label),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(_action),
                            ),
                          ),
                        ),
                      NavigationBar(
                        selectedIndex: selected < 0 ? 0 : selected,
                        onDestinationSelected: (index) => _open(areas[index]),
                        destinations: [
                          for (final area in areas)
                            NavigationDestination(
                              icon: Icon(area.icon),
                              selectedIcon: Icon(area.activeIcon),
                              label: area.label,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // Only Today's own list moves the title; nested scrollers do not.
  bool _onScroll(ScrollUpdateNotification note) {
    final today = Area.values[shell.currentIndex] == Area.today;

    if (!today || note.depth != 0 || note.metrics.axis != Axis.vertical) {
      return false;
    }

    final past = note.metrics.pixels > _titleGone;

    if (past != _past) {
      setState(() => _past = past);
    }

    return false;
  }

  // One pinned action per tab that adds something. Staff read About only.
  //   Today → Add update        About → Continue the story
  ({String label, String path})? _actionFor(
    Area area,
    Role role,
    PocketState? state,
  ) {
    if (area == Area.today) {
      return (label: 'Add update', path: Paths.entryNew);
    }

    if (area != Area.about || role == Role.staff || state == null) {
      return null;
    }

    final next = nextAsk(state.prompts);
    return (label: 'Continue the story', path: Paths.askFor(next.id));
  }

  // Re-tapping the active tab returns it to its root.
  void _open(Area area) {
    shell.goBranch(
      area.index,
      initialLocation: area.index == shell.currentIndex,
    );
  }
}
