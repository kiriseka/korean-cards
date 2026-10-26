import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korean_cards/data/db.dart';
import 'package:korean_cards/game/game_service.dart';
import 'package:korean_cards/grammar/sentence_gen.dart';
import 'package:korean_cards/learn/lesson_screen.dart';
import 'package:korean_cards/providers.dart';
import 'package:korean_cards/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'content_test.dart' show bundledWords;
import 'helpers.dart';
import 'study_screen_test.dart' show SilentSound, SilentTts;

void main() {
  testWidgets('a Gym round schedules its skill and logs the mistake', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'autoPlay': false});
    final prefs = await SharedPreferences.getInstance();
    final db = await tester.runAsync(() => seededDb(2)) as AppDatabase;
    final frames = Frames(jsonDecode(File('assets/data/sentence_frames.json').readAsStringSync()) as Map<String, dynamic>);
    final gen = SentenceGenerator(frames, bundledWords(), random: Random(4));
    final exercises = [
      for (var i = 0; i < 3; i++) gen.particleChoice(gen.transitive(Tense.past), 'object', 'p_object'),
    ];

    await tester.pumpWidget(ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        dbProvider.overrideWithValue(db),
        ttsProvider.overrideWithValue(SilentTts()),
        soundProvider.overrideWithValue(SilentSound()),
        gameProvider.overrideWithValue(GameService(db)),
      ],
      child: MaterialApp(
        home: LessonScreen(title: 'Grammar Gym', exercises: exercises, onComplete: (s) async => AwardOutcome(xp: s.xp)),
      ),
    ));
    await tester.pumpAndSettle();

    // Right, wrong, right — then the missed one comes back and is answered right.
    final plan = [true, false, true, true];
    for (final right in plan) {
      final e = tester.widget<Text>(find.textContaining('___').first).data!;
      final ex = exercises.firstWhere((x) => x.prompt == e);
      final pick = right ? ex.correct : ex.options.firstWhere((o) => o != ex.correct);
      await tester.tap(find.text(pick).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Grammar Gym complete'), findsOneWidget);

    final skill = await tester.runAsync(() => (db.select(db.skills)..where((s) => s.id.equals('p_object'))).getSingle());
    expect((skill!.correct, skill.attempts), (2, 3));
    final mistakes = await tester.runAsync(() => db.select(db.mistakes).get());
    expect(mistakes!.map((m) => m.skillId), contains('p_object'));
    await tester.runAsync(db.close);
  });
}
