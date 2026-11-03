import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../game/rules.dart';
import '../../learn/lesson_screen.dart';
import '../../learn/topic_lesson.dart';
import '../../providers.dart';
import '../../talk/dialogue.dart';
import '../../talk/replies.dart';
import 'dialogue_screen.dart';

/// Quick replies, then conversation scenes. All are open; the first unfinished scene is suggested.
class TalkView extends ConsumerWidget {
  const TalkView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenes = ref.watch(scenesProvider).value;
    final situations = ref.watch(repliesProvider).value ?? const <ReplySituation>[];
    final progress = ref.watch(lessonProgressProvider).value ?? const {};
    if (scenes == null) return const Center(child: CircularProgressIndicator());
    final current = scenes.indexWhere((s) => !progress.containsKey(s.progressId));
    final theme = Theme.of(context);
    final heading = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
      children: [
        Card.filled(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '🗣️ Real conversations. Listen, understand, repeat your lines, then play your part — '
              'the app speaks the other person and checks what you say.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        if (situations.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('💬 Quick replies', style: heading),
          Text('Someone talks to you: tap the words to answer.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: situations.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _SituationCard(
                situation: situations[i],
                stars: progress[situations[i].progressId]?.stars,
                onTap: () => openQuickReplies(context, ref, situations[i]),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('🎭 Scenes', style: heading),
        ],
        const SizedBox(height: 8),
        for (final s in scenes)
          () {
            final p = progress[s.progressId];
            final isCurrent = s.index == current;
            return Card(
              color: isCurrent ? theme.colorScheme.primaryContainer : null,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Text(s.emoji, style: const TextStyle(fontSize: 32)),
                title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${s.titleKo} · ${s.lines.length} lines · with ${s.partner}'),
                trailing: p != null
                    ? _Stars(p.stars)
                    : isCurrent
                        ? Text('START', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold))
                        : null,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => DialogueScreen(scene: s))),
              ),
            );
          }(),
      ],
    );
  }
}

/// A situation's replies in random order, as a lesson with stars.
Future<void> openQuickReplies(BuildContext context, WidgetRef ref, ReplySituation situation) {
  final rng = Random();
  final items = [...situation.items]..shuffle(rng);
  return Navigator.of(context).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => LessonScreen(
      title: '${situation.emoji} ${situation.title}',
      exercises: [for (final item in items) item.toExercise(rng)],
      onComplete: (s) async {
        final game = ref.read(gameProvider);
        await game.recordLesson(situation.progressId, stars: s.stars, accuracy: s.accuracy);
        return game.award([
          ...sessionActivities(game, s),
          game.activity(ActivityKind.lesson,
              xp: s.perfect ? Xp.perfectLesson : Xp.lesson, value: (s.accuracy * 100).round(), ref: situation.progressId),
        ]);
      },
    ),
  ));
}

class _SituationCard extends StatelessWidget {
  const _SituationCard({required this.situation, required this.stars, required this.onTap});
  final ReplySituation situation;
  final int? stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 124,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(situation.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 4),
              Text(situation.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (stars != null)
                _Stars(stars!)
              else
                Text('${situation.items.length} replies', style: theme.textTheme.bodySmall),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars(this.stars);
  final int stars;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < 3; i++)
          Icon(Icons.star_rounded, size: 18, color: i < stars ? Colors.amber : Theme.of(context).colorScheme.outlineVariant),
      ]);
}
