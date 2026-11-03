import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korean_cards/data/db.dart';
import 'package:korean_cards/game/game_service.dart';
import 'package:korean_cards/grammar/hangul.dart';
import 'package:korean_cards/learn/exercises.dart';
import 'package:korean_cards/learn/lesson_screen.dart';
import 'package:korean_cards/providers.dart';
import 'package:korean_cards/settings.dart';
import 'package:korean_cards/talk/dialogue.dart';
import 'package:korean_cards/talk/replies.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';
import 'study_screen_test.dart' show SilentSound, SilentTts;

void main() {
  final situations = parseReplies(File('assets/data/replies.json').readAsStringSync());
  final scenes = parseScenes(File('assets/data/dialogues.json').readAsStringSync());

  test('quick replies are short, translated, with decoys that are not part of the answer', () {
    expect(situations.map((s) => s.id).toSet().length, situations.length);
    final items = [for (final s in situations) ...s.items];
    expect(items.length, greaterThanOrEqualTo(140));
    for (final i in items) {
      final chips = replyTokens(i.a);
      expect(chips.length, inInclusiveRange(2, 5), reason: i.a);
      expect(i.qEn.trim(), isNotEmpty, reason: i.q);
      expect(i.en.trim(), isNotEmpty, reason: i.a);
      expect(i.extra, hasLength(2), reason: i.a);
      for (final e in i.extra) {
        expect(chips, isNot(contains(e)), reason: '${i.a}: $e');
        expect(isHangul(e), isTrue, reason: '${i.a}: $e');
      }
      for (final alt in i.alt) {
        expect([...replyTokens(alt)]..sort(), [...chips]..sort(), reason: alt);
      }
    }
  });

  test('chips drop punctuation; any listed word order is accepted', () {
    expect(replyTokens('네, 정말 재미있었어요. 민지 씨는요?'), ['네', '정말', '재미있었어요', '민지', '씨는요']);
    final e = const ReplyItem(
      q: '반찬 더 드릴까요?',
      qEn: 'More side dishes?',
      a: '네, 김치 좀 더 주세요.',
      en: 'Yes, a bit more kimchi please.',
      extra: ['덜', '마셔요'],
      alt: ['네, 김치 더 좀 주세요.'],
    ).toExercise(Random(1));
    expect([...e.tiles]..sort(), ['김치', '네', '더', '덜', '마셔요', '좀', '주세요']..sort());
    expect(e.accepts(['네', '김치', '좀', '더', '주세요']), isTrue);
    expect(e.accepts(['네', '김치', '더', '좀', '주세요']), isTrue);
    expect(e.accepts(['네', '김치', '좀', '덜', '주세요']), isFalse);
    expect(e.focusWordId, isNull, reason: 'replies have no word to star');
  });

  test('role-play lines become chips with decoys from your other lines; long lines stay a choice', () {
    final rng = Random(4);
    var built = 0;
    for (final scene in scenes) {
      for (final (i, line) in scene.lines.indexed) {
        if (!line.isYou) continue;
        final e = replyFromScene(scene, i, rng);
        final chips = replyTokens(line.ko);
        if (chips.length > maxReplyChips || chips.length < 2) {
          expect(e, isNull, reason: line.ko);
          continue;
        }
        built++;
        expect(e!.reply, line.ko);
        expect(e.english, line.en);
        expect(e.accepts(chips), isTrue, reason: line.ko);
        final decoys = [...e.tiles];
        for (final c in chips) {
          decoys.remove(c);
        }
        expect(decoys.length, lessThanOrEqualTo(2), reason: line.ko);
        expect(decoys.any(chips.contains), isFalse, reason: line.ko);
      }
    }
    expect(built, greaterThan(50));

    const long = Scene(
      id: 'x', index: 0, title: 'x', titleKo: 'x', emoji: 'x', partner: 'A', phraseIds: [], grammarIds: [],
      lines: [
        DialogueLine(speaker: 'A', ko: '뭐 했어요?', en: 'What did you do?'),
        DialogueLine(speaker: 'B', ko: '어제 친구하고 같이 시내에 가서 영화를 보고 밥을 먹었어요.', en: 'Long.'),
      ],
    );
    expect(replyFromScene(long, 1, rng), isNull);
  });

  testWidgets('build a reply from chips: correct shows the translation', (tester) async {
    SharedPreferences.setMockInitialValues({'autoPlay': false});
    final prefs = await SharedPreferences.getInstance();
    final db = await tester.runAsync(() => seededDb(3)) as AppDatabase;
    final tts = SilentTts();
    final item = situations.firstWhere((s) => s.id == 'friend').items.firstWhere((i) => i.q == '주말에 뭐 했어요?');
    await tester.pumpWidget(ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        dbProvider.overrideWithValue(db),
        ttsProvider.overrideWithValue(tts),
        soundProvider.overrideWithValue(SilentSound()),
        gameProvider.overrideWithValue(GameService(db)),
      ],
      child: MaterialApp(
        home: LessonScreen(
          title: 'Replies',
          exercises: [item.toExercise(Random(1))],
          onComplete: (s) async => AwardOutcome(xp: s.xp),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('주말에 뭐 했어요?'), findsOneWidget);
    expect(tts.spoken, ['주말에 뭐 했어요?'], reason: 'the other person speaks first');
    await tester.tap(find.text('Show English'));
    await tester.pump();
    expect(find.text('What did you do on the weekend?'), findsOneWidget);

    for (final chip in ['영화', '봤어요']) {
      await tester.tap(find.text(chip).last);
      await tester.pump();
    }
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.text('I watched a movie.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.text('Correct answer:'), findsNothing);
    expect(tts.spoken.last, '영화 봤어요.');
    await tester.runAsync(db.close);
  });
}
