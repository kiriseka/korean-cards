import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:korean_cards/data/db.dart';
import 'package:korean_cards/data/word_importer.dart';
import 'package:korean_cards/services/backup_service.dart';

import 'helpers.dart';

Future<void> study(AppDatabase db, CardWithWord c, {int state = CardState.review, double stability = 5}) =>
    db.saveReview(
      c.card.copyWith(
        state: state,
        stability: Value(stability),
        difficulty: const Value(5),
        due: DateTime.now().add(const Duration(days: 3)),
        lastReview: Value(DateTime.now()),
        reps: c.card.reps + 1,
      ),
      ReviewLogsCompanion.insert(
        cardId: c.card.id,
        rating: 3,
        stateBefore: c.card.state,
        reviewedAt: DateTime.now(),
        elapsedMs: 1000,
      ),
    );

void main() {
  test('new cards come in rank order and respect the limit', () async {
    final db = await seededDb();
    final cards = await db.newCards(reverse: false, limit: 3);
    expect(cards.map((c) => c.word.word), ['사과', '학교', '물']);
    expect(cards.every((c) => c.card.direction == Direction.koToEn), isTrue);
    await db.close();
  });

  test('a reverse card unlocks only after its forward card is studied', () async {
    final db = await seededDb(2);
    expect((await db.newCards(reverse: true, limit: 10)).length, 2);
    final first = (await db.newCards(reverse: false, limit: 1)).single;
    await study(db, first);
    final fresh = await db.newCards(reverse: true, limit: 10);
    expect(fresh.map((c) => (c.word.word, c.card.direction)), [('사과', Direction.enToKo), ('학교', Direction.koToEn)]);
    expect(await db.newCards(reverse: false, limit: 10), hasLength(1));
    await db.close();
  });

  test('re-importing keeps progress, stars and notes but updates word text', () async {
    final db = await seededDb(2);
    final first = (await db.newCards(reverse: false, limit: 1)).single;
    await study(db, first);
    await db.setStarred(first.word.id, true);
    await db.setNote(first.word.id, 'apple!');

    await importWords(db, [wordJson(100, '사과', meaning: 'apple'), wordJson(101, '학교', rank: 2)]);

    final word = await db.watchWord(100).first;
    expect(word.gloss, 'apple');
    expect(word.starred, isTrue);
    expect(word.note, 'apple!');
    final cards = await db.watchCardsForWord(100).first;
    expect(cards.first.state, CardState.review);
    expect(await db.select(db.cards).get(), hasLength(4));
    await db.close();
  });

  test('new cards introduced today are counted once', () async {
    final db = await seededDb(3);
    final first = (await db.newCards(reverse: false, limit: 1)).single;
    await study(db, first, state: CardState.learning);
    expect(await db.newIntroducedSince(studyDayStart(DateTime.now())), 1);
    await db.close();
  });

  test('custom words are studied first and can be deleted', () async {
    final db = await seededDb(2);
    final id = await db.addCustomWord(word: '맛있다', pos: 'adjective', meanings: ['delicious']);
    expect(id, firstCustomWordId);
    expect((await db.newCards(reverse: false, limit: 1)).single.word.word, '맛있다');
    await db.deleteWord(id);
    expect(await db.select(db.cards).get(), hasLength(4));
    await db.close();
  });

  test('backup round trip restores progress', () async {
    final db = await seededDb(3);
    final first = (await db.newCards(reverse: false, limit: 1)).single;
    await study(db, first, stability: 30);
    await db.setStarred(first.word.id, true);
    await db.addCustomWord(word: '맛있다', pos: 'adjective', meanings: ['delicious'], note: 'yum');
    final json = await BackupService(db).export();

    final fresh = await seededDb(3);
    await BackupService(fresh).import(json);
    final overview = await fresh.watchOverview().first;
    expect(overview.known, 1);
    expect(overview.total, 4);
    expect((await fresh.watchWord(first.word.id).first).starred, isTrue);
    expect(await fresh.select(fresh.reviewLogs).get(), hasLength(1));
    expect(() => BackupService(fresh).import('{"app":"other"}'), throwsFormatException);
    await db.close();
    await fresh.close();
  });

  test('study day starts at 4am', () {
    expect(studyDayStart(DateTime(2026, 10, 26, 2)), DateTime(2026, 10, 25, 4));
    expect(studyDayStart(DateTime(2026, 10, 26, 5)), DateTime(2026, 10, 26, 4));
  });
}
