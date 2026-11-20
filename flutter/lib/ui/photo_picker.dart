import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

// Phone photos are resized so a handful fit in browser storage on web.
const _maxSide = 1600.0;
const _quality = 80;

/// Opens the system photo library. Null when the person cancels.
Future<Uint8List?> pickPhoto() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: _maxSide,
    maxHeight: _maxSide,
    imageQuality: _quality,
  );

  return file?.readAsBytes();
}
