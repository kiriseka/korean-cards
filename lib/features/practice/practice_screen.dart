import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../learn/exercises.dart';
import '../../learn/lesson_screen.dart';
import '../../learn/numbers.dart';
import '../../learn/skill_service.dart';
import '../../learn/skills.dart';
import '../../learn/topic_lesson.dart';
import '../../providers.dart';
import '../../settings.dart';
import '../play/play_screen.dart';

final trickyWordsProvider = StreamProvider<List<Word>>((ref) => ref.watch(dbProvider).watchTrickyWords());

/// Exercises for a skill round: sentence practice for grammar, the numbers trainer for numbers.
Future<List<Exercise>> skillExercises(WidgetRef ref, Map<String, int> plan) async {
  final gen = await ref.read(sentenceGenProvider.future);
  final rows = await ref.read(skillServiceProvider).rows();
  final s = ref.read(settingsProvider);
  final numbers = NumbersTrainer();
  final out = <Exercise>[];
  for (final MapEntry(key: id, value: n) in plan.entries) {
    for (var i = 0; i < n; i++) {
      out.add(skillsById[id]!.group == SkillGroup.numbers
          ? numbers.forSkill(id, mastery: SkillService.mastery(rows[id]), speakingOn: s.speakingExercises)
          : gen.forSkill(id, typingOn: s.typingExercises, speakingOn: s.speakingExercises));
    }
  }
  return out..shuffle(Random());
}

/// A Gym or numbers round: due skills first, then the weakest (or one chosen skill).
Future<void> openSkillRound(BuildContext context, WidgetRef ref, {required Set<SkillGroup> groups, String? only, required String title}) async {
  final plan = await ref.read(skillServiceProvider).pickRound(only: only, groups: groups);
  final exercises = await skillExercises(ref, plan);
  if (!context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => LessonScreen(
      title: title,
      exercises: exercises,
      onComplete: (s) async {
        final game = ref.read(gameProvider);
        return game.award([...sessionActivities(game, s), game.activity(ActivityKind.gym, value: plan.length)]);
      },
    ),
  ));
}

/// Words and skills missed this week, until each is answered right twice.
Future<void> openMistakesSession(BuildContext context, WidgetRef ref) async {
  final (wordIds, skillIds) = await ref.read(mistakeServiceProvider).recent();
  final all = await ref.read(allWordsProvider.future);
  final byId = {for (final w in all) w.id: w};
  final gen = ExerciseGenerator(pool: all);
  final words = wordIds.map((id) => byId[id]).whereType<Word>().take(8).toList();
  final exercises = <Exercise>[
    for (final w in words) ...[gen.meaning(w), gen.reverse(w)],
    ...await skillExercises(ref, {for (final s in skillIds.take(4)) s: 2}),
  ]..shuffle(Random());
  if (!context.mounted || exercises.isEmpty) return;
  await Navigator.of(context).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => LessonScreen(
      title: 'Fix my mistakes',
      exercises: exercises,
      onComplete: (s) async {
        final game = ref.read(gameProvider);
        return game.award([...sessionActivities(game, s), game.activity(ActivityKind.fixed, value: 1)]);
      },
    ),
  ));
}

/// Words forgotten again and again: meet them once more, then drill them.
Future<void> openTrickySession(BuildContext context, WidgetRef ref, List<Word> tricky) async {
  final all = await ref.read(allWordsProvider.future);
  final gen = ExerciseGenerator(pool: all);
  final words = ([...tricky]..shuffle()).take(6).toList();
  final typing = ref.read(settingsProvider).typingExercises;
  final exercises = <Exercise>[
    for (final w in words) ...[gen.meaning(w), gen.reverse(w), gen.listening(w), if (typing && w.word.length <= 4) gen.typing(w)],
  ]..shuffle(Random());
  if (!context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => LessonScreen(
      title: 'Tricky words',
      exercises: exercises,
      intro: (context, start) => MeetWordsView(words: words, onStart: start),
      onComplete: (s) async {
        final game = ref.read(gameProvider);
        return game.award(sessionActivities(game, s));
      },
    ),
  ));
}

/// Practice hub: Grammar Gym, numbers, mistakes, tricky words and the arcade games.
class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  double _groupMastery(Map<String, SkillRow> rows, SkillGroup g) {
    final list = skills.where((s) => s.group == g).toList();
    return list.fold(0.0, (sum, s) => sum + SkillService.mastery(rows[s.id])) / list.length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(skillRowsProvider).value ?? const {};
    final mistakes = ref.watch(openMistakesProvider).value ?? const [];
    final tricky = ref.watch(trickyWordsProvider).value ?? const [];
    final now = DateTime.now();
    int due(Set<SkillGroup> g) => skills.where((s) => g.contains(s.group) && SkillService.isDue(rows[s.id], now)).length;
    final grammar = {SkillGroup.particles, SkillGroup.tenses};
    return Scaffold(
      appBar: AppBar(title: const Text('연습 · Practice')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HubCard(
            emoji: '💪',
            title: 'Grammar Gym',
            subtitle: 'Particles 은/는 · 이/가 · 을/를 · 에 · 에서 and verb tenses, in real sentences',
            progress: (_groupMastery(rows, SkillGroup.particles) + _groupMastery(rows, SkillGroup.tenses)) / 2,
            badge: due(grammar) > 0 ? '${due(grammar)} due' : null,
            color: const Color(0xFF1E88E5),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const SkillGroupScreen(title: '💪 Grammar Gym', groups: [SkillGroup.particles, SkillGroup.tenses]),
            )),
          ),
          _HubCard(
            emoji: '🔢',
            title: 'Numbers & money',
            subtitle: 'Prices, time, age and counters — both number systems',
            progress: _groupMastery(rows, SkillGroup.numbers),
            badge: due({SkillGroup.numbers}) > 0 ? '${due({SkillGroup.numbers})} due' : null,
            color: const Color(0xFF43A047),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const SkillGroupScreen(title: '🔢 Numbers & money', groups: [SkillGroup.numbers]),
            )),
          ),
          _HubCard(
            emoji: '🩹',
            title: 'Fix my mistakes',
            subtitle: mistakes.isEmpty ? 'Nothing to fix — nice!' : 'Get each one right twice to clear it',
            badge: mistakes.isEmpty ? null : '${mistakes.length}',
            color: const Color(0xFFE53935),
            onTap: mistakes.isEmpty ? null : () => openMistakesSession(context, ref),
          ),
          _HubCard(
            emoji: '😵‍💫',
            title: 'Tricky words',
            subtitle: tricky.isEmpty ? 'Words you keep forgetting will show up here' : 'Words you\'ve forgotten 4+ times — meet them again',
            badge: tricky.isEmpty ? null : '${tricky.length}',
            color: const Color(0xFF8E24AA),
            onTap: tricky.isEmpty ? null : () => openTrickySession(context, ref, tricky),
          ),
          _HubCard(
            emoji: '🎮',
            title: 'Arcade games',
            subtitle: 'Speed Round, Match Madness, Listening, Sentence Builder, Spelling Bee, Echo',
            color: const Color(0xFFFB8C00),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlayScreen())),
          ),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({required this.emoji, required this.title, required this.subtitle, required this.color, this.onTap, this.progress, this.badge});
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final double? progress;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.04)])),
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                      child: Text(badge!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                ]),
                Text(subtitle),
                if (progress != null) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress, minHeight: 6, borderRadius: BorderRadius.circular(3), color: color),
                  Text('${(progress! * 100).round()}% mastered', style: theme.textTheme.bodySmall),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Skill meters for one or more groups; train them all (due + weakest) or one at a time.
class SkillGroupScreen extends ConsumerWidget {
  const SkillGroupScreen({super.key, required this.title, required this.groups});
  final String title;
  final List<SkillGroup> groups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(skillRowsProvider).value ?? const {};
    final theme = Theme.of(context);
    final now = DateTime.now();
    final due = skills.where((s) => groups.contains(s.group) && SkillService.isDue(rows[s.id], now)).map((s) => s.label).toList();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60)),
            icon: const Icon(Icons.fitness_center),
            label: const Text('Train (12 exercises)', style: TextStyle(fontSize: 18)),
            onPressed: () => openSkillRound(context, ref, groups: groups.toSet(), title: title.substring(title.indexOf(' ') + 1)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 12),
            child: Text(due.isEmpty ? 'Nothing due — training your weakest skills.' : 'Due for review: ${due.join(', ')}',
                style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ),
          for (final g in groups) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text('${g.emoji} ${g.title}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            for (final s in skills.where((s) => s.group == g))
              Card(
                child: ListTile(
                  title: Row(children: [
                    Text(s.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    if (SkillService.isDue(rows[s.id], now))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                        decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
                        child: const Text('due', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                  ]),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.hint),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: SkillService.mastery(rows[s.id]),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                      color: SkillService.mastery(rows[s.id]) >= 0.8 ? Colors.amber : Colors.green,
                    ),
                  ]),
                  trailing: Text('${(SkillService.mastery(rows[s.id]) * 100).round()}%'),
                  onTap: () => openSkillRound(context, ref, groups: {g}, only: s.id, title: s.label),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
