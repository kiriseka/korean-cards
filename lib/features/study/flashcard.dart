import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/db.dart';
import '../../widgets/common.dart';

/// A card that flips in 3D between its question and answer sides.
class Flashcard extends StatelessWidget {
  const Flashcard({super.key, required this.item, required this.revealed, required this.onTap});

  final CardWithWord item;
  final bool revealed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: revealed ? 1 : 0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        builder: (context, t, _) {
          final showBack = t >= 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(pi * t + (showBack ? pi : 0)),
            child: _Face(child: showBack ? _Back(item: item) : _Front(item: item)),
          );
        },
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 2,
        child: SizedBox.expand(
          child: Padding(padding: const EdgeInsets.all(24), child: child),
        ),
      );
}

class _Front extends StatelessWidget {
  const _Front({required this.item});
  final CardWithWord item;

  @override
  Widget build(BuildContext context) {
    final word = item.word;
    final theme = Theme.of(context);
    final koreanFirst = item.card.direction == Direction.koToEn;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (koreanFirst) ...[
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(word.word, style: theme.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w600)),
          ),
          SpeakButton(word.word, size: 36),
        ] else ...[
          Text(word.gloss, textAlign: TextAlign.center, style: theme.textTheme.headlineLarge),
          const SizedBox(height: 12),
          Text(word.senseList.first.definition, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: 16),
        TagChip(word.pos),
        const SizedBox(height: 32),
        Text('Tap to reveal', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
      ],
    );
  }
}

class _Back extends StatelessWidget {
  const _Back({required this.item});
  final CardWithWord item;

  @override
  Widget build(BuildContext context) {
    final word = item.word;
    final theme = Theme.of(context);
    final senses = word.senseList;
    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(word.word, style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w600)),
            ),
            SpeakButton(word.word),
          ],
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: [
            if (word.pronunciation != null) Text('[${word.pronunciation}]', style: theme.textTheme.titleMedium),
            if (word.hanja != null) Text(word.hanja!, style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        Center(child: Wrap(spacing: 8, children: [TagChip(word.pos), TagChip(levelLabel(word.level))])),
        const Divider(height: 32),
        for (final (i, s) in senses.indexed) ...[
          Text(
            senses.length > 1 ? '${i + 1}. ${s.meanings.join(', ')}' : s.meanings.join(', '),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (s.definition.isNotEmpty) Text(s.definition, style: theme.textTheme.bodyMedium),
          if (s.example != null)
            Row(
              children: [
                Expanded(child: Text(s.example!, style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic))),
                SpeakButton(s.example!, size: 22),
              ],
            ),
          const SizedBox(height: 16),
        ],
        if (word.note != null && word.note!.isNotEmpty)
          Card.filled(
            child: Padding(padding: const EdgeInsets.all(12), child: Text('📝 ${word.note}')),
          ),
      ],
    );
  }
}
