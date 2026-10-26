import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../game/badges.dart';
import '../../game/rules.dart';
import '../../providers.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final overview = ref.watch(overviewProvider).value;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('나 · Me'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      Text(profile.level.title.emoji, style: const TextStyle(fontSize: 64)),
                      Text('Level ${profile.level.level} · ${profile.level.title.korean}',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      Text(profile.level.title.english, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: profile.level.progress, minHeight: 12, borderRadius: BorderRadius.circular(6), color: Colors.amber),
                      const SizedBox(height: 4),
                      Text('${profile.level.xpIntoLevel} / ${profile.level.xpForLevel} XP · ${profile.totalXp} XP total'),
                      const SizedBox(height: 12),
                      _NextTitle(level: profile.level.level),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  _Tile(emoji: '🔥', value: '${profile.streak.days}', label: 'day streak'),
                  _Tile(emoji: '🧊', value: '${profile.streak.freezes}/${StreakInfo.maxFreezes}', label: 'streak freezes'),
                  _Tile(emoji: '📚', value: '${(overview?.known ?? 0) + (overview?.young ?? 0) + (overview?.learning ?? 0)}', label: 'words learned'),
                ]),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('🧊 You earn a streak freeze every 7 days in a row (max 2). It saves your streak if you miss a day.',
                      style: theme.textTheme.bodySmall),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Text('Badges', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${profile.badges.length} / ${badges.length}'),
                ]),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.8,
                  children: [for (final b in badges) _BadgeTile(badge: b, unlockedAt: profile.badges[b.id])],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  icon: const Icon(Icons.insights),
                  label: const Text('Detailed stats'),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatsScreen())),
                ),
              ],
            ),
    );
  }
}

class _NextTitle extends StatelessWidget {
  const _NextTitle({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    final next = levelTitles.where((t) => t.fromLevel > level).firstOrNull;
    if (next == null) return const Text('👑 Highest title reached!');
    return Text('Next title at level ${next.fromLevel}: ${next.emoji} ${next.korean} (${next.english})',
        textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall);
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.emoji, required this.value, required this.label});
  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card.outlined(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ),
      );
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.unlockedAt});
  final GameBadge badge;
  final DateTime? unlockedAt;

  @override
  Widget build(BuildContext context) {
    final earned = unlockedAt != null;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${badge.emoji}  ${badge.title}'),
          content: Text(earned ? '${badge.description}\n\nEarned ${DateFormat.yMMMd().format(unlockedAt!)}' : badge.description),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: earned ? Colors.amber.withValues(alpha: 0.18) : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: earned ? Colors.amber : Colors.transparent, width: 2),
        ),
        padding: const EdgeInsets.all(6),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Opacity(opacity: earned ? 1 : 0.25, child: Text(badge.emoji, style: const TextStyle(fontSize: 30))),
          const SizedBox(height: 4),
          Text(badge.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
        ]),
      ),
    );
  }
}
