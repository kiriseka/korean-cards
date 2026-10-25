import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db.dart';

const wordsAsset = 'assets/data/words.json';
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
          ),
      ]);
    });
    await db.ensureCards();
  });
}
