import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../adapters/local/local_scan.dart';

const _size = 180.0;

/// Scannable household QR for the demo token. Used on More; PIN uses a
/// smaller drawn stand-in of the same data.
class QrMark extends StatelessWidget {
  const QrMark({super.key, this.size = _size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final brown = Theme.of(context).colorScheme.primary;

    return Semantics(
      label: 'Demo code for Pamela’s care profile',
      image: true,
      // QrImageView owns its own nodes; keep one label on the parent.
      child: ExcludeSemantics(
        child: ColoredBox(
          color: Colors.white,
          child: QrImageView(
            data: householdToken,
            size: size,
            backgroundColor: Colors.white,
            eyeStyle: QrEyeStyle(color: brown, eyeShape: QrEyeShape.square),
            dataModuleStyle: QrDataModuleStyle(
              color: brown,
              dataModuleShape: QrDataModuleShape.square,
            ),
          ),
        ),
      ),
    );
  }
}
