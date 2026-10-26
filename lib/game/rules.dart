import '../data/db.dart';

/// XP rewards.
abstract final class Xp {
  static const reviewAgain = 1;
  static const review = 2;
  static const answer = 5;
  static const maxComboBonus = 5;
  static const lesson = 20;
  static const perfectLesson = 30;
  static const challenge = 50;
  static const quest = 20;
  static const allQuests = 30;

  /// +1 for every 3 answers in a row, up to +5.
  static int forAnswer(int combo) => answer + (combo ~/ 3).clamp(0, maxComboBonus);
}

const dailyGoals = [20, 50, 100, 200];

class LevelTitle {
  const LevelTitle(this.fromLevel, this.emoji, this.korean, this.english);
  final int fromLevel;
  final String emoji;
  final String korean;
  final String english;
}

const levelTitles = [
  LevelTitle(1, '🌱', '새싹', 'Sprout'),
  LevelTitle(3, '🐯', '아기 호랑이', 'Tiger cub'),
  LevelTitle(6, '🎒', '학생', 'Student'),
  LevelTitle(10, '🎓', '선배', 'Senior'),
  LevelTitle(15, '📚', '선생님', 'Teacher'),
  LevelTitle(20, '🥋', '달인', 'Master'),
  LevelTitle(30, '👑', '한국어 왕', 'King of Korean'),
];

class LevelInfo {
  const LevelInfo({required this.level, required this.xpIntoLevel, required this.xpForLevel, required this.title});
  final int level;
  final int xpIntoLevel;
  final int xpForLevel;
  final LevelTitle title;

  double get progress => xpIntoLevel / xpForLevel;
}

/// Total XP needed to reach [level]: 0, 50, 150, 300, 500, ... (each level costs 50 more than the last).
int xpToReach(int level) => 25 * level * (level - 1);

LevelInfo levelFor(int totalXp) {
  var level = 1;
  while (xpToReach(level + 1) <= totalXp) {
    level++;
  }
  final start = xpToReach(level);
  return LevelInfo(
    level: level,
    xpIntoLevel: totalXp - start,
    xpForLevel: xpToReach(level + 1) - start,
    title: levelTitles.lastWhere((t) => level >= t.fromLevel),
  );
}

class StreakInfo {
  const StreakInfo({required this.days, required this.freezes, required this.activeToday, required this.frozenDays});

  /// Consecutive study days, counting days saved by a freeze as kept but not added.
  final int days;
  final int freezes;
  final bool activeToday;
  final Set<DateTime> frozenDays;

  static const maxFreezes = 2;
  static const daysPerFreeze = 7;
}

/// Replays study history day by day. Every 7th streak day earns a streak freeze (max 2); a missed
/// day spends one instead of breaking the streak. Today never breaks it: there's still time.
StreakInfo computeStreak(Set<DateTime> activeDays, DateTime now) {
  final today = studyDayStart(now);
  if (activeDays.isEmpty) {
    return const StreakInfo(days: 0, freezes: 0, activeToday: false, frozenDays: {});
  }
  final normalized = activeDays.map(studyDayStart).toSet();
  var day = normalized.reduce((a, b) => a.isBefore(b) ? a : b);
  var streak = 0, freezes = 0;
  final frozen = <DateTime>{};
  while (!day.isAfter(today)) {
    if (normalized.contains(day)) {
      streak++;
      if (streak % StreakInfo.daysPerFreeze == 0 && freezes < StreakInfo.maxFreezes) freezes++;
    } else if (day != today) {
      if (streak > 0 && freezes > 0) {
        freezes--;
        frozen.add(day);
      } else {
        streak = 0;
        frozen.clear();
      }
    }
    day = addDays(day, 1);
  }
  return StreakInfo(days: streak, freezes: freezes, activeToday: normalized.contains(today), frozenDays: frozen);
}
