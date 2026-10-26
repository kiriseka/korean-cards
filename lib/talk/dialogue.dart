import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DialogueLine {
  const DialogueLine({required this.speaker, required this.ko, required this.en});

  /// "A" (your partner) or "B" (you).
  final String speaker;
  final String ko;
  final String en;

  bool get isYou => speaker == 'B';
}

class Scene {
  const Scene({
    required this.id,
    required this.index,
    required this.title,
    required this.titleKo,
    required this.emoji,
    required this.partner,
    required this.lines,
    required this.phraseIds,
    required this.grammarIds,
  });

  final String id;
  final int index;
  final String title;
  final String titleKo;
  final String emoji;
  final String partner;
  final List<DialogueLine> lines;
  final List<int> phraseIds;
  final List<String> grammarIds;

  String get progressId => 'dialogue:$id';
  List<DialogueLine> get yourLines => lines.where((l) => l.isYou).toList();
}

List<Scene> parseScenes(String raw) => [
      for (final (i, s) in (jsonDecode(raw)['scenes'] as List).cast<Map<String, dynamic>>().indexed)
        Scene(
          id: s['id'] as String,
          index: i,
          title: s['title'] as String,
          titleKo: s['titleKo'] as String,
          emoji: s['emoji'] as String,
          partner: s['a'] as String,
          lines: [
            for (final l in (s['lines'] as List).cast<Map<String, dynamic>>())
              DialogueLine(speaker: l['s'] as String, ko: l['ko'] as String, en: l['en'] as String),
          ],
          phraseIds: ((s['phrases'] as List?) ?? const []).cast<int>(),
          grammarIds: ((s['grammar'] as List?) ?? const []).cast<String>(),
        ),
    ];

Future<List<Scene>> loadScenes([AssetBundle? bundle]) async =>
    parseScenes(await (bundle ?? rootBundle).loadString('assets/data/dialogues.json'));

final scenesProvider = FutureProvider<List<Scene>>((ref) => loadScenes());

/// TTS pitch per speaker so the two voices sound different.
const partnerPitch = 1.2;
const youPitch = 0.85;
