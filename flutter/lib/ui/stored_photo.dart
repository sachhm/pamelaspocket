import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../session/pocket_scope.dart';

const _radius = 12.0;
const _thumb = 96.0;
const _placeholderRatio = 4 / 3;

/// How much room the photo takes: the column's width, or a 96 pt thumbnail.
enum PhotoSize { full, thumb }

/// A stored photo, read once through the session. While it loads a petal
/// box holds its place; missing bytes show nothing.
class StoredPhoto extends StatefulWidget {
  const StoredPhoto({
    super.key,
    required this.id,
    required this.label,
    this.size = PhotoSize.full,
  });

  final String id;
  final String label;
  final PhotoSize size;

  @override
  State<StoredPhoto> createState() => _StoredPhotoState();
}

class _StoredPhotoState extends State<StoredPhoto> {
  // Read once, not on every rebuild of the screen.
  late final Future<Uint8List?> _bytes = PocketScope.of(
    context,
  ).readFile(widget.id);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _bytes,
      builder: (context, snapshot) {
        final bytes = snapshot.data;

        if (snapshot.connectionState != ConnectionState.done) {
          return _placeholder(context);
        }

        if (bytes == null) {
          return const SizedBox.shrink();
        }

        final photo = ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: _image(context, bytes),
        );

        // A list stretches its children; a thumbnail keeps its own width.
        if (widget.size == PhotoSize.thumb) {
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: photo,
          );
        }

        return photo;
      },
    );
  }

  // Decoded at the size it is shown, not the stored 1600 px.
  Widget _image(BuildContext context, Uint8List bytes) {
    final dpr = MediaQuery.devicePixelRatioOf(context);

    if (widget.size == PhotoSize.thumb) {
      return Image.memory(
        bytes,
        height: _thumb,
        cacheHeight: (_thumb * dpr).round(),
        fit: BoxFit.cover,
        semanticLabel: widget.label,
      );
    }

    return LayoutBuilder(
      builder: (context, box) => Image.memory(
        bytes,
        fit: BoxFit.cover,
        cacheWidth: (box.maxWidth * dpr).round(),
        semanticLabel: widget.label,
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(_radius),
      ),
    );

    if (widget.size == PhotoSize.thumb) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox.square(dimension: _thumb, child: box),
      );
    }

    return AspectRatio(aspectRatio: _placeholderRatio, child: box);
  }
}
