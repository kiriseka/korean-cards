// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:korean_cards/data/db.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test('v1 progress survives the upgrade to v2', () async {
    const senses = '[{"meanings":["apple"],"definition":"A fruit.","example":null}]';
    const apple = v1.WordsData(
      id: 66371, word: '사과', homonym: 1, pos: 'noun', level: '초급', hanja: '沙果', pronunciation: '사과',
      category: '식생활 > 과일', senses: senses, rank: 10, isCustom: 0, starred: 1, note: 'my note',
    );
    const mine = v1.WordsData(
      id: 10000000, word: '맛있다', homonym: 0, pos: 'adjective', level: 'custom', senses: senses,
      rank: 0, isCustom: 1, starred: 0,
    );
    const card = v1.CardsData(
      id: 1, wordId: 66371, direction: 0, state: 2, step: null, stability: 30.5, difficulty: 4.2,
      due: 1790000000, lastReview: 1780000000, reps: 5, lapses: 1, suspended: 0,
    );
    const log = v1.ReviewLogsData(id: 1, cardId: 1, rating: 3, stateBefore: 2, reviewedAt: 1780000000, elapsedMs: 4200);

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.words, [apple, mine]);
        batch.insertAll(oldDb.cards, [card]);
        batch.insertAll(oldDb.reviewLogs, [log]);
      },
      validateItems: (newDb) async {
        final words = await newDb.select(newDb.words).get();
        expect(words.map((w) => (w.word, w.starred, w.note, w.unit)), [
          ('사과', 1, 'my note', null),
          ('맛있다', 0, null, 'custom'),
        ]);
        final cards = await newDb.select(newDb.cards).get();
        expect(cards.single.toJson(), {...card.toJson()});
        expect((await newDb.select(newDb.reviewLogs).get()).single.toJson(), log.toJson());
        expect(await newDb.select(newDb.activities).get(), isEmpty);
      },
    );
  });
}
