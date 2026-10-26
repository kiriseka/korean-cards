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
  Future<void> speak(String text, {required double rate}) async => spoken.add(text);

  @override
  Future<void> stop() async {}
}

void main() {
  testWidgets('show answer, rate Good, next card appears, then the summary', (tester) async {
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
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
    }

    await settle();
    expect(find.text('사과'), findsOneWidget);
    expect(tts.spoken, ['사과']);

    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();
    expect(find.text('thing'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);

    await tester.tap(find.text('Easy'));
    await settle();
    expect(find.text('학교'), findsOneWidget);

    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Easy'));
    await settle();
    expect(find.text('수고했어요!'), findsOneWidget);

    final logs = await tester.runAsync(() => db.select(db.reviewLogs).get());
    expect(logs, hasLength(2));
    final xp = await tester.runAsync(() => GameService(db).totalXp());
    expect(xp, 4, reason: '2 XP per Easy review');
    await tester.runAsync(db.close);
  });
}
