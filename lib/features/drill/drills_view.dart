import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../learn/drill.dart';
import '../../providers.dart';
import 'drill_screen.dart';

/// Word-card drills by category: your piles, a level, or a topic.
class DrillsView extends ConsumerWidget {
  const DrillsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(curriculumProvider).value;
    final rows = ref.watch(drillCountsProvider).value;
    if (units == null || rows == null) return const Center(child: CircularProgressIndicator());
    final theme = Theme.of(context);
    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Text(text, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        );
    Widget tile(Drill d) => _DrillTile(drill: d, tally: d.tally(rows), onTap: () => openDrill(context, ref, d));
    Widget grid(List<Drill> drills) => GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [for (final d in drills) tile(d)],
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 48),
      children: [
        Card.filled(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '🃏 Pick any category and swipe: → learned, ← hard. Tap a card to see its meaning, '
              'tap 🔊 to hear it. Drill a deck as often as you like.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        header('My piles'),
        grid(const [Drill.hard, Drill.learned, Drill.starredWords]),
        header('By level'),
        grid(const [Drill.beginner, Drill.intermediate]),
        header('By topic'),
        grid([for (final u in units) Drill.topic(u)]),
      ],
    );
  }
}

/// The drills as a page of their own, for the home screen's button.
class DrillsScreen extends StatelessWidget {
  const DrillsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('🃏 Word card drills')),
        body: const DrillsView(),
      );
}

class _DrillTile extends StatelessWidget {
  const _DrillTile({required this.drill, required this.tally, required this.onTap});
  final Drill drill;
  final DrillTally tally;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showProgress = drill.pile == null && tally.total > 0;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(drill.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 6),
              Text(
                drill.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                switch (drill.pile) {
                  Pile.hard => '${tally.total} to practise',
                  Pile.learned => '${tally.total} words',
                  _ => tally.total == 0 ? 'No words yet' : '${tally.learned} / ${tally.total} learned',
                },
                style: theme.textTheme.labelSmall,
              ),
              if (showProgress) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: tally.learned / tally.total, minHeight: 5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
