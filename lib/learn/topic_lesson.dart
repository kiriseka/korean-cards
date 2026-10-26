import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db.dart';
import '../game/game_service.dart';
import '../game/rules.dart';
import '../providers.dart';
import '../settings.dart';
import '../srs/scheduler.dart';
import '../widgets/common.dart';
import 'curriculum.dart';
import 'exercises.dart';
import 'lesson_screen.dart';
import 'session.dart';

/// Puts a lesson's new words into spaced repetition as if rated "Good" once.
Future<void> markWordsLearned(WidgetRef ref, List<int> wordIds) async {
  final db = ref.read(dbProvider);
  final scheduler = ref.read(schedulerProvider);
  final now = DateTime.now();
  for (final card in await db.newForwardCards(wordIds)) {
    final outcome = scheduler.preview(card, now)[Rating.good]!;
    await db.saveReview(
      outcome.card,
      ReviewLogsCompanion.insert(
        cardId: card.id,
        rating: Rating.good.fsrsRating.value,
        stateBefore: card.state,
        reviewedAt: now,
        elapsedMs: 0,
      ),
    );
  }
}

/// The activities every finished exercise session earns: answers, combo, sentences.
List<ActivitiesCompanion> sessionActivities(GameService game, ExerciseSession s) => [
      if (s.xp > 0) game.activity(ActivityKind.answer, xp: s.xp, value: s.correctFirstTry),
      if (s.bestCombo > 0) game.activity(ActivityKind.combo, value: s.bestCombo),
      if (s.sentencesBuilt > 0) game.activity(ActivityKind.sentence, value: s.sentencesBuilt),
      if (s.spoken > 0) game.activity(ActivityKind.spoken, value: s.spoken),
    ];

Future<bool?> openTopicLesson(BuildContext context, WidgetRef ref, TopicLesson lesson, TopicUnit unit) async {
  final pool = await ref.read(allWordsProvider.future);
  if (!context.mounted) return null;
  final generator = ExerciseGenerator(pool: pool);
  final settings = ref.read(settingsProvider);
  final exercises = generator.topicPractice(lesson.words, typingOn: settings.typingExercises, speakingOn: settings.speakingExercises);
  return Navigator.of(context).push<bool>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => LessonScreen(
      title: '${unit.title} ${lesson.index + 1}',
      exercises: exercises,
      intro: (context, start) => MeetWordsView(words: lesson.words, onStart: start),
      onComplete: (s) async {
        final game = ref.read(gameProvider);
        await game.recordLesson(lesson.id, stars: s.stars, accuracy: s.accuracy);
        await markWordsLearned(ref, [for (final w in lesson.words) w.id]);
        return game.award([
          ...sessionActivities(game, s),
          game.activity(ActivityKind.lesson,
              xp: s.perfect ? Xp.perfectLesson : Xp.lesson, value: (s.accuracy * 100).round(), ref: lesson.id),
        ]);
      },
    ),
  ));
}

/// 20 questions over the whole unit; three mistakes and it's over.
Future<bool?> openUnitChallenge(BuildContext context, WidgetRef ref, TopicUnit unit, List<Word> words) async {
  final pool = await ref.read(allWordsProvider.future);
  if (!context.mounted) return null;
  final exercises = ExerciseGenerator(pool: pool).quiz(words, 20);
  return Navigator.of(context).push<bool>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => LessonScreen(
      title: '${unit.title} challenge',
      exercises: exercises,
      hearts: 3,
      onComplete: (s) async {
        final game = ref.read(gameProvider);
        if (!s.failed) {
          await game.recordLesson(TopicLesson.challengeId(unit.id), stars: s.stars, accuracy: s.accuracy);
        }
        return game.award([
          ...sessionActivities(game, s),
          if (!s.failed) game.activity(ActivityKind.challenge, xp: Xp.challenge, value: 1, ref: unit.id),
        ]);
      },
    ),
  ));
}

/// Swipe through the lesson's words before practising.
class MeetWordsView extends ConsumerStatefulWidget {
  const MeetWordsView({super.key, required this.words, required this.onStart});
  final List<Word> words;
  final VoidCallback onStart;

  @override
  ConsumerState<MeetWordsView> createState() => _MeetWordsViewState();
}

class _MeetWordsViewState extends ConsumerState<MeetWordsView> {
  final _pages = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak(0));
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _speak(int i) {
    if (ref.read(settingsProvider).autoPlay) ref.speak(widget.words[i].word);
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == widget.words.length - 1;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
          child: Row(children: [
            const CloseButton(),
            Expanded(
              child: Text('Meet the words · ${_page + 1}/${widget.words.length}',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            TextButton(onPressed: widget.onStart, child: const Text('Skip')),
          ]),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pages,
            itemCount: widget.words.length,
            onPageChanged: (i) {
              setState(() => _page = i);
              _speak(i);
            },
            itemBuilder: (_, i) => Padding(padding: const EdgeInsets.all(20), child: WordIntroCard(word: widget.words[i])),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: last
                ? widget.onStart
                : () => _pages.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
            child: Text(last ? "Let's practise! 💪" : 'Next', style: const TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }
}

class WordIntroCard extends StatelessWidget {
  const WordIntroCard({super.key, required this.word});
  final Word word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sense = word.senseList.firstOrNull;
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(word.word, style: theme.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w700)),
            ),
            SpeakButton(word.word, size: 40),
            if (word.pronunciation != null && word.pronunciation != word.word)
              Text('[${word.pronunciation}]', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(word.gloss, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [TagChip(word.pos), if (word.hanja != null) TagChip(word.hanja!)]),
            if (sense?.example != null) ...[
              const Divider(height: 40),
              Row(children: [
                Expanded(child: Text(sense!.example!, style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic))),
                SpeakButton(sense.example!, size: 24),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
