import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db.dart';

const wordsAsset = 'assets/data/words.json';
const phrasesAsset = 'assets/data/phrases.json';

/// Phrase ids start here; phrases are practised English → Korean as well.
const firstPhraseId = 20000000;
const _versionKey = 'wordsDataVersion';

/// Loads the bundled word list into the database when it is new or has changed.
///
/// Words are upserted by KRDict id, so review progress, stars and notes survive app updates.
Future<void> importBundledWords(AppDatabase db, SharedPreferences prefs, {AssetBundle? bundle}) async {
  final raw = await (bundle ?? rootBundle).loadString(wordsAsset);
  final data = jsonDecode(raw) as Map<String, dynamic>;
  final version = data['version'] as String;
  if (prefs.getString(_versionKey) == version) return;

  await importWords(db, (data['words'] as List).cast<Map<String, dynamic>>());
  await prefs.setString(_versionKey, version);
}

/// Upserts the hand-written survival phrases (small, so it runs every launch).
Future<void> importBundledPhrases(AppDatabase db, {AssetBundle? bundle}) async {
  final raw = await (bundle ?? rootBundle).loadString(phrasesAsset);
  await importWords(db, phrasesToWords((jsonDecode(raw)['phrases'] as List).cast<Map<String, dynamic>>()));
}

/// Phrases in the word-list format. They are spread through the learning order (one about
/// every 12 words) so new flashcards mix phrases in from day one.
List<Map<String, dynamic>> phrasesToWords(List<Map<String, dynamic>> phrases) => [
      for (final (i, p) in phrases.indexed)
        {
          'id': p['id'],
          'word': p['ko'],
          'pos': 'phrase',
          'level': 'phrase',
          'unit': p['unit'],
          'rank': 5 + i * 12,
          'senses': [
            {
              'meanings': [p['en']],
              'definition': [
                if (p['lit'] != null) 'Literally: “${p['lit']}”',
                if (p['note'] != null) p['note'],
              ].join(' — '),
              'example': null,
              'examples': <String>[],
              'dialogues': <List<String>>[],
            },
          ],
        },
    ];

Future<void> importWords(AppDatabase db, List<Map<String, dynamic>> items) async {
  await db.transaction(() async {
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(db.words, [
        for (final w in items)
          WordsCompanion.insert(
            id: Value(w['id'] as int),
            word: w['word'] as String,
            homonym: Value(w['homonym'] as int? ?? 0),
            pos: w['pos'] as String,
            level: w['level'] as String,
            hanja: Value(w['hanja'] as String?),
            pronunciation: Value(w['pronunciation'] as String?),
            category: Value(w['category'] as String?),
            senses: jsonEncode(w['senses']),
            rank: w['rank'] as int,
            unit: Value(w['unit'] as String?),
            forms: Value(w['forms'] == null ? null : jsonEncode(w['forms'])),
          ),
      ]);
    });
    await db.ensureCards();
  });
}
