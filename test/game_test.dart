import 'package:flutter_test/flutter_test.dart';
import 'package:korean_cards/data/db.dart';
import 'package:korean_cards/game/game_service.dart';
import 'package:korean_cards/game/quests.dart';
import 'package:korean_cards/game/rules.dart';
import 'package:korean_cards/learn/exercises.dart';
import 'package:korean_cards/learn/session.dart';

import 'helpers.dart';

DateTime day(int d, [int hour = 12]) => DateTime(2026, 10, d, hour);

const _q = ChoiceExercise(instruction: 'q', prompt: 'p', style: PromptStyle.korean, options: ['a', 'b'], answer: 0);
const _q2 = ChoiceExercise(instruction: 'q2', prompt: 'p2', style: PromptStyle.korean, options: ['a', 'b'], answer: 0);

void main() {
  test('levels: 0, 50, 150, 300… XP', () {
    expect(xpToReach(1), 0);
    expect(xpToReach(2), 50);
    expect(xpToReach(3), 150);
    expect(xpToReach(4), 300);
    expect(levelFor(0).level, 1);
    expect(levelFor(49).level, 1);
    expect(levelFor(50).level, 2);
    final l = levelFor(200);
    expect((l.level, l.xpIntoLevel, l.xpForLevel), (3, 50, 150));
    expect(levelFor(0).title.english, 'Sprout');
    expect(levelFor(xpToReach(30)).title.english, 'King of Korean');
  });

  test('combo bonus grows to +5', () {
    expect(Xp.forAnswer(1), 5);
    expect(Xp.forAnswer(3), 6);
    expect(Xp.forAnswer(9), 8);
    expect(Xp.forAnswer(40), 10);
  });

  group('streak', () {
    test('counts consecutive days; today not done yet keeps it', () {
      final s = computeStreak({day(1), day(2), day(3)}, day(4));
      expect((s.days, s.activeToday), (3, false));
      expect(computeStreak({day(1), day(2), day(3), day(4, 8)}, day(4)).days, 4);
    });

    test('a missed day without a freeze resets it', () {
      expect(computeStreak({day(1), day(2), day(4)}, day(4)).days, 1);
    });

    test('7 days earn a freeze that saves one missed day', () {
      final active = {for (var d = 1; d <= 7; d++) day(d), day(9), day(10)};
      final s = computeStreak(active, day(10));
      expect(s.days, 9);
      expect(s.freezes, 0);
      expect(s.frozenDays, {studyDayStart(day(8))});
    });

    test('late-night study counts for the day before (4am rollover)', () {
      final s = computeStreak({day(1, 20), day(3, 2)}, day(3, 10));
      expect(s.days, 2, reason: '3 Oct 2am belongs to 2 Oct');
    });
  });

  test('daily quests: three different kinds, stable for the day', () {
    final a = dailyQuests(studyDayStart(day(5)));
    expect(a, hasLength(3));
    expect(a.map((q) => q.metric).toSet(), hasLength(3));
    expect(dailyQuests(studyDayStart(day(5, 22))).map((q) => q.id), a.map((q) => q.id));
  });

  group('GameService', () {
    test('lesson XP, quests paying out once, badges and level-up', () async {
      final db = await seededDb(3);
      var now = day(10, 10);
      final game = GameService(db, clock: () => now);
      await game.recordLesson('topic:food:0', stars: 3, accuracy: 1.0);
      final outcome = await game.award([
        game.activity(ActivityKind.answer, xp: 60, value: 12),
        game.activity(ActivityKind.combo, value: 12),
        game.activity(ActivityKind.lesson, xp: Xp.perfectLesson, value: 100, ref: 'topic:food:0'),
      ]);
      expect(outcome.levelUp?.level, 2);
      expect(outcome.badges.map((b) => b.id), containsAll(['first_lesson', 'perfect1', 'combo10']));
      final profile = await game.watchProfile().first;
      final claimedXp = outcome.quests.fold(0, (s, q) => s + q.xp);
      expect(profile.totalXp, 90 + claimedXp);
      expect(profile.todayXp, profile.totalXp);
      expect(profile.badges.keys, contains('first_lesson'));

      // Awarding again must not pay finished quests or badges twice.
      final again = await game.award([game.activity(ActivityKind.answer, xp: 5, value: 1)]);
      expect(again.badges, isEmpty);
      expect(again.quests.where((q) => outcome.quests.any((o) => o.quest?.id == q.quest?.id)), isEmpty);

      // Next day: today's XP starts over, the streak continues.
      now = day(11, 10);
      await game.award([game.activity(ActivityKind.answer, xp: 5, value: 1)]);
      final tomorrow = await game.watchProfile().first;
      expect(tomorrow.streak.days, 2);
      expect(tomorrow.todayXp, lessThan(tomorrow.totalXp));
      await game.dispose();
      await db.close();
    });

    test('recordLesson keeps the best stars and counts completions', () async {
      final db = memoryDb();
      final game = GameService(db);
      await game.recordLesson('grammar:p1', stars: 3, accuracy: 0.95);
      await game.recordLesson('grammar:p1', stars: 1, accuracy: 0.5);
      final p = (await game.watchLessonProgress().first)['grammar:p1']!;
      expect((p.stars, p.bestAccuracy, p.completions), (3, 0.95, 2));
      await db.close();
    });
  });

  group('ExerciseSession', () {
    test('a miss comes back once at the end and costs a star', () {
      final s = ExerciseSession([_q, _q2]);
      s.answer(false);
      s.next();
      s.answer(true);
      s.next();
      expect(s.current, same(_q), reason: 'missed exercise repeats');
      s.answer(true);
      s.next();
      expect(s.finished, isTrue);
      expect((s.correctFirstTry, s.mistakes, s.stars, s.perfect), (1, 1, 1, false));
      expect(s.bestCombo, 2);
    });

    test('hearts end a challenge early', () {
      final s = ExerciseSession([_q, _q2, _q, _q2], hearts: 2, retryMistakes: false);
      s.answer(false);
      s.next();
      s.answer(false);
      expect(s.failed, isTrue);
      s.next();
      expect(s.finished, isTrue);
    });

    test('perfect run gets 3 stars and combo XP', () {
      final s = ExerciseSession([_q, _q2, _q]);
      for (var i = 0; i < 3; i++) {
        s.answer(true);
        s.next();
      }
      expect((s.stars, s.perfect, s.xp), (3, true, 5 + 5 + 6));
    });
  });
}
