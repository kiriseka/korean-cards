import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:korean_cards/data/db.dart';
import 'package:korean_cards/game/badges.dart';
import 'package:korean_cards/grammar/conjugator.dart';
import 'package:korean_cards/grammar/grammar_content.dart';
import 'package:korean_cards/grammar/hangul.dart';
import 'package:korean_cards/learn/curriculum.dart';
import 'package:korean_cards/learn/exercises.dart';

/// The bundled words.json as database rows.
List<Word> bundledWords() {
  final items = (jsonDecode(File('assets/data/words.json').readAsStringSync())['words'] as List).cast<Map<String, dynamic>>();
  return [
    for (final w in items)
      Word(
        id: w['id'] as int,
        word: w['word'] as String,
        homonym: w['homonym'] as int,
        pos: w['pos'] as String,
        level: w['level'] as String,
        hanja: w['hanja'] as String?,
        pronunciation: w['pronunciation'] as String?,
        category: w['category'] as String?,
        senses: jsonEncode(w['senses']),
        rank: w['rank'] as int,
        isCustom: false,
        starred: false,
        unit: w['unit'] as String?,
        forms: w['forms'] == null ? null : jsonEncode(w['forms']),
      ),
  ];
}

void main() {
  final units = parseGrammar(File('assets/data/grammar.json').readAsStringSync());
  final lessons = [for (final u in units) ...u.lessons];
  final words = bundledWords();

  test('grammar ids are unique and the badge units exist', () {
    expect(units.map((u) => u.id).toSet().length, units.length);
    expect(lessons.map((l) => l.id).toSet().length, lessons.length);
    for (final unit in ['particles', 'tenses', 'endings']) {
      expect(units.any((u) => u.id == unit), isTrue, reason: unit);
    }
    expect(lessons.length, greaterThanOrEqualTo(35));
    final grammarUnits = {for (final u in units) u.id: [for (final l in u.lessons) l.progressId]};
    final allDone = GameStats(completedLessons: {for (final l in lessons) l.progressId}, grammarUnits: grammarUnits);
    expect(badges.firstWhere((b) => b.id == 'particles').earned(allDone), isTrue);
  });

  test('every lesson has learn cards and well-formed practice', () {
    for (final l in lessons) {
      final where = 'lesson ${l.id}';
      expect(l.cards, isNotEmpty, reason: where);
      for (final c in l.cards) {
        expect(c.title.trim(), isNotEmpty, reason: where);
        for (final e in c.examples) {
          expect(isHangul(e.ko), isTrue, reason: '$where example ${e.ko}');
          expect(e.en.trim(), isNotEmpty, reason: '$where example ${e.ko}');
        }
        for (final row in c.table) {
          expect(row.length, c.table.first.length, reason: '$where table row $row');
        }
      }
      expect(l.practice.length + l.drills.length, greaterThanOrEqualTo(3), reason: where);
      for (final item in l.practice) {
        final type = item['type'];
        expect(['build', 'choice', 'meaning', 'quiz'], contains(type), reason: '$where $item');
        if (type == 'build') {
          final tiles = (item['ko'] as String).split(' ');
          expect(tiles.length, greaterThanOrEqualTo(2), reason: '$where ${item['ko']}');
          expect((item['en'] as String).trim(), isNotEmpty);
          for (final extra in (item['extra'] as List).cast<String>()) {
            expect(tiles, isNot(contains(extra)), reason: '$where extra "$extra" is also an answer tile');
          }
        } else {
          final options = (item['options'] as List).cast<String>();
          expect(options.length, greaterThanOrEqualTo(2), reason: '$where $item');
          expect(options.toSet().length, options.length, reason: '$where duplicate options $options');
          if (type == 'choice') expect(item['q'] as String, contains('___'), reason: '$where $item');
          if (type == 'meaning') expect(isHangul(item['ko'] as String), isTrue, reason: '$where $item');
        }
      }
      for (final d in l.drills) {
        if (d['forms'] != null) {
          for (final f in d['forms'] as List) {
            expect(Form.values.map((v) => v.name), contains(f), reason: '$where drill form $f');
          }
        } else {
          expect(['topic', 'subject', 'object', 'and', 'direction', 'copula'], contains(d['particle']), reason: where);
        }
      }
    }
  });

  test('every grammar lesson builds its practice from the real word list', () {
    for (final seed in [1, 2, 3]) {
      final builder = GrammarExerciseBuilder(words: words, random: Random(seed));
      for (final l in lessons) {
        final ex = builder.lessonPractice(l, typingOn: true);
        final drillTarget = l.drills.fold(0, (s, d) => s + (d['count'] as int));
        final drills = ex.length - l.practice.length;
        expect(drills, greaterThanOrEqualTo(drillTarget), reason: '${l.id}: expected $drillTarget drill items');
        for (final e in ex.whereType<ChoiceExercise>()) {
          expect(e.options.toSet().length, e.options.length, reason: '${l.id} ${e.prompt} ${e.options}');
          expect(e.answer, inInclusiveRange(0, e.options.length - 1));
        }
      }
    }
  });

  test('topic lessons: 8 words, no repeated spelling within a lesson', () {
    final byUnit = <String, List<Word>>{};
    for (final w in words) {
      byUnit.putIfAbsent(w.unitId, () => []).add(w);
    }
    final curriculum = (jsonDecode(File('assets/data/curriculum.json').readAsStringSync())['units'] as List).cast<Map<String, dynamic>>();
    for (final u in curriculum) {
      final unitWords = byUnit[u['id']] ?? [];
      expect(unitWords.length, greaterThanOrEqualTo(wordsPerLesson), reason: u['id'] as String);
      final built = buildTopicLessons(u['id'] as String, unitWords..sort((a, b) => a.rank.compareTo(b.rank)));
      expect(built.fold(0, (s, l) => s + l.words.length), unitWords.length, reason: 'every word in a lesson');
      for (final l in built) {
        expect(l.words.map((w) => w.word).toSet().length, l.words.length, reason: '${l.id} repeats a spelling');
        expect(l.words.length, inInclusiveRange(4, wordsPerLesson + 3), reason: l.id);
      }
    }
  });

  test('topic practice covers every word with valid exercises', () {
    final gen = ExerciseGenerator(pool: words, random: Random(7));
    final food = words.where((w) => w.unit == 'food').toList()..sort((a, b) => a.rank.compareTo(b.rank));
    for (final lesson in buildTopicLessons('food', food).take(10)) {
      final ex = gen.topicPractice(lesson.words, typingOn: true);
      expect(ex.length, inInclusiveRange(10, 16));
      final covered = {for (final e in ex) ...e.wordIds};
      expect(covered, containsAll(lesson.words.map((w) => w.id)), reason: lesson.id);
      for (final e in ex.whereType<ChoiceExercise>()) {
        expect(e.options.toSet().length, 4, reason: '${e.prompt}: ${e.options}');
      }
    }
  });
}
