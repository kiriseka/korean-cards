import 'package:drift/drift.dart';

import '../data/db.dart';
import 'exercises.dart';
import 'session.dart';

/// The mistakes notebook: what you got wrong recently, until you get it right twice in a row.
class MistakeService {
  MistakeService(this.db, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _clock;
  static const resolveAfter = 2;
  static const window = Duration(days: 7);

  Stream<List<Mistake>> watchOpen() =>
      (db.select(db.mistakes)..where((m) => m.resolved.equals(false))..orderBy([(m) => OrderingTerm.desc(m.createdAt)])).watch();

  Future<List<Mistake>> open() =>
      (db.select(db.mistakes)..where((m) => m.resolved.equals(false))..orderBy([(m) => OrderingTerm.desc(m.createdAt)])).get();

  /// Records a finished session: misses open (or reopen) entries; right answers move open
  /// entries toward resolved. Speaking items don't count toward resolving (they can be skipped).
  Future<void> recordSession(List<Exercise> exercises, ExerciseSession session) async {
    final practisedWords = <int>{}, practisedSkills = <String>{};
    for (final e in exercises) {
      if (e is SpeakExercise) continue;
      practisedWords.addAll(e.wordIds);
      practisedSkills.addAll(e.skillIds);
    }
    final missedWords = session.missedWordIds, missedSkills = session.missedSkillIds;
    if (missedWords.isEmpty && missedSkills.isEmpty && practisedWords.isEmpty && practisedSkills.isEmpty) return;
    final open = await this.open();
    final now = _clock();
    await db.transaction(() async {
      for (final m in open) {
        final missed = (m.wordId != null && missedWords.contains(m.wordId)) || (m.skillId != null && missedSkills.contains(m.skillId));
        final right = (m.wordId != null && practisedWords.contains(m.wordId)) || (m.skillId != null && practisedSkills.contains(m.skillId));
        if (missed) {
          await (db.update(db.mistakes)..where((x) => x.id.equals(m.id)))
              .write(MistakesCompanion(rightStreak: const Value(0), createdAt: Value(now)));
        } else if (right) {
          final streak = m.rightStreak + 1;
          await (db.update(db.mistakes)..where((x) => x.id.equals(m.id)))
              .write(MistakesCompanion(rightStreak: Value(streak), resolved: Value(streak >= resolveAfter)));
        }
      }
      final openWords = {for (final m in open) ?m.wordId};
      final openSkills = {for (final m in open) ?m.skillId};
      for (final w in missedWords.difference(openWords)) {
        await db.into(db.mistakes).insert(MistakesCompanion.insert(wordId: Value(w), createdAt: now));
      }
      for (final s in missedSkills.difference(openSkills)) {
        await db.into(db.mistakes).insert(MistakesCompanion.insert(skillId: Value(s), createdAt: now));
      }
    });
  }

  /// Open mistakes from the last week (older ones stay listed but aren't drilled).
  Future<(List<int> words, List<String> skills)> recent() async {
    final since = _clock().subtract(window);
    final open = (await this.open()).where((m) => !m.createdAt.isBefore(since));
    return (
      {for (final m in open) ?m.wordId}.toList(),
      {for (final m in open) ?m.skillId}.toList(),
    );
  }
}
