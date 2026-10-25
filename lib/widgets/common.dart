import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db.dart';
import '../providers.dart';

enum CardStatus {
  newCard('New'),
  learning('Learning'),
  known('Known'),
  suspended('Suspended');

  const CardStatus(this.label);
  final String label;

  static CardStatus of(StudyCard c) {
    if (c.suspended) return suspended;
    if (c.state == CardState.newCard) return newCard;
    if (c.state == CardState.review && (c.stability ?? 0) >= knownStabilityDays) return known;
    return learning;
  }

  Color color(ColorScheme scheme) => switch (this) {
        newCard => scheme.primary,
        learning => Colors.orange,
        known => Colors.green,
        suspended => scheme.outline,
      };
}

class StatusDot extends StatelessWidget {
  const StatusDot(this.status, {super.key});
  final CardStatus status;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: status.label,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: status.color(Theme.of(context).colorScheme), shape: BoxShape.circle),
        ),
      );
}

class TagChip extends StatelessWidget {
  const TagChip(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: scheme.onSecondaryContainer, fontSize: 13)),
    );
  }
}

String levelLabel(String level) => level == 'custom' ? 'My word' : level;

class SpeakButton extends ConsumerWidget {
  const SpeakButton(this.text, {super.key, this.size = 28});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
        tooltip: 'Listen',
        iconSize: size,
        icon: const Icon(Icons.volume_up_rounded),
        onPressed: () => ref.speak(text),
      );
}
