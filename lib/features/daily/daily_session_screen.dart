import 'package:confetti/confetti.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../game/sound_service.dart';
import '../../learn/daily_plan.dart';
import '../../learn/grammar_lesson.dart';
import '../../learn/lesson_screen.dart';
import '../../learn/topic_lesson.dart';
import '../../providers.dart';
import '../../settings.dart';
import '../../talk/dialogue.dart';
import '../home/home_screen.dart';
import '../study/study_screen.dart';
import '../talk/dialogue_screen.dart';

/// Which steps of today's session are done (from today's `daily` activities).
final dailyProgressProvider = StreamProvider<Set<int>>((ref) {
  final db = ref.watch(dbProvider);
  final since = studyDayStart(DateTime.now());
  return (db.select(db.activities)
        ..where((a) => a.kind.equals(ActivityKind.daily) & a.createdAt.isBiggerOrEqualValue(since))
        ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]))
      .watch()
      .map((rows) => {for (final r in rows) r.value});
});

/// The next unfinished conversation scene.
final nextSceneProvider = Provider<Scene?>((ref) {
  final scenes = ref.watch(scenesProvider).value;
  final progress = ref.watch(lessonProgressProvider).value;
  if (scenes == null || progress == null) return null;
  for (final s in scenes) {
    if (!progress.containsKey(s.progressId)) return s;
  }
  return null;
});

class DailySessionScreen extends ConsumerStatefulWidget {
  const DailySessionScreen({super.key});

  @override
  ConsumerState<DailySessionScreen> createState() => _DailySessionScreenState();
}

class _DailySessionScreenState extends ConsumerState<DailySessionScreen> {
  final _confetti = ConfettiController(duration: const Duration(seconds: 3));
  bool _running = false;

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _markDone(DailyStep step) async {
    final game = ref.read(gameProvider);
    final done = {...?ref.read(dailyProgressProvider).value, step.code};
    await game.award([game.activity(ActivityKind.daily, value: step.code)]);
    final allSteps = DailyStep.values.every((s) => done.contains(s.code));
    if (allSteps && !done.contains(DailyStep.completeCode)) {
      await game.award([game.activity(ActivityKind.daily, xp: 25, value: DailyStep.completeCode)]);
      ref.read(soundProvider).play(Sfx.levelup);
      _confetti.play();
    }
  }

  Future<void> _run(DailyStep step) async {
    if (_running) return;
    setState(() => _running = true);
    try {
      final ok = switch (step) {
        DailyStep.review => await _review(),
        DailyStep.speakListen => await _speakListen(),
        DailyStep.learn => await _learn(),
      };
      if (ok == true) await _markDone(step);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<bool?> _review() async {
    final budget = DailyBudget(ref.read(settingsProvider).dailyMinutes);
    final counts = ref.read(todayCountsProvider).value;
    if (counts != null && counts.due + counts.learning + counts.newAvailable == 0) return true;
    await Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => StudyScreen(maxCards: budget.reviewCards),
    ));
    return true;
  }

  Future<bool?> _speakListen() async {
    final settings = ref.read(settingsProvider);
    final all = await ref.read(allWordsProvider.future);
    final learned = await ref.read(learnedWordIdsProvider.future);
    final known = all.where((w) => learned.contains(w.id) && w.pos != 'phrase').toList();
    final common = (all.where((w) => w.pos != 'phrase').toList()..sort((a, b) => a.rank.compareTo(b.rank))).take(150).toList();
    final learnedPhrases = all.where((w) => w.pos == 'phrase' && learned.contains(w.id)).toList();
    final phrases = learnedPhrases.isNotEmpty ? learnedPhrases : (all.where((w) => w.pos == 'phrase').toList()..sort((a, b) => a.rank.compareTo(b.rank))).take(20).toList();
    final exercises = speakListenSet(
      known: known.length >= 15 ? known : [...known, ...common],
      phrases: phrases,
      pool: all,
      count: DailyBudget(settings.dailyMinutes).speakListenItems,
      speakingOn: settings.speakingExercises,
    );
    if (!mounted) return null;
    return Navigator.of(context).push<bool>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => LessonScreen(
        title: 'Speak & listen',
        exercises: exercises,
        onComplete: (s) async {
          final game = ref.read(gameProvider);
          return game.award(sessionActivities(game, s));
        },
      ),
    ));
  }

  Future<bool?> _learn() async {
    final scene = ref.read(nextSceneProvider);
    if (scene != null) {
      return Navigator.of(context).push<bool>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => DialogueScreen(scene: scene)));
    }
    final topic = ref.read(nextTopicLessonProvider);
    if (topic != null) return openTopicLesson(context, ref, topic.$2, topic.$1);
    final grammar = ref.read(nextGrammarLessonProvider);
    if (grammar != null) return openGrammarLesson(context, ref, grammar);
    return true;
  }

  String _learnDetail() {
    final scene = ref.watch(nextSceneProvider);
    if (scene != null) return '${scene.emoji} Conversation: ${scene.title}';
    final topic = ref.watch(nextTopicLessonProvider);
    if (topic != null) return '${topic.$1.emoji} ${topic.$1.title} · lesson ${topic.$2.index + 1}';
    final grammar = ref.watch(nextGrammarLessonProvider);
    if (grammar != null) return '📐 Grammar: ${grammar.title}';
    return 'Free practice';
  }

  @override
  Widget build(BuildContext context) {
    final done = ref.watch(dailyProgressProvider).value ?? const {};
    final minutes = ref.watch(settingsProvider.select((s) => s.dailyMinutes));
    final counts = ref.watch(todayCountsProvider).value;
    final theme = Theme.of(context);
    final next = DailyStep.values.firstWhere((s) => !done.contains(s.code), orElse: () => DailyStep.learn);
    final allDone = done.contains(DailyStep.completeCode);
    final details = {
      DailyStep.review: counts == null
          ? ''
          : '${(counts.due + counts.learning).clamp(0, 999)} due · up to ${DailyBudget(minutes).reviewCards} cards',
      DailyStep.speakListen: '${DailyBudget(minutes).speakListenItems} quick items from words you know',
      DailyStep.learn: _learnDetail(),
    };
    return Scaffold(
      appBar: AppBar(title: Text("오늘의 $minutes분 · Today's session")),
      body: Stack(children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              allDone ? '🎉 Done for today! 대박!' : 'Three short steps. Do them in one go, or one now and the rest later.',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            for (final step in DailyStep.values)
              Card(
                color: done.contains(step.code) ? Colors.green.withValues(alpha: 0.12) : step == next && !allDone ? theme.colorScheme.primaryContainer : null,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Text(done.contains(step.code) ? '✅' : step.emoji, style: const TextStyle(fontSize: 32)),
                  title: Text('${step.index + 1}. ${step.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  subtitle: Text(details[step]!.isEmpty ? step.description : details[step]!),
                  trailing: done.contains(step.code) ? const Text('Again') : const Icon(Icons.play_circle_fill, size: 36),
                  onTap: _running ? null : () => _run(step),
                ),
              ),
            const SizedBox(height: 16),
            if (!allDone)
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60)),
                icon: const Icon(Icons.play_arrow_rounded, size: 30),
                label: Text('Start: ${next.title}', style: const TextStyle(fontSize: 18)),
                onPressed: _running ? null : () => _run(next),
              )
            else
              Card.filled(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('+25 XP bonus earned. Want more? Try a game in Play, or keep going in Learn.', style: theme.textTheme.bodyLarge),
                ),
              ),
          ],
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(confettiController: _confetti, blastDirectionality: BlastDirectionality.explosive, numberOfParticles: 50),
        ),
      ]),
    );
  }
}
