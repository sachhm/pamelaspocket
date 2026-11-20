import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// A live region that also speaks [text] when it appears or changes.
/// VoiceOver ignores live regions, so iOS and web need the announcement;
/// Android reads the live region and reports no announce support.
class Announced extends StatefulWidget {
  const Announced({super.key, required this.text, required this.child});

  final String text;
  final Widget child;

  @override
  State<Announced> createState() => _AnnouncedState();
}

class _AnnouncedState extends State<Announced> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  @override
  void didUpdateWidget(Announced old) {
    super.didUpdateWidget(old);

    if (old.text != widget.text) {
      _speak();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(liveRegion: true, child: widget.child);
  }

  void _speak() {
    if (!mounted || !MediaQuery.supportsAnnounceOf(context)) {
      return;
    }

    SemanticsService.sendAnnouncement(
      View.of(context),
      widget.text,
      Directionality.of(context),
    );
  }
}
