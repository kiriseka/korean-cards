import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../learn/exercises.dart';
import 'dialogue.dart';

/// Someone says [q]; you answer [a] by tapping its words in order.
class ReplyItem {
  const ReplyItem({
    required this.q,
    required this.qEn,
    required this.a,
    required this.en,
    required this.extra,
    this.alt = const [],
  });

  final String q;
  final String qEn;

  /// The reply as written, with punctuation.
  final String a;
  final String en;

  /// Wrong chips: the same kind of word as the right ones (a wrong verb, a wrong particle).
  final List<String> extra;

  /// Other word orders that are right too.
  final List<String> alt;

  ReplyExercise toExercise(Random rng) => ReplyExercise(
        prompt: q,
        promptEnglish: qEn,
        reply: a,
        english: en,
        tiles: [...replyTokens(a), ...extra]..shuffle(rng),
        accepted: alt,
      );
}

/// An everyday situation with about a dozen quick replies.
class ReplySituation {
  const ReplySituation({required this.id, required this.title, required this.titleKo, required this.emoji, required this.items});

  final String id;
  final String title;
  final String titleKo;
  final String emoji;
  final List<ReplyItem> items;

  String get progressId => 'replies:$id';
}

List<ReplySituation> parseReplies(String raw) => [
      for (final s in (jsonDecode(raw)['situations'] as List).cast<Map<String, dynamic>>())
        ReplySituation(
          id: s['id'] as String,
          title: s['title'] as String,
          titleKo: s['titleKo'] as String,
          emoji: s['emoji'] as String,
          items: [
            for (final i in (s['items'] as List).cast<Map<String, dynamic>>())
              ReplyItem(
                q: i['q'] as String,
                qEn: i['qEn'] as String,
                a: i['a'] as String,
                en: i['en'] as String,
                extra: (i['extra'] as List).cast<String>(),
                alt: ((i['alt'] as List?) ?? const []).cast<String>(),
              ),
          ],
        ),
    ];

Future<List<ReplySituation>> loadReplies([AssetBundle? bundle]) async =>
    parseReplies(await (bundle ?? rootBundle).loadString('assets/data/replies.json'));

final repliesProvider = FutureProvider<List<ReplySituation>>((ref) => loadReplies());

/// Lines longer than this are picked from a list instead of built from chips.
const maxReplyChips = 7;

/// Your line number [index] of a role-play as chips, with two decoy words from your other lines.
/// Null when the line is too long (or too short) to build from chips.
ReplyExercise? replyFromScene(Scene scene, int index, Random rng) {
  final yours = scene.lines[index];
  final answer = replyTokens(yours.ko);
  if (answer.length < 2 || answer.length > maxReplyChips) return null;
  final decoys = <String>{};
  for (final other in [for (final l in scene.yourLines) if (l.ko != yours.ko) l]..shuffle(rng)) {
    for (final token in replyTokens(other.ko)) {
      if (token.length >= 2 && !answer.contains(token)) decoys.add(token);
    }
    if (decoys.length >= 2) break;
  }
  final before = index > 0 ? scene.lines[index - 1] : null;
  return ReplyExercise(
    prompt: before?.ko ?? '',
    promptEnglish: before?.en,
    reply: yours.ko,
    english: yours.en,
    tiles: [...answer, ...decoys.take(2)]..shuffle(rng),
  );
}
