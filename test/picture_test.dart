import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korean_cards/data/db.dart';
import 'package:korean_cards/game/game_service.dart';
import 'package:korean_cards/learn/curriculum.dart';
import 'package:korean_cards/learn/exercises.dart';
import 'package:korean_cards/learn/lesson_screen.dart';
import 'package:korean_cards/learn/pictures.dart';
import 'package:korean_cards/providers.dart';
import 'package:korean_cards/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'content_test.dart' show bundledWords;
import 'helpers.dart';
import 'study_screen_test.dart' show SilentSound, SilentTts;

void main() {
  final raw = File('assets/data/pictures.json').readAsStringSync();
  final pictures = parsePictures(raw);
  final words = bundledWords();
  final byId = {for (final w in words) w.id: w};

  test('every picture points at the bundled word it names, with its own emoji', () {
    final entries = (jsonDecode(raw)['pictures'] as List).cast<Map<String, dynamic>>();
    expect(entries.length, greaterThanOrEqualTo(150));
    for (final p in entries) {
      expect(byId[p['id']]?.word, p['word'], reason: '${p['id']}');
    }
    expect(pictures.values.toSet().length, pictures.length, reason: 'one word per emoji');
  });

  test('picture questions: four different pictures, the right one, never a same-spelled word', () {
    final gen = ExerciseGenerator(pool: words, pictures: pictures, random: Random(3));
    final emojiToWord = {for (final e in pictures.entries) e.value: byId[e.key]!};
    for (final id in pictures.keys) {
      final w = byId[id]!;
      final e = gen.picture(w)!;
      expect(e.options.toSet().length, 4, reason: w.word);
      expect(e.correct, pictures[id], reason: w.word);
      expect(e.focusWordId, id);
      for (final (i, emoji) in e.options.indexed) {
        if (i != e.answer) expect(emojiToWord[emoji]!.word, isNot(w.word), reason: '${w.word} vs $emoji');
      }
      final back = gen.pictureToWord(w)!;
      expect(back.options.toSet().length, 4, reason: w.word);
      expect(back.correct, w.word);
      expect(back.style, PromptStyle.picture);
    }
  });

  test('colours are asked among colours, not red apples', () {
    final gen = ExerciseGenerator(pool: words, pictures: pictures, random: Random(1));
    final red = words.firstWhere((w) => w.word == '빨간색');
    final colours = {for (final w in words) if (w.category == red.category && pictures.containsKey(w.id)) pictures[w.id]};
    for (var i = 0; i < 20; i++) {
      expect(colours.containsAll(gen.picture(red)!.options), isTrue);
    }
  });

  test('words without a picture get none; Picture Pick mixes the three kinds', () {
    final gen = ExerciseGenerator(pool: words, pictures: pictures, random: Random(2));
    final noPicture = words.firstWhere((w) => !pictures.containsKey(w.id));
    expect(gen.picture(noPicture), isNull);
    expect(gen.pictureToWord(noPicture), isNull);

    final pictured = [for (final w in words) if (pictures.containsKey(w.id)) w];
    final game = gen.pictureGame([...pictured.take(10), noPicture], 10);
    expect(game, hasLength(10));
    expect(game.whereType<PictureExercise>().where((e) => e.listen), hasLength(2));
    expect(game.whereType<ChoiceExercise>(), hasLength(2));
  });

  test('topic lessons swap up to two meaning questions for pictures, keeping their length', () {
    final food = [for (final w in words) if (w.unit == 'food') w]..sort((a, b) => a.rank.compareTo(b.rank));
    final lesson = buildTopicLessons('food', food).first;
    final withPictures = ExerciseGenerator(pool: words, pictures: pictures, random: Random(5))
        .topicPractice(lesson.words, typingOn: false);
    final without = ExerciseGenerator(pool: words, random: Random(5)).topicPractice(lesson.words, typingOn: false);
    final count = withPictures.whereType<PictureExercise>().length;
    expect(count, inInclusiveRange(1, 2));
    expect(withPictures.length, without.length);
    expect(without.whereType<PictureExercise>(), isEmpty);
  });

  testWidgets('tap the right picture: the word and its meaning show', (tester) async {
    SharedPreferences.setMockInitialValues({'autoPlay': false});
    final prefs = await SharedPreferences.getInstance();
    final db = await tester.runAsync(() => seededDb(3)) as AppDatabase;
    final tts = SilentTts();
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
          title: 'Pictures',
          exercises: const [
            PictureExercise(word: '빵', english: 'bread', options: ['🍎', '🍞', '🐱', '🚗'], answer: 1, wordIds: [100]),
          ],
          onComplete: (s) async => AwardOutcome(xp: s.xp),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Pick the right picture'), findsOneWidget);
    await tester.tap(find.text('🍞'));
    await tester.pumpAndSettle();
    expect(find.text('빵 = bread'), findsOneWidget);
    expect(find.text('Correct answer:'), findsNothing);
    expect(tts.spoken, ['빵']);
    await tester.runAsync(db.close);
  });
}
