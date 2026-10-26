import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korean_cards/data/db.dart';
import 'package:korean_cards/game/game_service.dart';
import 'package:korean_cards/learn/exercises.dart';
import 'package:korean_cards/learn/lesson_screen.dart';
import 'package:korean_cards/learn/session.dart';
import 'package:korean_cards/learn/topic_lesson.dart';
import 'package:korean_cards/providers.dart';
import 'package:korean_cards/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';
import 'study_screen_test.dart' show SilentSound, SilentTts;

const choice = ChoiceExercise(
  instruction: 'What does this mean?',
  prompt: '사과',
  style: PromptStyle.korean,
  options: ['apple', 'school', 'water', 'book'],
  answer: 0,
);
const sentence = SentenceExercise(
  english: 'I eat rice.',
  answer: ['저는', '밥을', '먹어요'],
  tiles: ['먹어요', '밥을', '물을', '저는'],
);

void main() {
  testWidgets('lesson: right answer, wrong sentence then retried, results with stars', (tester) async {
    SharedPreferences.setMockInitialValues({'autoPlay': false});
    final prefs = await SharedPreferences.getInstance();
    final db = await tester.runAsync(() => seededDb(3)) as AppDatabase;
    final game = GameService(db);
    ExerciseSession? finished;

    await tester.pumpWidget(ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        dbProvider.overrideWithValue(db),
        ttsProvider.overrideWithValue(SilentTts()),
        soundProvider.overrideWithValue(SilentSound()),
        gameProvider.overrideWithValue(game),
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          home: LessonScreen(
            title: 'Test lesson',
            exercises: const [choice, sentence],
            onComplete: (s) async {
              finished = s;
              return AwardOutcome(xp: s.xp);
            },
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // 1. Multiple choice, right.
    await tester.tap(find.text('apple'));
    await tester.pumpAndSettle();
    expect(find.textContaining('+5 XP'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // 2. Sentence builder, wrong order.
    for (final t in ['밥을', '저는', '먹어요']) {
      await tester.tap(find.text(t).last);
      await tester.pump();
    }
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.text('Correct answer:'), findsOneWidget);
    expect(find.text('저는 밥을 먹어요'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // 3. The missed sentence comes back; this time in order.
    for (final t in ['저는', '밥을', '먹어요']) {
      await tester.tap(find.text(t).last);
      await tester.pump();
    }
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    // Results run confetti, which never "settles"; pump a few seconds instead.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(finished, isNotNull);
    expect((finished!.correctFirstTry, finished!.mistakes, finished!.sentencesBuilt), (1, 1, 1));
    expect(find.text('Test lesson complete'), findsOneWidget);
    expect(find.textContaining('50%'), findsOneWidget);
    expect(find.text('+${finished!.xp}'), findsOneWidget);
    expect(sessionActivities(game, finished!).map((a) => a.kind.value), ['answer', 'combo', 'sentence']);
    await tester.runAsync(db.close);
  });

  testWidgets('words from a finished topic lesson enter spaced repetition', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = await tester.runAsync(() => seededDb(3)) as AppDatabase;
    late WidgetRef widgetRef;
    await tester.pumpWidget(ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs), dbProvider.overrideWithValue(db)],
      child: MaterialApp(home: Consumer(builder: (context, ref, _) {
        widgetRef = ref;
        return const SizedBox();
      })),
    ));
    await tester.runAsync(() => markWordsLearned(widgetRef, [100, 101]));
    final cards = await tester.runAsync(() => db.select(db.cards).get());
    final forward = cards!.where((c) => c.direction == Direction.koToEn);
    expect(forward.where((c) => c.state != CardState.newCard).map((c) => c.wordId).toSet(), {100, 101});
    expect(await tester.runAsync(() => db.newIntroducedSince(studyDayStart(DateTime.now()))), 2);
    await tester.runAsync(db.close);
  });
}
