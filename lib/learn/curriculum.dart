import 'dart:convert';

import 'package:flutter/services.dart';

import '../data/db.dart';

class TopicUnit {
  const TopicUnit({required this.id, required this.title, required this.titleKo, required this.emoji});
  final String id;
  final String title;
  final String titleKo;
  final String emoji;

  factory TopicUnit.fromJson(Map<String, dynamic> j) => TopicUnit(
        id: j['id'] as String,
        title: j['title'] as String,
        titleKo: j['titleKo'] as String,
        emoji: j['emoji'] as String,
      );
}

const myWordsUnit = TopicUnit(id: customUnit, title: 'My words', titleKo: '내 단어', emoji: '✏️');

/// Units in recommended order: survival phrases first, then word topics, "My words" last.
Future<List<TopicUnit>> loadCurriculum([AssetBundle? bundle]) async {
  final b = bundle ?? rootBundle;
  final phrases = (jsonDecode(await b.loadString('assets/data/phrases.json'))['units'] as List).cast<Map<String, dynamic>>();
  final units = (jsonDecode(await b.loadString('assets/data/curriculum.json'))['units'] as List).cast<Map<String, dynamic>>();
  return [...phrases.map(TopicUnit.fromJson), ...units.map(TopicUnit.fromJson), myWordsUnit];
}

bool isPhraseUnit(String unitId) => unitId.startsWith('phrases_');

class TopicLesson {
  const TopicLesson({required this.unitId, required this.index, required this.words, this.intermediate = false});
  final String unitId;
  final int index;
  final List<Word> words;

  /// A "Level 2" lesson of 중급 words (after the unit's beginner lessons).
  final bool intermediate;

  String get id => lessonId(unitId, index);
  static String lessonId(String unitId, int index) => 'topic:$unitId:$index';
  static String challengeId(String unitId) => 'challenge:$unitId';
}

const wordsPerLesson = 8;

/// Splits a unit's words (already in learning order) into lessons of 8. A word whose Korean
/// spelling is already in the current lesson (homographs like 이 "this" / 이 "two") waits for the
/// next one, so no lesson asks to tell two identical words apart. A short tail merges backwards.
List<TopicLesson> buildTopicLessons(String unitId, List<Word> words) {
  // Beginner (and own) words first, then 중급 as Level 2 — so beginner lesson ids never shift.
  var level1 = words.where((w) => w.level != intermediateLevel).toList();
  var level2 = words.where((w) => w.level == intermediateLevel).toList();
  if (level2.length < wordsPerLesson ~/ 2) {
    // A Level 2 of 1–3 words isn't worth a lesson: they join the end of the path.
    level1 = [...level1, ...level2];
    level2 = [];
  }
  final beginner = _chunk(level1);
  final inter = _chunk(level2);
  return [
    for (final (i, c) in beginner.indexed) TopicLesson(unitId: unitId, index: i, words: c),
    for (final (i, c) in inter.indexed) TopicLesson(unitId: unitId, index: beginner.length + i, words: c, intermediate: true),
  ];
}

const intermediateLevel = '중급';

List<List<Word>> _chunk(List<Word> words) {
  final chunks = <List<Word>>[];
  final pending = [...words];
  while (pending.isNotEmpty) {
    final chunk = <Word>[];
    final spellings = <String>{};
    for (var i = 0; i < pending.length && chunk.length < wordsPerLesson;) {
      if (spellings.add(pending[i].word)) {
        chunk.add(pending.removeAt(i));
      } else {
        i++;
      }
    }
    chunks.add(chunk);
  }
  if (chunks.length > 1 && chunks.last.length < wordsPerLesson ~/ 2) {
    // Spread a short tail over the nearest earlier lessons that don't already have that spelling.
    final tail = chunks.removeLast();
    for (final w in tail) {
      final home = chunks.reversed.firstWhere((c) => c.every((p) => p.word != w.word), orElse: () => chunks.last);
      home.add(w);
    }
  }
  return chunks;
}
