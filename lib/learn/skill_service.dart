import 'package:drift/drift.dart';

import '../data/db.dart';
import '../srs/scheduler.dart';
import 'skills.dart';

/// Schedules grammar and number skills with FSRS, like flashcards, and picks Gym rounds.
class SkillService {
  SkillService(this.db, this.scheduler, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final Scheduler scheduler;
  final DateTime Function() _clock;

  Stream<Map<String, SkillRow>> watch() => db.select(db.skills).watch().map((rows) => {for (final r in rows) r.id: r});

  Future<Map<String, SkillRow>> rows() async => {for (final r in await db.select(db.skills).get()) r.id: r};

  /// 0..1: how solid a skill is — mostly memory strength (FSRS stability, 3 weeks = full),
  /// partly recent accuracy.
  static double mastery(SkillRow? r) {
    if (r == null || r.state == CardState.newCard) return 0;
    final strength = ((r.stability ?? 0) / knownStabilityDays).clamp(0.0, 1.0);
    final accuracy = r.attempts == 0 ? 0.0 : r.correct / r.attempts;
    return (strength * 0.7 + accuracy * 0.3).clamp(0.0, 1.0);
  }

  static bool isDue(SkillRow? r, DateTime now) => r != null && r.state != CardState.newCard && !r.due.isAfter(now);

  /// After a round: all right → Good, more right than wrong → Hard, otherwise Again.
  static Rating ratingFor(int right, int wrong) {
    if (wrong == 0) return Rating.good;
    if (right > wrong) return Rating.hard;
    return Rating.again;
  }

  Future<void> recordResults(Map<String, (int, int)> results) async {
    if (results.isEmpty) return;
    final now = _clock();
    final existing = await rows();
    await db.transaction(() async {
      for (final MapEntry(key: id, value: (right, wrong)) in results.entries) {
        final row = existing[id];
        final card = StudyCard(
          id: 0,
          wordId: 0,
          direction: 0,
          state: row?.state ?? CardState.newCard,
          step: row?.step,
          stability: row?.stability,
          difficulty: row?.difficulty,
          due: row?.due ?? now,
          lastReview: row?.lastReview,
          reps: row?.reps ?? 0,
          lapses: row?.lapses ?? 0,
          suspended: false,
        );
        final next = scheduler.preview(card, now)[ratingFor(right, wrong)]!.card;
        await db.into(db.skills).insertOnConflictUpdate(SkillsCompanion.insert(
              id: id,
              state: Value(next.state),
              step: Value(next.step),
              stability: Value(next.stability),
              difficulty: Value(next.difficulty),
              due: Value(next.due),
              lastReview: Value(next.lastReview),
              reps: Value(next.reps),
              lapses: Value(next.lapses),
              correct: Value((row?.correct ?? 0) + right),
              attempts: Value((row?.attempts ?? 0) + right + wrong),
            ));
      }
    });
  }

  /// Finishing a grammar lesson starts its skills' review schedule.
  Future<void> seedLesson(String lessonId) async {
    final existing = await rows();
    await recordResults({
      for (final s in skillsForLesson(lessonId))
        if (existing[s.id] == null) s.id: (1, 0),
    });
  }

  /// Skills for one Gym round, with how many exercises each: due skills first, then the
  /// weakest ones (never-trained skills count as weakest).
  Future<Map<String, int>> pickRound({int size = 12, String? only, Set<SkillGroup> groups = const {SkillGroup.particles, SkillGroup.tenses}}) async {
    if (only != null) return {only: size};
    final now = _clock();
    final existing = await rows();
    final pool = skills.where((s) => groups.contains(s.group)).toList();
    final due = pool.where((s) => isDue(existing[s.id], now)).toList()
      ..sort((a, b) => existing[a.id]!.due.compareTo(existing[b.id]!.due));
    final rest = pool.where((s) => !due.contains(s)).toList()
      ..sort((a, b) => mastery(existing[a.id]).compareTo(mastery(existing[b.id])));
    final chosen = [...due, ...rest].take(3).toList();
    final per = size ~/ chosen.length;
    return {for (final (i, s) in chosen.indexed) s.id: per + (i < size % chosen.length ? 1 : 0)};
  }

  /// Skills due now, for Today's session.
  Future<List<String>> dueSkills({Set<SkillGroup> groups = const {SkillGroup.particles, SkillGroup.tenses}}) async {
    final now = _clock();
    final existing = await rows();
    return [
      for (final s in skills)
        if (groups.contains(s.group) && isDue(existing[s.id], now)) s.id,
    ];
  }
}
