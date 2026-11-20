import 'package:flutter/material.dart';

const _dot = 8.0;

/// The three words generated text carries.
enum AiLabel {
  summary('AI summary'),
  reply('AI reply'),
  suggestion('AI suggestion');

  const AiLabel(this.text);

  final String text;
}

/// The surface the chip sits on.
enum ChipGround { ivory, petal }

/// Petal pill with a bronze dot, placed above a generated paragraph.
/// On a petal card the pill turns ivory, or it would vanish into the card.
///
///   ( • AI summary )
class AiChip extends StatelessWidget {
  const AiChip(this.label, {super.key, this.ground = ChipGround.ivory});

  final AiLabel label;
  final ChipGround ground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fill = ground == ChipGround.petal
        ? scheme.surface
        : scheme.primaryContainer;

    return DecoratedBox(
      decoration: ShapeDecoration(color: fill, shape: const StadiumBorder()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _dot,
              height: _dot,
              decoration: BoxDecoration(
                color: scheme.tertiary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label.text,
              style: theme.textTheme.labelMedium!.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
