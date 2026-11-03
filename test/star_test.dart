import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korean_cards/data/db.dart';
import 'package:korean_cards/features/drill/drill_screen.dart';
import 'package:korean_cards/game/game_service.dart';
import 'package:korean_cards/learn/drill.dart';
import 'package:korean_cards/learn/exercises.dart';
import 'package:korean_cards/learn/lesson_screen.dart';
import 'package:korean_cards/providers.dart';
import 'package:korean_cards/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'drill_test.dart' show food, topicDb;
import 'helpers.dart';
import 'study_screen_test.dart' show SilentSound, SilentTts;

Future<void> _pump(WidgetTester tester, AppDatabase db, Widget home) async {
  SharedPreferences.setMockInitialValues({'autoPlay': false});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      dbProvider.overrideWithValue(db),
      ttsProvider.overrideWithValue(SilentTts()),
      soundProvider.overrideWithValue(SilentSound()),
      gameProvider.overrideWithValue(GameService(db)),
    ],
    child: MaterialApp(home: home),
  ));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
  await tester.pumpAndSettle();
}

void main() {
  test('only exercises about one word offer a star', () {
    const meaning = ChoiceExercise(
        instruction: '', prompt: '사과', style: PromptStyle.korean, options: ['a', 'b'], answer: 0, wordIds: [1]);
    const reply = ChoiceExercise(
        instruction: '', prompt: '뭐요?', style: PromptStyle.dialogue, options: ['a', 'b'], answer: 0, wordIds: [1]);
    expect(meaning.focusWordId, 1);
    expect(reply.focusWordId, isNull);
    expect(const MatchExercise(pairs: [], wordIds: [1, 2]).focusWordId, isNull);
    expect(const TypingExercise(prompt: 'apple', answer: '사과', wordIds: [1]).focusWordId, 1);
    expect(const SpeakExercise(target: '사과', mode: SpeakMode.sayIt, wordIds: [1]).focusWordId, 1);
    expect(const SpeakExercise(target: '사과가 맛있어요', mode: SpeakMode.shadow, wordIds: [1]).focusWordId, isNull);
  });

  testWidgets('star a word on a drill card: it joins the Starred pile', (tester) async {
    final db = await tester.runAsync(topicDb) as AppDatabase;
    await _pump(tester, db, DrillScreen(drill: food, options: const DrillOptions(size: null), random: Random(1)));
    await _settle(tester);

    expect(find.text('사과'), findsOneWidget);
    await tester.tap(find.byTooltip('Star'));
    await _settle(tester);
    expect(find.byTooltip('Unstar'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget, reason: 'starring does not flip or move on');

    final rows = await tester.runAsync(() => db.watchDrillCounts().first);
    expect(Drill.starredWords.tally(rows!).total, 1);
    final starred = await tester.runAsync(() => Drill.starredWords.load(db, const DrillOptions(size: null)));
    expect([for (final c in starred!) c.word.word], ['사과']);

    // The next card has its own star.
    await tester.tap(find.text('Learned'));
    await _settle(tester);
    expect(find.text('학교'), findsOneWidget);
    expect(find.byTooltip('Star'), findsOneWidget);

    await tester.runAsync(db.close);
  });

  testWidgets('lesson header shows a star for word questions, not for sentences', (tester) async {
    final db = await tester.runAsync(() => seededDb(3)) as AppDatabase;
    await _pump(
      tester,
      db,
      LessonScreen(
        title: 'Test',
        exercises: const [
          ChoiceExercise(
            instruction: 'What does this mean?',
            prompt: '사과',
            style: PromptStyle.korean,
            options: ['apple', 'school', 'water', 'book'],
            answer: 0,
            wordIds: [100],
          ),
          SentenceExercise(english: 'I eat rice.', answer: ['밥을', '먹어요'], tiles: ['먹어요', '밥을']),
        ],
        onComplete: (s) async => AwardOutcome(xp: s.xp),
      ),
    );
    await _settle(tester);

    await tester.tap(find.byTooltip('Star'));
    await _settle(tester);
    expect(find.byTooltip('Unstar'), findsOneWidget);
    final word = await tester.runAsync(() => db.watchWord(100).first);
    expect(word!.starred, isTrue);

    await tester.tap(find.text('apple'));
    await _settle(tester);
    await tester.tap(find.text('Continue'));
    await _settle(tester);
    expect(find.text('Build the sentence'), findsOneWidget);
    expect(find.byTooltip('Star'), findsNothing);
    expect(find.byTooltip('Unstar'), findsNothing);
    await tester.runAsync(db.close);
  });
}
