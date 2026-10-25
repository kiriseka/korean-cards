import 'package:flutter_test/flutter_test.dart';
import 'package:korean_cards/data/db.dart';
import 'package:korean_cards/srs/session_queue.dart';

final now = DateTime(2026, 10, 26, 9);

CardWithWord item(int id, int state, {DateTime? due}) => CardWithWord(
      StudyCard(
        id: id,
        wordId: id,
        direction: Direction.koToEn,
        state: state,
        due: due ?? now,
        reps: 0,
        lapses: 0,
        suspended: false,
      ),
      Word(
        id: id,
        word: 'w$id',
        homonym: 0,
        pos: 'noun',
        level: '초급',
        senses: '[]',
        rank: id,
        isCustom: false,
        starred: false,
      ),
    );

List<int> drain(SessionQueue q) => [for (var c = q.next(now); c != null; c = q.next(now)) c.card.id];

void main() {
  test('learning first, then reviews with new cards spread between them', () {
    final q = SessionQueue(
      due: [item(1, CardState.review), item(2, CardState.learning), item(3, CardState.review), item(4, CardState.review)],
      newCards: [item(10, CardState.newCard), item(11, CardState.newCard)],
    );
    final order = drain(q);
    expect(order.first, 2);
    expect(order.toSet(), {1, 2, 3, 4, 10, 11});
    // New cards are not bunched at the end.
    expect(order.indexOf(10), lessThan(order.indexOf(4)));
  });

  test('only new cards', () {
    final q = SessionQueue(due: [], newCards: [item(10, CardState.newCard), item(11, CardState.newCard)]);
    expect(drain(q), [10, 11]);
  });

  test('a card due again soon comes back; the earliest is shown early when nothing else is left', () {
    final q = SessionQueue(due: [], newCards: [item(10, CardState.newCard), item(11, CardState.newCard)]);
    final first = q.next(now)!;
    q.requeueIfDueSoon(item(first.card.id, CardState.learning, due: now.add(const Duration(minutes: 10))), now);
    expect(q.remaining, 2);
    expect(q.next(now)!.card.id, 11);
    expect(q.next(now)!.card.id, 10);
    expect(q.next(now), isNull);
  });

  test('a graduated card is not requeued', () {
    final q = SessionQueue(due: [], newCards: []);
    q.requeueIfDueSoon(item(1, CardState.review, due: now.add(const Duration(days: 3))), now);
    expect(q.isEmpty, isTrue);
  });
}
