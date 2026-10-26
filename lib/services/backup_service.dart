import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/db.dart';

/// Whole-progress backup as JSON: custom words, stars and notes, cards, the review history and
/// game progress (XP, lessons, badges, quests).
/// Bundled word text is not included; it comes back from the app's own word list.
class BackupService {
  BackupService(this.db);
  final AppDatabase db;

  static const formatVersion = 2;

  Future<String> export() async {
    final words = await db.select(db.words).get();
    final cards = await db.select(db.cards).get();
    final logs = await db.select(db.reviewLogs).get();
    return jsonEncode({
      'app': 'korean_cards',
      'format': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'customWords': [for (final w in words.where((w) => w.isCustom)) w.toJson()],
      'wordMarks': [
        for (final w in words.where((w) => !w.isCustom && (w.starred || w.note != null)))
          {'id': w.id, 'starred': w.starred, 'note': w.note},
      ],
      'cards': [for (final c in cards) c.toJson()],
      'reviewLogs': [for (final l in logs) l.toJson()],
      'activities': [for (final a in await db.select(db.activities).get()) a.toJson()],
      'lessonProgress': [for (final l in await db.select(db.lessonProgress).get()) l.toJson()],
      'achievements': [for (final a in await db.select(db.achievements).get()) a.toJson()],
      'questClaims': [for (final q in await db.select(db.questClaims).get()) q.toJson()],
    });
  }

  /// Replaces all progress with the backup's. Throws [FormatException] for a file that isn't one.
  Future<void> import(String json) async {
    final data = jsonDecode(json);
    if (data is! Map<String, dynamic> || data['app'] != 'korean_cards') {
      throw const FormatException('Not a Korean Cards backup file');
    }
    // Version 1 files have no game progress; missing lists import as empty.
    List<Map<String, dynamic>> list(String key) => ((data[key] as List?) ?? const []).cast<Map<String, dynamic>>();

    await db.transaction(() async {
      final bundledIds = (await db.select(db.words).get()).where((w) => !w.isCustom).map((w) => w.id).toSet();
      await db.delete(db.reviewLogs).go();
      await db.delete(db.cards).go();
      await db.delete(db.activities).go();
      await db.delete(db.lessonProgress).go();
      await db.delete(db.achievements).go();
      await db.delete(db.questClaims).go();
      await (db.delete(db.words)..where((w) => w.isCustom.equals(true))).go();
      await db.update(db.words).write(const WordsCompanion(starred: Value(false), note: Value(null)));

      await db.batch((b) {
        b.insertAll(db.words, [for (final w in list('customWords')) Word.fromJson(w)]);
        for (final m in list('wordMarks')) {
          if (!bundledIds.contains(m['id'])) continue;
          b.update(db.words, WordsCompanion(starred: Value(m['starred'] as bool), note: Value(m['note'] as String?)),
              where: (w) => w.id.equals(m['id'] as int));
        }
      });
      final wordIds = (await db.select(db.words).get()).map((w) => w.id).toSet();
      final cards = [for (final c in list('cards')) StudyCard.fromJson(c)].where((c) => wordIds.contains(c.wordId)).toList();
      final cardIds = cards.map((c) => c.id).toSet();
      await db.batch((b) {
        b.insertAll(db.cards, cards);
        b.insertAll(db.reviewLogs,
            [for (final l in list('reviewLogs')) ReviewLog.fromJson(l)].where((l) => cardIds.contains(l.cardId)));
        b.insertAll(db.activities, [for (final a in list('activities')) Activity.fromJson(a)]);
        b.insertAll(db.lessonProgress, [for (final l in list('lessonProgress')) LessonProgressData.fromJson(l)]);
        b.insertAll(db.achievements, [for (final a in list('achievements')) Achievement.fromJson(a)]);
        b.insertAll(db.questClaims, [for (final q in list('questClaims')) QuestClaim.fromJson(q)]);
      });
      await db.ensureCards();
    });
  }
}
