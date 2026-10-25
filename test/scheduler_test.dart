import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:korean_cards/data/db.dart';
import 'package:korean_cards/srs/scheduler.dart';

StudyCard newCard() => StudyCard(
      id: 1,
      wordId: 1,
      direction: Direction.koToEn,
      state: CardState.newCard,
      due: DateTime(2026, 1, 1),
      reps: 0,
      lapses: 0,
      suspended: false,
    );

void main() {
  final scheduler = Scheduler(
    scheduler: fsrs.Scheduler(
      learningSteps: const [Duration(minutes: 1), Duration(minutes: 10)],
      relearningSteps: const [Duration(minutes: 10)],
      enableFuzzing: false,
    ),
  );
  final now = DateTime(2026, 10, 26, 9);

  test('a new card follows the learning steps', () {
    final p = scheduler.preview(newCard(), now);
    expect(p[Rating.again]!.interval, const Duration(minutes: 1));
    expect(p[Rating.good]!.interval, const Duration(minutes: 10));
    expect(p[Rating.easy]!.interval.inDays, greaterThanOrEqualTo(1));
    expect(p[Rating.good]!.card.state, CardState.learning);
    expect(p[Rating.easy]!.card.state, CardState.review);
    for (final o in p.values) {
      expect(o.card.reps, 1);
      expect(o.card.lastReview, now);
    }
  });

  test('graduated cards get growing intervals and lapses are counted', () {
    var card = newCard();
    var t = now;
    // Good twice graduates the card.
    for (var i = 0; i < 2; i++) {
      card = scheduler.preview(card, t)[Rating.good]!.card;
      t = card.due;
    }
    expect(card.state, CardState.review);

    final p = scheduler.preview(card, card.due);
    expect(p[Rating.hard]!.interval, lessThanOrEqualTo(p[Rating.good]!.interval));
    expect(p[Rating.good]!.interval, lessThan(p[Rating.easy]!.interval));
    final forgot = p[Rating.again]!.card;
    expect(forgot.state, CardState.relearning);
    expect(forgot.lapses, 1);
  });

  test('formatInterval', () {
    expect(formatInterval(const Duration(seconds: 30)), '1m');
    expect(formatInterval(const Duration(minutes: 10)), '10m');
    expect(formatInterval(const Duration(hours: 5)), '5h');
    expect(formatInterval(const Duration(days: 3)), '3d');
    expect(formatInterval(const Duration(days: 45)), '1.5mo');
    expect(formatInterval(const Duration(days: 730)), '2y');
  });
}
