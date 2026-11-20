import 'package:flutter/material.dart';

/// Whether a commit is running.
enum Phase { idle, busy }

const _spinner = 20.0;

/// Button label that swaps to a 20px spinner while busy. The label keeps its
/// slot (invisible) so the button does not change width.
class BusyLabel extends StatelessWidget {
  const BusyLabel(this.label, {super.key, required this.phase});

  final String label;
  final Phase phase;

  @override
  Widget build(BuildContext context) {
    final busy = phase == Phase.busy;

    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(opacity: busy ? 0 : 1, child: Text(label)),
        if (busy)
          SizedBox.square(
            dimension: _spinner,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: DefaultTextStyle.of(context).style.color,
            ),
          ),
      ],
    );
  }
}
