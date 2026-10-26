import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db.dart';
import 'lemmatizer.dart';

const dictionaryAsset = 'assets/data/dictionary.json.gz';
const _loadedKey = 'dictionaryBytes';

List<dynamic> _decode(Uint8List gz) => jsonDecode(utf8.decode(GZipCodec().decode(gz))) as List<dynamic>;

class DictSense {
  const DictSense(this.meanings, this.definition);
  final List<String> meanings;
  final String definition;
}

extension DictEntryX on DictEntry {
  List<DictSense> get senseList => [
        for (final s in jsonDecode(senses) as List)
          DictSense(((s as Map)['m'] as List).cast<String>(), s['d'] as String? ?? ''),
      ];

  String get gloss => senseList.isEmpty ? '' : senseList.first.meanings.take(3).join(', ');
}

/// The full KRDict dictionary, loaded into the database on first use (about 53k entries).
class DictionaryService {
  DictionaryService(this.db, this.prefs, {AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AppDatabase db;
  final SharedPreferences prefs;
  final AssetBundle _bundle;
  Map<String, List<String>>? _forms;

  /// Loaded and matching the bundled file (a new app version with a new file reloads it).
  Future<bool> get ready async => prefs.getInt(_loadedKey) == (await _bundle.load(dictionaryAsset)).lengthInBytes;

  Future<void> ensureLoaded({void Function(double progress)? onProgress}) async {
    final data = await _bundle.load(dictionaryAsset);
    if (prefs.getInt(_loadedKey) == data.lengthInBytes) return;
    final entries = await compute(_decode, data.buffer.asUint8List());
    await db.delete(db.dictionary).go();
    const chunk = 2000;
    for (var i = 0; i < entries.length; i += chunk) {
      await db.batch((b) => b.insertAll(db.dictionary, [
            for (final e in entries.skip(i).take(chunk).cast<Map<String, dynamic>>())
              DictionaryCompanion.insert(
                id: Value(e['i'] as int),
                word: e['w'] as String,
                pos: e['p'] as String,
                level: e['l'] as String? ?? '',
                hanja: Value(e['h'] as String?),
                pronunciation: Value(e['r'] as String?),
                senses: jsonEncode(e['s']),
                example: Value(e['e'] as String?),
                forms: Value(e['f'] == null ? null : jsonEncode(e['f'])),
              ),
          ]));
      onProgress?.call((i + chunk) / entries.length);
    }
    _forms = null;
    await prefs.setInt(_loadedKey, data.lengthInBytes);
  }

  /// KRDict 아/어 forms and 으니 stems → dictionary form (들어 → 듣다, 추우 → 춥다).
  Future<Map<String, List<String>>> formIndex() async {
    if (_forms != null) return _forms!;
    final rows = await (db.select(db.dictionary)..where((d) => d.forms.isNotNull())).get();
    final index = <String, List<String>>{};
    for (final r in rows) {
      final f = jsonDecode(r.forms!) as Map<String, dynamic>;
      final a = f['a'] as String?;
      final euni = f['euni'] as String?;
      // 들어 is both 듣다 (listen) and 들다 (lift): keep every word a form can come from.
      if (a != null) (index[a] ??= []).add(r.word);
      if (euni != null && euni.length > 1) (index[euni.substring(0, euni.length - 1)] ??= []).add(r.word);
    }
    return _forms = index;
  }

  /// Puts a dictionary word into your deck (as one of your own words, keeping the KRDict id so
  /// it merges cleanly if a deck brings the same word later). False if it was already there.
  Future<bool> addToDeck(DictEntry e, {String unit = customUnit}) async {
    final existing = await (db.select(db.words)..where((w) => w.id.equals(e.id))).getSingleOrNull();
    if (existing != null) return false;
    final senses = e.senseList;
    await db.into(db.words).insert(
          WordsCompanion.insert(
            id: Value(e.id),
            word: e.word,
            pos: e.pos,
            level: e.level.isEmpty ? 'custom' : e.level,
            hanja: Value(e.hanja),
            pronunciation: Value(e.pronunciation),
            senses: jsonEncode([
              for (final (i, s) in senses.indexed)
                Sense(meanings: s.meanings, definition: s.definition, example: i == 0 ? e.example : null, examples: [if (i == 0) ?e.example])
                    .toJson(),
            ]),
            rank: 0,
            isCustom: const Value(true),
            unit: Value(unit),
            forms: Value(e.forms),
          ),
        );
    await db.ensureCards();
    return true;
  }

  static const _levelOrder = "CASE level WHEN '초급' THEN 0 WHEN '중급' THEN 1 WHEN '고급' THEN 2 ELSE 3 END";

  Future<List<DictEntry>> _byWords(List<String> words) async {
    if (words.isEmpty) return const [];
    final rows = await (db.select(db.dictionary)..where((d) => d.word.isIn(words))).get();
    final rank = {for (final (i, w) in words.indexed) w: i};
    const level = {'초급': 0, '중급': 1, '고급': 2};
    rows.sort((a, b) {
      final r = rank[a.word]!.compareTo(rank[b.word]!);
      return r != 0 ? r : (level[a.level] ?? 3).compareTo(level[b.level] ?? 3);
    });
    return rows;
  }

  /// Dictionary entries a word from real text could be (conjugations and particles undone).
  Future<List<DictEntry>> lookup(String token) async =>
      _byWords(lemmaCandidates(token, formIndex: await formIndex()));

  /// Search by Korean (exact and conjugated forms first, then words starting with it) or English.
  Future<List<DictEntry>> search(String query, {int limit = 40}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    if (RegExp(r'[가-힣]').hasMatch(q)) {
      final exact = await lookup(q);
      final seen = {for (final e in exact) e.id};
      final prefix = await db.customSelect(
        'SELECT * FROM dictionary WHERE word LIKE ? ORDER BY $_levelOrder, length(word) LIMIT ?',
        variables: [Variable.withString('${q.replaceAll('%', '')}%'), Variable.withInt(limit)],
        readsFrom: {db.dictionary},
      ).map((r) => db.dictionary.map(r.data)).get();
      return [...exact, ...prefix.where((e) => !seen.contains(e.id))].take(limit).toList();
    }
    final lower = q.toLowerCase().replaceAll('"', '');
    return db.customSelect(
      'SELECT * FROM dictionary WHERE lower(senses) LIKE ? '
      'ORDER BY (lower(senses) LIKE ?) DESC, $_levelOrder, length(word) LIMIT ?',
      variables: [Variable.withString('%$lower%'), Variable.withString('%"$lower"%'), Variable.withInt(limit)],
      readsFrom: {db.dictionary},
    ).map((r) => db.dictionary.map(r.data)).get();
  }
}
