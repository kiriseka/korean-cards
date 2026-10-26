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
  const TopicLesson({required this.unitId, required this.index, required this.words});
  final String unitId;
  final int index;
  final List<Word> words;

  String get id => lessonId(unitId, index);
  static String lessonId(String unitId, int index) => 'topic:$unitId:$index';
  static String challengeId(String unitId) => 'challenge:$unitId';
}

const wordsPerLesson = 8;

/// Splits a unit's words (already in learning order) into lessons of 8. A word whose Korean
/// spelling is already in the current lesson (homographs like 이 "this" / 이 "two") waits for the
/// next one, so no lesson asks to tell two identical words apart. A short tail merges backwards.
List<TopicLesson> buildTopicLessons(String unitId, List<Word> words) {
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
    final tail = chunks.last;
    final prev = chunks[chunks.length - 2];
    if (tail.every((w) => prev.every((p) => p.word != w.word))) {
      prev.addAll(chunks.removeLast());
    }
  }
  return [for (final (i, c) in chunks.indexed) TopicLesson(unitId: unitId, index: i, words: c)];
}
