import 'dart:math';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../game/game_service.dart';
import '../../grammar/grammar_content.dart';
import '../../learn/curriculum.dart';
import '../../learn/exercises.dart';
import '../../learn/grammar_lesson.dart';
import '../../learn/lesson_screen.dart';
import '../../learn/topic_lesson.dart';
import '../../providers.dart';
import 'echo_screen.dart';
import 'match_madness_screen.dart';
import 'speed_round_screen.dart';

class ArcadeGame {
  const ArcadeGame(this.id, this.emoji, this.title, this.description, this.color);
  final String id;
  final String emoji;
  final String title;
  final String description;
  final Color color;
}

const arcadeGames = [
  ArcadeGame('speed', '⚡', 'Speed Round', '60 seconds. As many right answers as you can.', Color(0xFFFB8C00)),
  ArcadeGame('match', '🧩', 'Match Madness', 'Match pairs against the clock.', Color(0xFF8E24AA)),
  ArcadeGame('listen', '🎧', 'Listening Challenge', 'Hear it, pick it. 10 rounds.', Color(0xFF1E88E5)),
  ArcadeGame('sentences', '🏗️', 'Sentence Builder', 'Build sentences from your grammar lessons.', Color(0xFF43A047)),
  ArcadeGame('spell', '🐝', 'Spelling Bee', 'Type the Korean word. 10 rounds.', Color(0xFFE53935)),
  ArcadeGame('echo', '🦜', 'Echo', 'Repeat as many sentences as you can in 2 minutes. 🎤', Color(0xFF00897B)),
];

/// Best score per game.
final bestScoresProvider = StreamProvider<Map<String, int>>((ref) {
  final db = ref.watch(dbProvider);
  return (db.select(db.activities)
        ..where((a) => a.kind.equals(ActivityKind.game))
        ..orderBy([(a) => OrderingTerm.desc(a.value)]))
      .watch()
      .map((rows) {
    final best = <String, int>{};
    for (final r in rows) {
      best.putIfAbsent(r.ref ?? '', () => r.value);
    }
    return best;
  });
});

/// Which words the arcade plays with.
enum PoolKind { learned, topic, mine }

class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  PoolKind _pool = PoolKind.learned;
  String _topic = 'food';

  Future<List<Word>> _words() async {
    final all = await ref.read(allWordsProvider.future);
    switch (_pool) {
      case PoolKind.learned:
        final learned = await ref.read(learnedWordIdsProvider.future);
        final words = all.where((w) => learned.contains(w.id)).toList();
        if (words.length >= 12) return words;
        // Not enough yet: top up with the most common words.
        final common = [...all]..sort((a, b) => a.rank.compareTo(b.rank));
        return {...words, ...common.take(40)}.toList();
      case PoolKind.topic:
        return all.where((w) => w.unitId == _topic).toList();
      case PoolKind.mine:
        return all.where((w) => w.isCustom).toList();
    }
  }

  Future<void> _start(ArcadeGame game) async {
    final words = await _words();
    if (!mounted) return;
    if (game.id != 'sentences' && words.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick a pool with at least 6 words')));
      return;
    }
    final pool = await ref.read(allWordsProvider.future);
    if (!mounted) return;
    final gen = ExerciseGenerator(pool: pool);
    final rng = Random();
    switch (game.id) {
      case 'speed':
        await Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => SpeedRoundScreen(words: words, generator: gen)));
      case 'match':
        await Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => MatchMadnessScreen(words: words, generator: gen)));
      case 'listen':
        // Mix word listening with "pick the natural reply" rounds from KRDict mini dialogues.
        final picks = ([...words]..shuffle(rng)).take(10).toList();
        final bank = SentenceBank.fromWords(words);
        final dialogues = [...bank.dialogues]..shuffle(rng);
        final others = [for (final d in SentenceBank.fromWords(pool).dialogues) d.$1];
        final rounds = <Exercise>[];
        for (final (i, w) in picks.indexed) {
          final reply = i % 3 == 2 && dialogues.isNotEmpty ? gen.reply(dialogues.removeLast().$1, others) : null;
          rounds.add(reply ?? gen.listening(w, pickKorean: i.isEven));
        }
        await _runLessonGame(game, rounds);
      case 'echo':
        await Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => EchoScreen(words: words)));
      case 'spell':
        final picks = (words.where((w) => w.word.length <= 5).toList()..shuffle(rng)).take(10).toList();
        await _runLessonGame(game, [for (final w in picks) gen.typing(w)]);
      case 'sentences':
        final exercises = await _sentenceItems(rng);
        if (mounted) await _runLessonGame(game, exercises);
    }
  }

  /// Sentences from grammar lessons already finished (or the first unit, to get started).
  Future<List<Exercise>> _sentenceItems(Random rng) async {
    final units = await ref.read(grammarProvider.future);
    final progress = ref.read(lessonProgressProvider).value ?? const {};
    final lessons = [for (final u in units) ...u.lessons];
    var done = lessons.where((l) => progress.containsKey(l.progressId)).toList();
    if (done.isEmpty) done = units.first.lessons;
    final builder = GrammarExerciseBuilder(words: const [], random: rng);
    final items = [for (final l in done) ...l.buildItems]..shuffle(rng);
    return [for (final item in items.take(8)) builder.fromItem(item)];
  }

  Future<void> _runLessonGame(ArcadeGame game, List<Exercise> exercises) => Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LessonScreen(
          title: game.title,
          exercises: exercises,
          onComplete: (s) async {
            final g = ref.read(gameProvider);
            return g.award([
              ...sessionActivities(g, s),
              g.activity(ActivityKind.game, value: s.correctFirstTry, ref: game.id),
            ]);
          },
        ),
      ));

  @override
  Widget build(BuildContext context) {
    final best = ref.watch(bestScoresProvider).value ?? const {};
    final units = ref.watch(curriculumProvider).value ?? const <TopicUnit>[];
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('놀이 · Play')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Play with', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ChoiceChip(label: const Text('📚 Words I learned'), selected: _pool == PoolKind.learned, onSelected: (_) => setState(() => _pool = PoolKind.learned)),
              ChoiceChip(label: const Text('✏️ My words'), selected: _pool == PoolKind.mine, onSelected: (_) => setState(() => _pool = PoolKind.mine)),
              ChoiceChip(label: const Text('🗂️ A topic'), selected: _pool == PoolKind.topic, onSelected: (_) => setState(() => _pool = PoolKind.topic)),
              if (_pool == PoolKind.topic)
                DropdownButton<String>(
                  value: _topic,
                  items: [
                    for (final u in units.where((u) => u.id != customUnit))
                      DropdownMenuItem(value: u.id, child: Text('${u.emoji} ${u.title}')),
                  ],
                  onChanged: (v) => setState(() => _topic = v!),
                ),
            ],
          ),
          const SizedBox(height: 16),
          for (final g in arcadeGames)
            Card(
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _start(g),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [g.color.withValues(alpha: 0.25), g.color.withValues(alpha: 0.05)]),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Text(g.emoji, style: const TextStyle(fontSize: 44)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(g.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        Text(g.description),
                        if (best[g.id] != null) Text('🏅 Best: ${best[g.id]}', style: TextStyle(color: g.color, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                    Icon(Icons.play_circle_fill, size: 40, color: g.color),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shown at the end of a timed game.
class GameOverView extends StatelessWidget {
  const GameOverView({super.key, required this.title, required this.score, required this.best, required this.outcome, required this.onAgain});
  final String title;
  final int score;
  final int? best;
  final AwardOutcome outcome;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final record = best == null || score > best!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const Spacer(),
        Text(record && score > 0 ? '🏆' : '🐯', style: const TextStyle(fontSize: 80)),
        Text(record && score > 0 ? '신기록! New best!' : '수고했어요!', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 24),
        Text('$score', style: theme.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        Text(best == null ? 'First game!' : 'Best before: $best'),
        const SizedBox(height: 12),
        Text('+${outcome.xp} XP', style: TextStyle(fontSize: 22, color: Colors.amber.shade800, fontWeight: FontWeight.bold)),
        for (final b in outcome.badges) ListTile(leading: Text(b.emoji, style: const TextStyle(fontSize: 28)), title: Text('New badge: ${b.title}')),
        const Spacer(),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          icon: const Icon(Icons.replay),
          label: const Text('Play again', style: TextStyle(fontSize: 18)),
          onPressed: onAgain,
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ]),
    );
  }
}
