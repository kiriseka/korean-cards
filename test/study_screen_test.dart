import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korean_cards/data/db.dart';
import 'package:korean_cards/features/study/study_screen.dart';
import 'package:korean_cards/game/game_service.dart';
import 'package:korean_cards/game/sound_service.dart';
import 'package:korean_cards/providers.dart';
import 'package:korean_cards/services/tts_service.dart';
import 'package:korean_cards/settings.dart';
import 'package:korean_cards/srs/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

class SilentSound extends SoundService {
  @override
  Future<void> play(Sfx sfx) async {}
}

class SilentTts extends TtsService {
  final spoken = <String>[];

  @override
  Future<bool> get koreanAvailable async => true;

  @override
  Future<void> speak(String text, {required double rate, double pitch = 1.0}) async => spoken.add(text);

  @override
  Future<void> stop() async {}
}

void main() {
  testWidgets('flip, swipe right, mark hard, the hard card comes back, then the summary', (tester) async {
    SharedPreferences.setMockInitialValues({'newPerDay': 2});
    final prefs = await SharedPreferences.getInstance();
    final db = await tester.runAsync(() => seededDb(3)) as AppDatabase;
    final tts = SilentTts();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        dbProvider.overrideWithValue(db),
        ttsProvider.overrideWithValue(tts),
        gameProvider.overrideWithValue(GameService(db)),
        soundProvider.overrideWithValue(SilentSound()),
      ],
      child: const MaterialApp(home: StudyScreen()),
    ));
    Future<void> settle() async {
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
    }

    await settle();
    expect(find.text('사과'), findsOneWidget);
    expect(tts.spoken, ['사과']);

    // Tapping flips the card to its meaning, and back.
    await tester.tap(find.text('Tap to see the meaning'));
    await tester.pumpAndSettle();
    expect(find.text('thing'), findsOneWidget);

    // Swipe right: learned.
    await tester.drag(find.text('사과'), const Offset(500, 0));
    await settle();
    expect(find.text('학교'), findsOneWidget);

    // A short drag springs back without counting.
    await tester.drag(find.text('학교'), const Offset(-60, 0));
    await settle();
    expect(find.text('학교'), findsOneWidget);

    await tester.tap(find.text('Hard'));
    await settle();
    expect(find.text('학교'), findsOneWidget, reason: 'a hard card comes back in the same session');

    await tester.tap(find.text('Learned'));
    await settle();
    expect(find.text('수고했어요!'), findsOneWidget);
    expect(find.textContaining('2 learned · 1 hard'), findsOneWidget);

    final logs = await tester.runAsync(() => db.select(db.reviewLogs).get());
    expect(logs!.map((l) => l.rating), [Rating.good, Rating.again, Rating.good].map((r) => r.fsrsRating.value));
    final words = await tester.runAsync(() => db.select(db.words).get());
    expect({for (final w in words!) w.word: w.pile}, {'사과': Pile.learned, '학교': Pile.learned, '물': null});
    final xp = await tester.runAsync(() => GameService(db).totalXp());
    expect(xp, 5, reason: '2 XP per learned swipe, 1 per hard one');
    await tester.runAsync(db.close);
  });
}
