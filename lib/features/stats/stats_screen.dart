import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/db.dart';
import '../../providers.dart';
import 'stats_data.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(overviewProvider).value;
    final logs = ref.watch(recentLogsProvider).value;
    if (overview == null || logs == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final now = DateTime.now();
    final perDay = reviewsPerDay(logs, now);
    final retention = retentionOf(logs, addDays(studyDayStart(now), -30));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('통계 · Stats')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProgressCard(overview: overview),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _Tile(label: 'Day streak', value: '${streakOf(logs, now)}')),
              const SizedBox(width: 12),
              Expanded(child: _Tile(label: 'Retention (30d)', value: retention == null ? '–' : '${(retention * 100).round()}%')),
              const SizedBox(width: 12),
              Expanded(child: _Tile(label: 'Reviews (30d)', value: '${perDay.fold(0, (sum, d) => sum + d.count)}')),
            ],
          ),
          const SizedBox(height: 24),
          Text('Reviews per day', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(height: 160, child: _BarChart(days: perDay)),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.overview});
  final Overview overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final o = overview;
    final learning = o.learning + o.young;
    Widget legend(Color color, String label, int value) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('$label $value'),
          ],
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${o.known} of ${o.total - o.suspended} words known', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    if (o.known > 0) Expanded(flex: o.known, child: const ColoredBox(color: Colors.green)),
                    if (learning > 0) Expanded(flex: learning, child: const ColoredBox(color: Colors.orange)),
                    if (o.newCount > 0)
                      Expanded(flex: o.newCount, child: ColoredBox(color: theme.colorScheme.surfaceContainerHighest)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                legend(Colors.green, 'Known', o.known),
                legend(Colors.orange, 'Learning', learning),
                legend(theme.colorScheme.surfaceContainerHighest, 'New', o.newCount),
                if (o.suspended > 0) legend(theme.colorScheme.outline, 'Suspended', o.suspended),
              ],
            ),
            const SizedBox(height: 8),
            Text('"Known" means the next review is 3+ weeks away.', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card.outlined(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.days});
  final List<DayCount> days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final max = days.fold(1, (m, d) => d.count > m ? d.count : m);
    final small = Theme.of(context).textTheme.labelSmall;
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final d in days)
                Expanded(
                  child: Tooltip(
                    message: '${DateFormat.MMMd().format(d.day)}: ${d.count}',
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      height: d.count == 0 ? 2 : 4 + 120 * d.count / max,
                      decoration: BoxDecoration(
                        color: d.count == 0 ? scheme.surfaceContainerHighest : scheme.primary,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat.MMMd().format(days.first.day), style: small),
            Text('max $max', style: small),
            Text('Today', style: small),
          ],
        ),
      ],
    );
  }
}
