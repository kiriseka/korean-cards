import 'dart:math';

import '../data/db.dart';

enum QuestMetric { xp, lessons, reviews, combo, sentences, games, perfect, answers, spoken, dialogues, daily, gym, fixed }

class Quest {
  const Quest(this.id, this.emoji, this.title, this.metric, this.target);
  final String id;
  final String emoji;
  final String title;
  final QuestMetric metric;
  final int target;
}

const questPool = [
  Quest('xp30', '⚡', 'Earn 30 XP', QuestMetric.xp, 30),
  Quest('xp80', '⚡', 'Earn 80 XP', QuestMetric.xp, 80),
  Quest('lesson1', '📗', 'Finish a lesson', QuestMetric.lessons, 1),
  Quest('lesson2', '📚', 'Finish 2 lessons', QuestMetric.lessons, 2),
  Quest('review15', '🔁', 'Review 15 cards', QuestMetric.reviews, 15),
  Quest('review30', '🔁', 'Review 30 cards', QuestMetric.reviews, 30),
  Quest('combo8', '🔥', 'Get an 8-answer combo', QuestMetric.combo, 8),
  Quest('combo15', '🔥', 'Get a 15-answer combo', QuestMetric.combo, 15),
  Quest('sentence5', '🧩', 'Build 5 sentences', QuestMetric.sentences, 5),
  Quest('game1', '🎮', 'Play an arcade game', QuestMetric.games, 1),
  Quest('perfect1', '💯', 'Finish a lesson with no mistakes', QuestMetric.perfect, 1),
  Quest('answers25', '✅', 'Answer 25 questions right', QuestMetric.answers, 25),
  Quest('speak10', '🎤', 'Say 10 things out loud', QuestMetric.spoken, 10),
  Quest('dialogue1', '🎭', 'Finish a conversation scene', QuestMetric.dialogues, 1),
  Quest('daily', '⏱️', "Complete today's session", QuestMetric.daily, 1),
  Quest('gym2', '💪', 'Train 2 skills in the Gym', QuestMetric.gym, 2),
  Quest('fix1', '🩹', 'Review your mistakes', QuestMetric.fixed, 1),
];

/// Three quests for the study day starting at [day], each measuring something different.
/// The same day always gets the same quests.
List<Quest> dailyQuests(DateTime day) {
  final rng = Random(day.year * 10000 + day.month * 100 + day.day);
  final shuffled = [...questPool]..shuffle(rng);
  final picked = <Quest>[];
  for (final q in shuffled) {
    if (picked.every((p) => p.metric != q.metric)) picked.add(q);
    if (picked.length == 3) break;
  }
  return picked;
}

/// Progress toward [metric] from one study day's activities and flashcard reviews.
int questProgress(QuestMetric metric, List<Activity> today, int reviewsToday) {
  int sum(String kind, int Function(Activity a) f) =>
      today.where((a) => a.kind == kind).fold(0, (s, a) => s + f(a));
  return switch (metric) {
    QuestMetric.xp => today.fold(0, (s, a) => s + a.xp),
    QuestMetric.lessons => sum(ActivityKind.lesson, (_) => 1),
    QuestMetric.reviews => reviewsToday,
    QuestMetric.combo => today.where((a) => a.kind == ActivityKind.combo).fold(0, (m, a) => max(m, a.value)),
    QuestMetric.sentences => sum(ActivityKind.sentence, (a) => a.value),
    QuestMetric.games => sum(ActivityKind.game, (_) => 1),
    QuestMetric.perfect => sum(ActivityKind.lesson, (a) => a.value == 100 ? 1 : 0), // value = accuracy %
    QuestMetric.answers => sum(ActivityKind.answer, (a) => a.value),
    QuestMetric.spoken => sum(ActivityKind.spoken, (a) => a.value),
    QuestMetric.dialogues => sum(ActivityKind.dialogue, (_) => 1),
    QuestMetric.daily => sum(ActivityKind.daily, (a) => a.value == 99 ? 1 : 0),
    QuestMetric.gym => sum(ActivityKind.gym, (a) => a.value),
    QuestMetric.fixed => sum(ActivityKind.fixed, (a) => a.value),
  };
}
