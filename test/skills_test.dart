import 'package:flutter_test/flutter_test.dart';
import 'package:korean_cards/learn/exercises.dart';
import 'package:korean_cards/learn/mistakes.dart';
import 'package:korean_cards/learn/session.dart';
import 'package:korean_cards/learn/skill_service.dart';
import 'package:korean_cards/learn/skills.dart';
import 'package:korean_cards/srs/scheduler.dart';

import 'helpers.dart';

ChoiceExercise q(int wordId, {String? skill}) => ChoiceExercise(
      instruction: 'q',
      prompt: 'p$wordId',
      style: PromptStyle.korean,
      options: const ['a', 'b'],
      answer: 0,
      wordIds: [wordId],
      skillIds: [?skill],
    );

/// Answers [exercises] in order: true = right on the first try.
ExerciseSession run(List<Exercise> exercises, List<bool> answers) {
  final s = ExerciseSession(exercises, retryMistakes: false);
  for (final a in answers) {
    s.answer(a);
    s.next();
  }
  return s;
}

void main() {
  test('round results become FSRS ratings', () {
    expect(SkillService.ratingFor(4, 0), Rating.good);
    expect(SkillService.ratingFor(3, 1), Rating.hard);
    expect(SkillService.ratingFor(1, 1), Rating.again);
    expect(SkillService.ratingFor(0, 2), Rating.again);
  });

  test('skills get scheduled, seeded from lessons, and picked due-first', () async {
    final db = memoryDb();
    var now = DateTime(2026, 10, 27, 9);
    final svc = SkillService(db, Scheduler(), clock: () => now);

    await svc.seedLesson('p1');
    final rows = await svc.rows();
    expect(rows.keys, contains('p_topic'));
    expect(rows['p_topic']!.attempts, 1);

    await svc.recordResults({'t_past': (4, 0), 'p_object': (1, 3)});
    final after = await svc.rows();
    expect(after['t_past']!.correct, 4);
    expect(after['p_object']!.lapses + after['p_object']!.reps, greaterThan(0));

    // A day later everything practised is due; due skills lead the round.
    now = now.add(const Duration(days: 1));
    final round = await svc.pickRound();
    expect(round.values.fold(0, (a, b) => a + b), 12);
    expect(round.keys.toSet().intersection({'p_topic', 't_past', 'p_object'}), isNotEmpty);
    expect(await svc.pickRound(only: 'p_at'), {'p_at': 12});
    final numbers = await svc.pickRound(groups: {SkillGroup.numbers});
    expect(numbers.keys.every((k) => k.startsWith('n_')), isTrue);
    await db.close();
  });

  test('mastery grows with strength and accuracy', () async {
    final db = memoryDb();
    var now = DateTime(2026, 10, 1, 9);
    final svc = SkillService(db, Scheduler(), clock: () => now);
    for (var i = 0; i < 6; i++) {
      await svc.recordResults({'t_future': (4, 0)});
      final r = (await svc.rows())['t_future']!;
      now = r.due.add(const Duration(minutes: 1));
    }
    expect(SkillService.mastery((await svc.rows())['t_future']), greaterThan(0.8));
    expect(SkillService.mastery(null), 0);
    await db.close();
  });

  test('a mistake clears after two right answers in later sessions', () async {
    final db = memoryDb();
    final svc = MistakeService(db);
    await svc.recordSession([q(1), q(2, skill: 'p_object')], run([q(1), q(2, skill: 'p_object')], [false, false]));
    var open = await svc.open();
    expect(open.map((m) => (m.wordId, m.skillId)).toSet(), {(1, null), (2, null), (null, 'p_object')});

    // Word 1 right twice → resolved; word 2 wrong again → stays open with streak 0.
    for (var i = 0; i < 2; i++) {
      await svc.recordSession([q(1), q(2, skill: 'p_object')], run([q(1), q(2, skill: 'p_object')], [true, false]));
    }
    open = await svc.open();
    expect(open.where((m) => m.wordId == 1), isEmpty);
    expect(open.where((m) => m.wordId == 2).single.rightStreak, 0);
    final (words, skillIds) = await svc.recent();
    expect(words, [2]);
    expect(skillIds, ['p_object']);
    await db.close();
  });
}
