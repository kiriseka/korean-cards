import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korean_cards/data/db.dart';
import 'package:korean_cards/data/word_importer.dart';
import 'package:korean_cards/features/talk/dialogue_screen.dart';
import 'package:korean_cards/game/game_service.dart';
import 'package:korean_cards/games/speak_view.dart';
import 'package:korean_cards/grammar/grammar_content.dart';
import 'package:korean_cards/grammar/hangul.dart';
import 'package:korean_cards/learn/daily_plan.dart';
import 'package:korean_cards/learn/exercises.dart';
import 'package:korean_cards/providers.dart';
import 'package:korean_cards/settings.dart';
import 'package:korean_cards/speech/speech_match.dart';
import 'package:korean_cards/speech/speech_service.dart';
import 'package:korean_cards/talk/dialogue.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'content_test.dart' show bundledWords;
import 'helpers.dart';
import 'study_screen_test.dart' show SilentSound, SilentTts;

/// Hears whatever was queued, instantly.
class FakeSpeech implements SpeechService {
  FakeSpeech(this.queue, {this.available = true});
  final List<String> queue;
  final bool available;

  @override
  Future<bool> init() async => available;

  @override
  Future<void> listen({required void Function(String text, bool isFinal) onResult, required void Function() onDone}) async {
    onResult(queue.isEmpty ? '' : queue.removeAt(0), true);
    onDone();
  }

  @override
  Future<void> stop() async {}
}

void main() {
  final phrasesJson = jsonDecode(File('assets/data/phrases.json').readAsStringSync()) as Map<String, dynamic>;
  final phrases = (phrasesJson['phrases'] as List).cast<Map<String, dynamic>>();
  final phraseUnits = {for (final u in phrasesJson['units'] as List) (u as Map)['id'] as String};
  final scenes = parseScenes(File('assets/data/dialogues.json').readAsStringSync());
  final grammarIds = {
    for (final u in parseGrammar(File('assets/data/grammar.json').readAsStringSync())) ...u.lessons.map((l) => l.id),
  };

  group('content', () {
    test('phrases: unique permanent ids, Korean + English, every unit has a full lesson', () {
      final ids = phrases.map((p) => p['id'] as int).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids.every((id) => id > firstPhraseId && id < firstPhraseId + 1000000), isTrue);
      for (final p in phrases) {
        expect(isHangul(p['ko'] as String), isTrue, reason: '$p');
        expect((p['en'] as String).trim(), isNotEmpty, reason: '$p');
        expect(phraseUnits, contains(p['unit']), reason: '$p');
      }
      for (final u in phraseUnits) {
        expect(phrases.where((p) => p['unit'] == u).length, greaterThanOrEqualTo(8), reason: u);
      }
      expect(phrases.length, 150);
    });

    test('dialogues: well-formed scenes whose links resolve', () {
      final phraseIds = phrases.map((p) => p['id']).toSet();
      expect(scenes.map((s) => s.id).toSet().length, scenes.length);
      expect(scenes.length, 24);
      for (final s in scenes) {
        expect(s.lines.length, inInclusiveRange(6, 10), reason: s.id);
        expect(s.yourLines.length, greaterThanOrEqualTo(3), reason: s.id);
        for (final l in s.lines) {
          expect(['A', 'B'], contains(l.speaker), reason: '${s.id}: ${l.ko}');
          expect(isHangul(l.ko), isTrue, reason: '${s.id}: ${l.ko}');
          expect(l.en.trim(), isNotEmpty, reason: '${s.id}: ${l.ko}');
          // Speech matching must score a perfect recitation as perfect.
          expect(matchSpeech(l.ko, l.ko).score, 1.0, reason: l.ko);
        }
        for (final l in s.yourLines) {
          expect(l.ko.replaceAll(RegExp(r'[^가-힣]'), '').length, lessThanOrEqualTo(20), reason: 'say "${l.ko}" in one breath');
        }
        expect(phraseIds, containsAll(s.phraseIds), reason: s.id);
        expect(grammarIds, containsAll(s.grammarIds), reason: s.id);
      }
    });
  });

  group('speaking and listening practice', () {
    final words = bundledWords();
    final phraseWords = [
      for (final w in phrasesToWords(phrases))
        Word(
          id: w['id'] as int,
          word: w['word'] as String,
          homonym: 0,
          pos: 'phrase',
          level: 'phrase',
          senses: jsonEncode(w['senses']),
          rank: w['rank'] as int,
          isCustom: false,
          starred: false,
          unit: w['unit'] as String,
        ),
    ];

    test('the daily set mixes shadowing, replies, dictation and a phrase', () {
      final known = (words.toList()..sort((a, b) => a.rank.compareTo(b.rank))).take(300).toList();
      final set = speakListenSet(known: known, phrases: phraseWords, pool: words, count: 6, speakingOn: true, random: Random(3));
      expect(set, hasLength(6));
      expect(set.whereType<SpeakExercise>(), isNotEmpty);
      expect(set.whereType<DictationExercise>(), isNotEmpty);
      final replies = set.whereType<ChoiceExercise>().where((e) => e.style == PromptStyle.dialogue);
      expect(replies, isNotEmpty);
      for (final r in replies) {
        expect(r.options.toSet().length, r.options.length);
        expect(r.options[r.answer], r.speak);
      }
      for (final d in set.whereType<DictationExercise>()) {
        expect(d.tiles, containsAll(d.answer));
      }
      final silent = speakListenSet(known: known, phrases: phraseWords, pool: words, count: 6, speakingOn: false, random: Random(3));
      expect(silent.whereType<SpeakExercise>(), isEmpty);
    });

    test('budget scales with the session length', () {
      expect(const DailyBudget(10).reviewCards, 24);
      expect(const DailyBudget(15).reviewCards, 36);
      expect(const DailyBudget(15).speakListenItems, 6);
      expect(const DailyBudget(20).speakListenItems, 8);
    });

    test('phrase lessons are speaking-heavy', () {
      final unit = phraseWords.where((w) => w.unit == 'phrases_cafe').take(8).toList();
      final ex = ExerciseGenerator(pool: [...words, ...phraseWords], random: Random(1)).topicPractice(unit, typingOn: false, speakingOn: true);
      expect(ex.whereType<SpeakExercise>().length, 5);
    });
  });

  test('phrases import as words and are practised both ways', () async {
    final db = memoryDb();
    await importWords(db, phrasesToWords(phrases.take(3).toList()));
    final first = (await db.newCards(reverse: false, limit: 1)).single;
    expect(first.word.pos, 'phrase');
    await db.saveReview(
      first.card.copyWith(state: CardState.review, due: DateTime.now().add(const Duration(days: 2)), lastReview: Value(DateTime.now())),
      ReviewLogsCompanion.insert(cardId: first.card.id, rating: 3, stateBefore: 0, reviewedAt: DateTime.now(), elapsedMs: 1),
    );
    final next = await db.newCards(reverse: false, limit: 10);
    expect(next.any((c) => c.word.id == first.word.id && c.card.direction == Direction.enToKo), isTrue,
        reason: 'reverse phrase card unlocks even with reverse cards off');
    await db.close();
  });

  Future<(SharedPreferences, AppDatabase)> setup(WidgetTester tester, Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues({'autoPlay': false, ...prefs});
    final p = await SharedPreferences.getInstance();
    final db = await tester.runAsync(() => seededDb(2)) as AppDatabase;
    return (p, db);
  }

  testWidgets('speak: a close attempt passes and colours the syllables', (tester) async {
    final (prefs, db) = await setup(tester, {});
    bool? result;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        dbProvider.overrideWithValue(db),
        ttsProvider.overrideWithValue(SilentTts()),
        speechProvider.overrideWithValue(FakeSpeech(['감사함니다'])),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SpeakView(
            exercise: const SpeakExercise(target: '감사합니다', mode: SpeakMode.readAloud),
            onAnswer: (ok) => result = ok,
            onSkip: () {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(find.textContaining('Heard: “감사함니다”'), findsOneWidget);
    await tester.runAsync(db.close);
  });

  testWidgets('speak: two misses count as wrong; no recognizer offers "I said it"', (tester) async {
    final (prefs, db) = await setup(tester, {});
    bool? result;
    Widget app(SpeechService speech) => ProviderScope(
          overrides: [
            prefsProvider.overrideWithValue(prefs),
            dbProvider.overrideWithValue(db),
            ttsProvider.overrideWithValue(SilentTts()),
            speechProvider.overrideWithValue(speech),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SpeakView(
                key: UniqueKey(),
                exercise: const SpeakExercise(target: '화장실이 어디예요?', mode: SpeakMode.sayIt, english: "Where's the bathroom?"),
                onAnswer: (ok) => result = ok,
                onSkip: () {},
              ),
            ),
          ),
        );
    await tester.pumpWidget(app(FakeSpeech(['화장실', '어디'])));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pumpAndSettle();
    expect(result, isNull, reason: 'first miss: try again');
    expect(find.textContaining('Almost'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pumpAndSettle();
    expect(result, isFalse);

    result = null;
    await tester.pumpWidget(app(FakeSpeech([], available: false)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I said it ✓'));
    await tester.pump();
    expect(result, isTrue);
    await tester.runAsync(db.close);
  });

  testWidgets('role-play runs to results and records the scene', (tester) async {
    final scene = scenes.firstWhere((s) => s.id == 'paying');
    // A typical phone screen (about 415 x 900 dp) rather than the default 800 x 600 test surface.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    final (prefs, db) = await setup(tester, {'speakingExercises': true});
    final heard = [for (var round = 0; round < 2; round++) ...scene.yourLines.map((l) => l.ko)];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        dbProvider.overrideWithValue(db),
        ttsProvider.overrideWithValue(SilentTts()),
        soundProvider.overrideWithValue(SilentSound()),
        speechProvider.overrideWithValue(FakeSpeech(heard)),
        gameProvider.overrideWithValue(GameService(db)),
      ],
      child: MaterialApp(home: DialogueScreen(scene: scene)),
    ));
    Future<void> settle([int seconds = 2]) async {
      for (var i = 0; i < seconds * 4; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    await settle(4);
    await tester.tap(find.text('Next'));
    await settle();
    await tester.tap(find.text('Next'));
    await settle();
    // Shadow each of your lines.
    for (var i = 0; i < scene.yourLines.length; i++) {
      await tester.tap(find.byIcon(Icons.mic_rounded));
      await settle(1);
      await tester.tap(find.textContaining(i == scene.yourLines.length - 1 ? 'Start the role-play' : 'Next line'));
      await settle(1);
    }
    // Role-play: the partner speaks, you answer.
    for (var i = 0; i < scene.yourLines.length; i++) {
      await settle(2);
      await tester.tap(find.byIcon(Icons.mic_rounded));
      await settle(1);
      await tester.tap(find.text('Continue'));
    }
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await settle(1);
    }
    expect(find.textContaining('You said ${scene.yourLines.length} of ${scene.yourLines.length} lines'), findsOneWidget);
    final progress = await tester.runAsync(() => db.select(db.lessonProgress).get());
    expect(progress!.single.lessonId, scene.progressId);
    expect(progress.single.stars, 3);
    await tester.runAsync(db.close);
  });
}
