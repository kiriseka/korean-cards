import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../providers.dart';
import '../stats/stats_data.dart';
import '../study/study_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(todayCountsProvider);
    final hasVoice = ref.watch(koreanVoiceProvider).value ?? true;
    final logs = ref.watch(recentLogsProvider).value ?? const [];
    final streak = streakOf(logs, DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('오늘 · Today')),
      body: counts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (c) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!hasVoice) const _NoVoiceBanner(),
            _CountsCard(counts: c),
            const SizedBox(height: 24),
            _StudyButton(counts: c),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _MiniStat(icon: Icons.local_fire_department, label: 'Day streak', value: '$streak')),
                const SizedBox(width: 12),
                Expanded(child: _MiniStat(icon: Icons.check_circle_outline, label: 'Reviewed today', value: '${c.reviewedToday}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CountsCard extends StatelessWidget {
  const _CountsCard({required this.counts});
  final TodayCounts counts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget count(String label, int value, Color color) => Expanded(
          child: Column(
            children: [
              Text('$value', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        child: Row(
          children: [
            count('New', counts.newAvailable, scheme.primary),
            count('Learning', counts.learning, Colors.orange),
            count('Review', counts.due, Colors.green),
          ],
        ),
      ),
    );
  }
}

class _StudyButton extends StatelessWidget {
  const _StudyButton({required this.counts});
  final TodayCounts counts;

  void _open(BuildContext context, {int extraNew = 0}) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => StudyScreen(extraNew: extraNew), fullscreenDialog: true),
      );

  @override
  Widget build(BuildContext context) {
    final total = counts.newAvailable + counts.learning + counts.due;
    if (total > 0) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64), textStyle: const TextStyle(fontSize: 20)),
        icon: const Icon(Icons.play_arrow_rounded, size: 32),
        label: const Text('Study'),
        onPressed: () => _open(context),
      );
    }
    return Column(
      children: [
        Text('🎉  All done for today!', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('Come back tomorrow, or learn a few more words now.'),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.add),
          label: const Text('Learn 5 more words'),
          onPressed: () => _open(context, extraNew: 5),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      );
}

class _NoVoiceBanner extends StatelessWidget {
  const _NoVoiceBanner();

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.errorContainer,
        margin: const EdgeInsets.only(bottom: 16),
        child: const ListTile(
          leading: Icon(Icons.volume_off),
          title: Text('No Korean voice installed'),
          subtitle: Text(
            'To hear words, open Android Settings → System → Languages → Text-to-speech output → '
            'Google → Install voice data → Korean, then restart the app.',
          ),
        ),
      );
}
