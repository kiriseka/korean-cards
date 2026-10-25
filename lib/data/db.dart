import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'db.g.dart';

/// Card states. 1–3 match fsrs' State values; 0 means never studied.
abstract final class CardState {
  static const newCard = 0;
  static const learning = 1;
  static const review = 2;
  static const relearning = 3;
}

abstract final class Direction {
  static const koToEn = 0;
  static const enToKo = 1;
}

/// A review-state card whose interval is at least this many days counts as "known".
const knownStabilityDays = 21.0;

/// Ids for words added in the app start here, well above KRDict's ids.
const firstCustomWordId = 10000000;

class Words extends Table {
  IntColumn get id => integer()();
  TextColumn get word => text()();
  IntColumn get homonym => integer().withDefault(const Constant(0))();
  TextColumn get pos => text()();
  TextColumn get level => text()();
  TextColumn get hanja => text().nullable()();
  TextColumn get pronunciation => text().nullable()();
  TextColumn get category => text().nullable()();

  /// JSON list of {meanings: [..], definition, example}.
  TextColumn get senses => text()();
  IntColumn get rank => integer()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  BoolColumn get starred => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('StudyCard')
class Cards extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get wordId => integer().references(Words, #id, onDelete: KeyAction.cascade)();
  IntColumn get direction => integer()();
  IntColumn get state => integer().withDefault(const Constant(CardState.newCard))();
  IntColumn get step => integer().nullable()();
  RealColumn get stability => real().nullable()();
  RealColumn get difficulty => real().nullable()();
  DateTimeColumn get due => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastReview => dateTime().nullable()();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  BoolColumn get suspended => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {wordId, direction},
      ];
}

class ReviewLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cardId => integer().references(Cards, #id, onDelete: KeyAction.cascade)();
  IntColumn get rating => integer()();
  IntColumn get stateBefore => integer()();
  DateTimeColumn get reviewedAt => dateTime()();
  IntColumn get elapsedMs => integer()();
}

class Sense {
  const Sense({required this.meanings, this.definition = '', this.example});

  final List<String> meanings;
  final String definition;
  final String? example;

  factory Sense.fromJson(Map<String, dynamic> json) => Sense(
        meanings: (json['meanings'] as List).cast<String>(),
        definition: json['definition'] as String? ?? '',
        example: json['example'] as String?,
      );

  Map<String, dynamic> toJson() => {'meanings': meanings, 'definition': definition, 'example': example};
}

extension WordSenses on Word {
  List<Sense> get senseList =>
      (jsonDecode(senses) as List).map((s) => Sense.fromJson(s as Map<String, dynamic>)).toList();

  /// Short English gloss, e.g. "shop, store".
  String get gloss => senseList.isEmpty ? '' : senseList.first.meanings.join(', ');
}

class CardWithWord {
  const CardWithWord(this.card, this.word);
  final StudyCard card;
  final Word word;
}

enum WordFilter { all, newWords, learning, known, starred, suspended }

class TodayCounts {
  const TodayCounts({
    required this.due,
    required this.learning,
    required this.newAvailable,
    required this.reviewedToday,
    required this.newToday,
  });

  final int due;
  final int learning;
  final int newAvailable;
  final int reviewedToday;
  final int newToday;
}

class DayCount {
  const DayCount(this.day, this.count);
  final DateTime day;
  final int count;
}

class Overview {
  const Overview({
    required this.total,
    required this.newCount,
    required this.learning,
    required this.young,
    required this.known,
    required this.suspended,
  });

  final int total;
  final int newCount;
  final int learning;
  final int young;
  final int known;
  final int suspended;
}

/// The study day starts at 4am, like Anki, so a late-night session counts for the day before.
DateTime studyDayStart(DateTime now) {
  final start = DateTime(now.year, now.month, now.day, 4);
  return now.isBefore(start) ? addDays(start, -1) : start;
}

/// Calendar-day arithmetic that keeps the wall-clock time across daylight-saving changes.
DateTime addDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days, d.hour, d.minute);

@DriftDatabase(tables: [Words, Cards, ReviewLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'korean_cards'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async => customStatement('PRAGMA foreign_keys = ON'),
      );

  // ---- Study queue -------------------------------------------------------

  Future<List<CardWithWord>> _cardsWithWords(Expression<bool> where,
      {List<OrderingTerm> orderBy = const [], int? limit}) async {
    final query = select(cards).join([innerJoin(words, words.id.equalsExp(cards.wordId))])
      ..where(where & cards.suspended.equals(false))
      ..orderBy(orderBy);
    if (limit != null) query.limit(limit);
    final rows = await query.get();
    return rows.map((r) => CardWithWord(r.readTable(cards), r.readTable(words))).toList();
  }

  Expression<bool> _reverseAllowed(bool reverse) =>
      reverse ? const Constant(true) : cards.direction.equals(Direction.koToEn);

  /// Learning cards due soon and review cards due before the next study day.
  Future<List<CardWithWord>> dueCards(DateTime now, {required bool reverse, int? limit}) {
    final dayEnd = addDays(studyDayStart(now), 1);
    final learnAhead = now.add(const Duration(minutes: 20));
    return _cardsWithWords(
      _reverseAllowed(reverse) &
          ((cards.state.equals(CardState.review) & cards.due.isSmallerThanValue(dayEnd)) |
              (cards.state.isIn([CardState.learning, CardState.relearning]) &
                  cards.due.isSmallerOrEqualValue(learnAhead))),
      orderBy: [OrderingTerm.asc(cards.due)],
      limit: limit,
    );
  }

  /// New cards in learning order. A reverse card only becomes available once its word's
  /// forward card has been studied.
  Future<List<CardWithWord>> newCards({required bool reverse, required int limit}) {
    if (limit <= 0) return Future.value([]);
    final forwardStudied = existsQuery(
      select(cards.createAlias('f'))
        ..where((f) =>
            f.wordId.equalsExp(cards.wordId) &
            f.direction.equals(Direction.koToEn) &
            f.state.isNotValue(CardState.newCard)),
    );
    return _cardsWithWords(
      cards.state.equals(CardState.newCard) &
          (cards.direction.equals(Direction.koToEn) |
              (_reverseAllowed(reverse) & cards.direction.equals(Direction.enToKo) & forwardStudied)),
      orderBy: [OrderingTerm.asc(words.rank), OrderingTerm.asc(words.id), OrderingTerm.asc(cards.direction)],
      limit: limit,
    );
  }

  Future<int> newIntroducedSince(DateTime since) async {
    final count = reviewLogs.cardId.count(distinct: true);
    final query = selectOnly(reviewLogs)
      ..addColumns([count])
      ..where(reviewLogs.stateBefore.equals(CardState.newCard) & reviewLogs.reviewedAt.isBiggerOrEqualValue(since));
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<void> saveReview(StudyCard updated, ReviewLogsCompanion log) => transaction(() async {
        await update(cards).replace(updated);
        await into(reviewLogs).insert(log);
      });

  /// Recomputes the home screen counts whenever cards or logs change.
  Stream<TodayCounts> watchTodayCounts({required int newPerDay, required bool reverse}) {
    final trigger = customSelect('SELECT 1', readsFrom: {cards, reviewLogs}).watch();
    return trigger.asyncMap((_) async {
      final now = DateTime.now();
      final dayStart = studyDayStart(now);
      final due = await dueCards(now, reverse: reverse);
      final newToday = await newIntroducedSince(dayStart);
      final newAvailable = (await newCards(reverse: reverse, limit: (newPerDay - newToday).clamp(0, 9999))).length;
      final reviewed = reviewLogs.id.count();
      final reviewedToday = await (selectOnly(reviewLogs)
            ..addColumns([reviewed])
            ..where(reviewLogs.reviewedAt.isBiggerOrEqualValue(dayStart)))
          .map((r) => r.read(reviewed) ?? 0)
          .getSingle();
      return TodayCounts(
        due: due.where((c) => c.card.state == CardState.review).length,
        learning: due.where((c) => c.card.state != CardState.review).length,
        newAvailable: newAvailable,
        reviewedToday: reviewedToday,
        newToday: newToday,
      );
    });
  }

  // ---- Browse ------------------------------------------------------------

  Stream<List<CardWithWord>> watchWords({String query = '', WordFilter filter = WordFilter.all}) {
    final q = query.trim();
    Expression<bool> where = cards.direction.equals(Direction.koToEn);
    if (q.isNotEmpty) {
      where = where & (words.word.contains(q) | words.senses.contains(q) | words.note.contains(q));
    }
    where = where &
        switch (filter) {
          WordFilter.all => const Constant(true),
          WordFilter.newWords => cards.state.equals(CardState.newCard),
          WordFilter.learning => cards.state.isIn([CardState.learning, CardState.relearning]) |
              (cards.state.equals(CardState.review) & cards.stability.isSmallerThanValue(knownStabilityDays)),
          WordFilter.known =>
            cards.state.equals(CardState.review) & cards.stability.isBiggerOrEqualValue(knownStabilityDays),
          WordFilter.starred => words.starred.equals(true),
          WordFilter.suspended => cards.suspended.equals(true),
        };
    final select_ = select(cards).join([innerJoin(words, words.id.equalsExp(cards.wordId))])
      ..where(where)
      ..orderBy([OrderingTerm.asc(words.rank), OrderingTerm.asc(words.id)]);
    return select_.watch().map((rows) => rows.map((r) => CardWithWord(r.readTable(cards), r.readTable(words))).toList());
  }

  Stream<Word> watchWord(int id) => (select(words)..where((w) => w.id.equals(id))).watchSingle();

  Stream<List<StudyCard>> watchCardsForWord(int wordId) =>
      (select(cards)..where((c) => c.wordId.equals(wordId))..orderBy([(c) => OrderingTerm.asc(c.direction)])).watch();

  Future<void> setStarred(int wordId, bool starred) =>
      (update(words)..where((w) => w.id.equals(wordId))).write(WordsCompanion(starred: Value(starred)));

  Future<void> setNote(int wordId, String? note) =>
      (update(words)..where((w) => w.id.equals(wordId))).write(WordsCompanion(note: Value(note)));

  Future<void> setSuspended(int wordId, bool suspended) =>
      (update(cards)..where((c) => c.wordId.equals(wordId))).write(CardsCompanion(suspended: Value(suspended)));

  Future<void> resetProgress(int wordId) => (update(cards)..where((c) => c.wordId.equals(wordId))).write(
        CardsCompanion(
          state: const Value(CardState.newCard),
          step: const Value(null),
          stability: const Value(null),
          difficulty: const Value(null),
          due: Value(DateTime.now()),
          lastReview: const Value(null),
          reps: const Value(0),
          lapses: const Value(0),
        ),
      );

  Future<int> addCustomWord({
    required String word,
    required String pos,
    required List<String> meanings,
    String? example,
    String? note,
  }) =>
      transaction(() async {
        final maxId = words.id.max();
        final current = await (selectOnly(words)..addColumns([maxId])).map((r) => r.read(maxId)).getSingle();
        final id = (current ?? 0) < firstCustomWordId ? firstCustomWordId : current! + 1;
        await into(words).insert(WordsCompanion.insert(
          id: Value(id),
          word: word,
          pos: pos,
          level: 'custom',
          senses: jsonEncode([Sense(meanings: meanings, example: example).toJson()]),
          rank: 0,
          isCustom: const Value(true),
          note: Value(note),
        ));
        await ensureCards();
        return id;
      });

  Future<void> deleteWord(int wordId) => (delete(words)..where((w) => w.id.equals(wordId))).go();

  /// Creates the ko→en and en→ko cards for every word that is missing them.
  Future<void> ensureCards() async {
    for (final direction in [Direction.koToEn, Direction.enToKo]) {
      await customStatement(
        'INSERT OR IGNORE INTO cards (word_id, direction, state, due, reps, lapses, suspended) '
        'SELECT id, ?, 0, ?, 0, 0, 0 FROM words',
        [direction, DateTime.now().millisecondsSinceEpoch ~/ 1000],
      );
    }
  }

  // ---- Stats -------------------------------------------------------------

  Stream<Overview> watchOverview() {
    final trigger = customSelect('SELECT 1', readsFrom: {cards, words}).watch();
    return trigger.asyncMap((_) async {
      final rows = await customSelect(
        'SELECT '
        'COUNT(*) AS total, '
        'SUM(state = 0 AND suspended = 0) AS new_count, '
        'SUM(state IN (1, 3) AND suspended = 0) AS learning, '
        'SUM(state = 2 AND stability < ? AND suspended = 0) AS young, '
        'SUM(state = 2 AND stability >= ? AND suspended = 0) AS known, '
        'SUM(suspended) AS suspended '
        'FROM cards WHERE direction = 0',
        variables: [Variable.withReal(knownStabilityDays), Variable.withReal(knownStabilityDays)],
      ).getSingle();
      int read(String key) => rows.read<int?>(key) ?? 0;
      return Overview(
        total: read('total'),
        newCount: read('new_count'),
        learning: read('learning'),
        young: read('young'),
        known: read('known'),
        suspended: read('suspended'),
      );
    });
  }

  /// Reviews since [since], for the stats chart, retention and streak.
  Stream<List<ReviewLog>> watchLogsSince(DateTime since) =>
      (select(reviewLogs)..where((l) => l.reviewedAt.isBiggerOrEqualValue(since))).watch();
}
