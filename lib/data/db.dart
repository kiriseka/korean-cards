import 'dart:convert';

import 'package:drift/drift.dart';

import 'db.steps.dart';

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

/// The topic unit for the user's own words unless they pick another.
const customUnit = 'custom';

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

  /// Topic unit id from curriculum.json ("food", "custom", ...).
  TextColumn get unit => text().nullable()();

  /// KRDict conjugation forms for verbs/adjectives, JSON {"a": "들어", "euni": "들으니"}.
  TextColumn get forms => text().nullable()();

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

/// Everything that earns XP or counts toward quests and badges.
class Activities extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// One of [ActivityKind].
  TextColumn get kind => text()();
  IntColumn get xp => integer().withDefault(const Constant(0))();

  /// Kind-specific number: the rating, combo, stars or game score.
  IntColumn get value => integer().withDefault(const Constant(0))();

  /// Kind-specific id: lesson id, unit id, game id or quest id.
  TextColumn get ref => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

abstract final class ActivityKind {
  static const review = 'review';
  static const answer = 'answer';
  static const lesson = 'lesson';
  static const challenge = 'challenge';
  static const game = 'game';
  static const sentence = 'sentence';
  static const combo = 'combo';
  static const quest = 'quest';
  static const wordAdded = 'word_added';
  static const spoken = 'spoken';
  static const dialogue = 'dialogue';
  static const daily = 'daily';
}

class LessonProgress extends Table {
  TextColumn get lessonId => text()();
  IntColumn get stars => integer()();
  RealColumn get bestAccuracy => real()();
  IntColumn get completions => integer().withDefault(const Constant(1))();
  DateTimeColumn get firstCompletedAt => dateTime()();
  DateTimeColumn get lastCompletedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {lessonId};
}

class Achievements extends Table {
  TextColumn get id => text()();
  DateTimeColumn get unlockedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class QuestClaims extends Table {
  /// Start of the study day the quest belongs to.
  DateTimeColumn get day => dateTime()();
  TextColumn get questId => text()();

  @override
  Set<Column> get primaryKey => {day, questId};
}

class Sense {
  const Sense({
    required this.meanings,
    this.definition = '',
    this.example,
    this.examples = const [],
    this.dialogues = const [],
  });

  final List<String> meanings;
  final String definition;
  final String? example;

  /// Up to 3 KRDict example sentences (written style, Korean only).
  final List<String> examples;

  /// Two-line spoken mini dialogues from KRDict: [question, answer].
  final List<List<String>> dialogues;

  factory Sense.fromJson(Map<String, dynamic> json) => Sense(
        meanings: (json['meanings'] as List).cast<String>(),
        definition: json['definition'] as String? ?? '',
        example: json['example'] as String?,
        examples: ((json['examples'] as List?) ?? [if (json['example'] != null) json['example']]).cast<String>(),
        dialogues: [for (final d in (json['dialogues'] as List?) ?? const []) (d as List).cast<String>()],
      );

  Map<String, dynamic> toJson() => {
        'meanings': meanings,
        'definition': definition,
        'example': example,
        'examples': examples,
        'dialogues': dialogues,
      };
}

extension WordSenses on Word {
  List<Sense> get senseList =>
      (jsonDecode(senses) as List).map((s) => Sense.fromJson(s as Map<String, dynamic>)).toList();

  /// Short English gloss, e.g. "shop, store".
  String get gloss => senseList.isEmpty ? '' : senseList.first.meanings.join(', ');

  Map<String, dynamic>? get formsMap => forms == null ? null : jsonDecode(forms!) as Map<String, dynamic>;

  /// The unit a word is taught in; custom words without a topic live in "My words".
  String get unitId => unit ?? (isCustom ? customUnit : 'more');
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

@DriftDatabase(tables: [Words, Cards, ReviewLogs, Activities, LessonProgress, Achievements, QuestClaims])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: stepByStep(
          // v1.1: topics, conjugation forms and gamification. Word text is refreshed by the
          // importer on the next launch; review progress is untouched.
          from1To2: (m, schema) async {
            await m.addColumn(schema.words, schema.words.unit);
            await m.addColumn(schema.words, schema.words.forms);
            await m.createTable(schema.activities);
            await m.createTable(schema.lessonProgress);
            await m.createTable(schema.achievements);
            await m.createTable(schema.questClaims);
            await customStatement("UPDATE words SET unit = 'custom' WHERE is_custom = 1");
          },
        ),
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

  /// Phrases are always practised both ways: saying them is the point.
  Expression<bool> _reverseAllowed(bool reverse) =>
      reverse ? const Constant(true) : cards.direction.equals(Direction.koToEn) | words.pos.equals('phrase');

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

  Stream<List<Word>> watchUnitWords(String unitId) => (select(words)
        ..where((w) => unitId == customUnit ? w.unit.equals(customUnit) | (w.unit.isNull() & w.isCustom.equals(true)) : w.unit.equals(unitId))
        ..orderBy([(w) => OrderingTerm.asc(w.isCustom), (w) => OrderingTerm.asc(w.rank), (w) => OrderingTerm.asc(w.id)]))
      .watch();

  /// Ids of words whose Korean→English card has been studied at least once.
  Stream<Set<int>> watchLearnedWordIds() => (selectOnly(cards)
        ..addColumns([cards.wordId])
        ..where(cards.direction.equals(Direction.koToEn) & cards.state.isNotValue(CardState.newCard)))
      .map((r) => r.read(cards.wordId)!)
      .watch()
      .map((ids) => ids.toSet());

  Future<List<StudyCard>> newForwardCards(List<int> wordIds) => (select(cards)
        ..where((c) => c.wordId.isIn(wordIds) & c.direction.equals(Direction.koToEn) & c.state.equals(CardState.newCard)))
      .get();

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
    String unit = customUnit,
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
          senses: jsonEncode([Sense(meanings: meanings, example: example, examples: [?example]).toJson()]),
          rank: 0,
          isCustom: const Value(true),
          note: Value(note),
          unit: Value(unit),
        ));
        await ensureCards();
        return id;
      });

  Future<void> updateCustomWord(
    int id, {
    required String word,
    required String pos,
    required List<String> meanings,
    String? example,
    String? note,
    required String unit,
  }) =>
      (update(words)..where((w) => w.id.equals(id) & w.isCustom.equals(true))).write(WordsCompanion(
        word: Value(word),
        pos: Value(pos),
        senses: Value(jsonEncode([Sense(meanings: meanings, example: example, examples: [?example]).toJson()])),
        note: Value(note),
        unit: Value(unit),
      ));

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
