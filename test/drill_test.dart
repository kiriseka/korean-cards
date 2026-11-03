import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korean_cards/data/db.dart';
import 'package:korean_cards/data/word_importer.dart';
import 'package:korean_cards/features/drill/drill_screen.dart';
import 'package:korean_cards/game/game_service.dart';
import 'package:korean_cards/learn/curriculum.dart';
import 'package:korean_cards/learn/drill.dart';
import 'package:korean_cards/providers.dart';
import 'package:korean_cards/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';
import 'study_screen_test.dart' show SilentSound, SilentTts;

/// 사과 and 학교 in "food" (beginner), 물 in "food" (Level 2), 책 in "home".
Future<AppDatabase> topicDb() async {
  final db = memoryDb();
  await importWords(db, [
    {...wordJson(100, '사과', rank: 1), 'unit': 'food'},
    {...wordJson(101, '학교', rank: 2), 'unit': 'food'},
    {...wordJson(102, '물', rank: 3), 'unit': 'food', 'level': '중급'},
    {...wordJson(103, '책', rank: 4), 'unit': 'home'},
  ]);
  return db;
}

const food = Drill(id: 'topic:food', title: 'Food', emoji: '🍚', unit: 'food');

void main() {
  test('drill decks filter by topic, level and pile; tallies add up', () async {
    final db = await topicDb();
    List<String> names(List<CardWithWord> cards) => [for (final c in cards) c.word.word];

    expect(names(await food.load(db, const DrillOptions(size: null))), ['사과', '학교', '물']);
    expect(names(await food.load(db, const DrillOptions(level: '초급', size: null))), ['사과', '학교']);
    expect(names(await Drill.intermediate.load(db, const DrillOptions(size: null))), ['물']);
    expect(names(await food.load(db, const DrillOptions(size: 2))), ['사과', '학교']);

    await db.setPile(100, Pile.learned);
    await db.setPile(101, Pile.hard);
    expect(names(await food.load(db, const DrillOptions(size: null))), ['학교', '물'], reason: 'learned words are skipped');
    expect(names(await food.load(db, const DrillOptions(skipLearned: false, size: null))), ['사과', '학교', '물']);
    expect(names(await Drill.hard.load(db, const DrillOptions(size: null))), ['학교']);
    expect(names(await Drill.learned.load(db, const DrillOptions(size: null))), ['사과'], reason: 'never skips itself');
    expect(names(await food.load(db, const DrillOptions(size: null), except: [101])), ['물']);

    final rows = await db.watchDrillCounts().first;
    final tally = food.tally(rows);
    expect((tally.total, tally.learned, tally.hard), (3, 1, 1));
    expect(food.tally(rows, onlyLevel: '중급').total, 1);
    expect(Drill.hard.tally(rows).total, 1);
    expect(Drill.topic(const TopicUnit(id: 'home', title: 'Home', titleKo: '집', emoji: '🏠')).tally(rows).total, 1);
    await db.close();
  });

  testWidgets('swipe a topic deck, then re-drill just the hard ones', (tester) async {
    SharedPreferences.setMockInitialValues({'autoPlay': false});
    final prefs = await SharedPreferences.getInstance();
    final db = await tester.runAsync(topicDb) as AppDatabase;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        dbProvider.overrideWithValue(db),
        ttsProvider.overrideWithValue(SilentTts()),
        gameProvider.overrideWithValue(GameService(db)),
        soundProvider.overrideWithValue(SilentSound()),
      ],
      child: MaterialApp(home: DrillScreen(drill: food, options: const DrillOptions(size: null), random: Random(1))),
    ));
    Future<void> settle() async {
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
    }

    await settle();
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('사과'), findsOneWidget);
    await tester.drag(find.text('사과'), const Offset(500, 0));
    await settle();
    await tester.drag(find.text('학교'), const Offset(-500, 0));
    await settle();
    await tester.tap(find.text('Hard'));
    await settle();

    expect(find.text('수고했어요!'), findsOneWidget);
    expect(find.text('Drill the 2 hard ones'), findsOneWidget);
    expect(find.textContaining('Next'), findsNothing, reason: 'the whole deck was in this round');

    await tester.tap(find.text('Drill the 2 hard ones'));
    await settle();
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(find.text('Learned'));
    await settle();
    await tester.tap(find.text('Learned'));
    await settle();
    expect(find.text('완벽해요! 🎉'), findsOneWidget);

    final logs = await tester.runAsync(() => db.select(db.reviewLogs).get());
    expect(logs, hasLength(3), reason: 're-drill rounds only move words between piles');
    final words = await tester.runAsync(() => db.select(db.words).get());
    expect(words!.where((w) => w.unit == 'food').map((w) => w.pile).toSet(), {Pile.learned});
    await tester.runAsync(db.close);
  });

  testWidgets('a deck in batches offers the next batch', (tester) async {
    SharedPreferences.setMockInitialValues({'autoPlay': false});
    final prefs = await SharedPreferences.getInstance();
    final db = await tester.runAsync(topicDb) as AppDatabase;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        dbProvider.overrideWithValue(db),
        ttsProvider.overrideWithValue(SilentTts()),
        gameProvider.overrideWithValue(GameService(db)),
        soundProvider.overrideWithValue(SilentSound()),
      ],
      child: MaterialApp(home: DrillScreen(drill: food, options: const DrillOptions(size: 2, skipLearned: false))),
    ));
    Future<void> settle() async {
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
    }

    await settle();
    expect(find.text('1 / 2'), findsOneWidget);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Learned'));
      await settle();
    }
    await tester.tap(find.text('Next 1 word'));
    await settle();
    expect(find.text('물'), findsOneWidget);
    await tester.runAsync(db.close);
  });
}
