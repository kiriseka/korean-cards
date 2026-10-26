import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart';

import '../data/db.dart';
import '../learn/skill_service.dart';
import '../learn/skills.dart';
import 'badges.dart';
import 'quests.dart';
import 'rules.dart';

class QuestStatus {
  const QuestStatus(this.quest, this.progress, this.claimed);
  final Quest quest;
  final int progress;
  final bool claimed;

  bool get done => claimed || progress >= quest.target;
  double get fraction => (progress / quest.target).clamp(0, 1).toDouble();
}

class Profile {
  const Profile({
    required this.totalXp,
    required this.todayXp,
    required this.level,
    required this.streak,
    required this.quests,
    required this.badges,
  });

  final int totalXp;
  final int todayXp;
  final LevelInfo level;
  final StreakInfo streak;
  final List<QuestStatus> quests;
  final Map<String, DateTime> badges;
}

sealed class Celebration {
  const Celebration();
}

class LevelUp extends Celebration {
  const LevelUp(this.level);
  final LevelInfo level;
}

class BadgeEarned extends Celebration {
  const BadgeEarned(this.badge);
  final GameBadge badge;
}

class QuestDone extends Celebration {
  const QuestDone(this.quest, this.xp);
  final Quest? quest; // null: the all-quests bonus
  final int xp;
}

class AwardOutcome {
  const AwardOutcome({required this.xp, this.levelUp, this.badges = const [], this.quests = const []});
  final int xp;
  final LevelInfo? levelUp;
  final List<GameBadge> badges;
  final List<QuestDone> quests;
}

/// XP, levels, streaks, quests and badges on top of the database.
class GameService {
  GameService(this.db, {this.grammarUnits = const {}, DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppDatabase db;

  /// Grammar unit id → lesson ids, for the grammar badges.
  final Map<String, List<String>> grammarUnits;
  final DateTime Function() _clock;
  final _events = StreamController<Celebration>.broadcast();

  /// Level-ups, badges and quests as they happen, for the app-wide celebration overlay.
  Stream<Celebration> get celebrations => _events.stream;

  ActivitiesCompanion activity(String kind, {int xp = 0, int value = 0, String? ref}) => ActivitiesCompanion.insert(
        kind: kind,
        xp: Value(xp),
        value: Value(value),
        ref: Value(ref),
        createdAt: _clock(),
      );

  Future<int> totalXp() async {
    final sum = db.activities.xp.sum();
    return await (db.selectOnly(db.activities)..addColumns([sum])).map((r) => r.read(sum) ?? 0).getSingle();
  }

  Future<List<Activity>> _activitiesSince(DateTime since) =>
      (db.select(db.activities)..where((a) => a.createdAt.isBiggerOrEqualValue(since))).get();

  Future<int> _reviewsSince(DateTime since) async {
    final count = db.reviewLogs.id.count();
    return await (db.selectOnly(db.reviewLogs)
          ..addColumns([count])
          ..where(db.reviewLogs.reviewedAt.isBiggerOrEqualValue(since)))
        .map((r) => r.read(count) ?? 0)
        .getSingle();
  }

  Future<StreakInfo> _streak() async {
    final since = addDays(studyDayStart(_clock()), -400);
    final acts = await (db.selectOnly(db.activities)
          ..addColumns([db.activities.createdAt])
          ..where(db.activities.createdAt.isBiggerOrEqualValue(since)))
        .map((r) => r.read(db.activities.createdAt)!)
        .get();
    final reviews = await (db.selectOnly(db.reviewLogs)
          ..addColumns([db.reviewLogs.reviewedAt])
          ..where(db.reviewLogs.reviewedAt.isBiggerOrEqualValue(since)))
        .map((r) => r.read(db.reviewLogs.reviewedAt)!)
        .get();
    return computeStreak({...acts, ...reviews}, _clock());
  }

  Future<List<QuestStatus>> _quests() async {
    final day = studyDayStart(_clock());
    final today = await _activitiesSince(day);
    final reviews = await _reviewsSince(day);
    final claimed = (await (db.select(db.questClaims)..where((q) => q.day.equals(day))).get()).map((q) => q.questId).toSet();
    return [
      for (final q in dailyQuests(day)) QuestStatus(q, questProgress(q.metric, today, reviews), claimed.contains(q.id)),
    ];
  }

  /// Records activities, then pays out finished quests, unlocks badges and reports level-ups.
  Future<AwardOutcome> award(List<ActivitiesCompanion> items) async {
    final before = levelFor(await totalXp());
    await db.batch((b) => b.insertAll(db.activities, items));
    var xp = items.fold(0, (s, a) => s + a.xp.value);

    final questsDone = <QuestDone>[];
    final day = studyDayStart(_clock());
    // Quest XP can itself finish an "earn XP" quest, so settle until nothing changes.
    for (var round = 0; round < 3; round++) {
      final open = (await _quests()).where((q) => !q.claimed && q.progress >= q.quest.target).toList();
      if (open.isEmpty) break;
      for (final q in open) {
        await db.into(db.questClaims).insert(QuestClaimsCompanion.insert(day: day, questId: q.quest.id));
        await db.into(db.activities).insert(activity(ActivityKind.quest, xp: Xp.quest, ref: q.quest.id));
        xp += Xp.quest;
        questsDone.add(QuestDone(q.quest, Xp.quest));
      }
      final bonusClaimed = await (db.select(db.questClaims)
            ..where((q) => q.day.equals(day) & q.questId.equals('all')))
          .getSingleOrNull();
      if (bonusClaimed == null && (await _quests()).every((q) => q.claimed)) {
        await db.into(db.questClaims).insert(QuestClaimsCompanion.insert(day: day, questId: 'all'));
        await db.into(db.activities).insert(activity(ActivityKind.quest, xp: Xp.allQuests, ref: 'all'));
        xp += Xp.allQuests;
        questsDone.add(const QuestDone(null, Xp.allQuests));
      }
    }

    final after = levelFor(await totalXp());
    final newBadges = await checkBadges();
    final outcome = AwardOutcome(
      xp: xp,
      levelUp: after.level > before.level ? after : null,
      badges: newBadges,
      quests: questsDone,
    );
    questsDone.forEach(_events.add);
    for (final b in newBadges) {
      _events.add(BadgeEarned(b));
    }
    if (outcome.levelUp != null) _events.add(LevelUp(outcome.levelUp!));
    return outcome;
  }

  /// Saves a finished lesson, keeping the best stars and accuracy.
  Future<void> recordLesson(String lessonId, {required int stars, required double accuracy}) async {
    final now = _clock();
    final existing =
        await (db.select(db.lessonProgress)..where((l) => l.lessonId.equals(lessonId))).getSingleOrNull();
    await db.into(db.lessonProgress).insertOnConflictUpdate(LessonProgressCompanion.insert(
          lessonId: lessonId,
          stars: max(stars, existing?.stars ?? 0),
          bestAccuracy: max(accuracy, existing?.bestAccuracy ?? 0),
          completions: Value((existing?.completions ?? 0) + 1),
          firstCompletedAt: existing?.firstCompletedAt ?? now,
          lastCompletedAt: now,
        ));
  }

  Future<GameStats> stats() async {
    int readInt(QueryRow r, String key) => r.read<int?>(key) ?? 0;
    final row = await db.customSelect(
      'SELECT '
      '(SELECT COUNT(*) FROM cards WHERE direction = 0 AND state != 0) AS words, '
      "(SELECT MAX(value) FROM activities WHERE kind = 'combo') AS combo, "
      "(SELECT COALESCE(SUM(value), 0) FROM activities WHERE kind = 'sentence') AS sentences, "
      "(SELECT COUNT(DISTINCT ref) FROM activities WHERE kind = 'challenge') AS challenges, "
      "(SELECT MAX(value) FROM activities WHERE kind = 'game' AND ref = 'speed') AS speed, "
      '(SELECT COUNT(*) FROM words WHERE is_custom = 1) AS custom, '
      '(SELECT COUNT(*) FROM lesson_progress WHERE best_accuracy >= 1.0) AS perfect, '
      "(SELECT COALESCE(SUM(value), 0) FROM activities WHERE kind = 'spoken') AS spoken, "
      "(SELECT COUNT(DISTINCT ref) FROM activities WHERE kind = 'dialogue') AS scenes, "
      "(SELECT COUNT(*) FROM activities WHERE kind = 'daily' AND value = 99) AS daily_days, "
      "(SELECT COUNT(*) FROM cards c JOIN words w ON w.id = c.word_id WHERE w.pos = 'phrase' AND c.direction = 0 AND c.state != 0) AS phrases",
      readsFrom: {db.cards, db.activities, db.words, db.lessonProgress},
    ).getSingle();
    final completed = (await db.select(db.lessonProgress).get()).map((l) => l.lessonId).toSet();
    final skillRows = {for (final r in await db.select(db.skills).get()) r.id: r};
    return GameStats(
      wordsLearned: readInt(row, 'words'),
      streak: (await _streak()).days,
      bestCombo: readInt(row, 'combo'),
      lessonsDone: completed.where((id) => !id.startsWith('challenge:')).length,
      perfectLessons: readInt(row, 'perfect'),
      sentencesBuilt: readInt(row, 'sentences'),
      challengesPassed: readInt(row, 'challenges'),
      bestSpeedRound: readInt(row, 'speed'),
      customWords: readInt(row, 'custom'),
      spokenTotal: readInt(row, 'spoken'),
      scenesDone: readInt(row, 'scenes'),
      dailyDays: readInt(row, 'daily_days'),
      phrasesLearned: readInt(row, 'phrases'),
      skillMastery: {for (final s in skills) s.id: SkillService.mastery(skillRows[s.id])},
      completedLessons: completed,
      grammarUnits: grammarUnits,
      hour: _clock().hour,
    );
  }

  /// Unlocks every badge whose condition is now met; returns the new ones.
  Future<List<GameBadge>> checkBadges() async {
    final have = (await db.select(db.achievements).get()).map((a) => a.id).toSet();
    final s = await stats();
    final fresh = badges.where((b) => !have.contains(b.id) && b.earned(s)).toList();
    final now = _clock();
    await db.batch((batch) => batch.insertAll(
          db.achievements,
          [for (final b in fresh) AchievementsCompanion.insert(id: b.id, unlockedAt: now)],
          mode: InsertMode.insertOrIgnore,
        ));
    return fresh;
  }

  Stream<Profile> watchProfile() {
    final trigger = db.customSelect('SELECT 1',
        readsFrom: {db.activities, db.reviewLogs, db.achievements, db.questClaims}).watch();
    return trigger.asyncMap((_) async {
      final total = await totalXp();
      final today = await _activitiesSince(studyDayStart(_clock()));
      return Profile(
        totalXp: total,
        todayXp: today.fold(0, (s, a) => s + a.xp),
        level: levelFor(total),
        streak: await _streak(),
        quests: await _quests(),
        badges: {for (final a in await db.select(db.achievements).get()) a.id: a.unlockedAt},
      );
    });
  }

  Stream<Map<String, LessonProgressData>> watchLessonProgress() =>
      db.select(db.lessonProgress).watch().map((rows) => {for (final r in rows) r.lessonId: r});

  Future<void> dispose() => _events.close();
}
