import '../data/db.dart';
import 'curriculum.dart';

/// A deck of word cards to drill: a topic, a level, a pile or the starred words.
class Drill {
  const Drill({
    required this.id,
    required this.title,
    required this.emoji,
    this.unit,
    this.level,
    this.pile,
    this.starred = false,
  });

  factory Drill.topic(TopicUnit unit) => Drill(id: 'topic:${unit.id}', title: unit.title, emoji: unit.emoji, unit: unit.id);

  static const beginner = Drill(id: 'level:초급', title: 'Beginner · 초급', emoji: '🌱', level: '초급');
  static const intermediate = Drill(id: 'level:중급', title: 'Level 2 · 중급', emoji: '🌳', level: intermediateLevel);
  static const hard = Drill(id: 'pile:hard', title: 'Hard words', emoji: '🔥', pile: Pile.hard);
  static const learned = Drill(id: 'pile:learned', title: 'Learned words', emoji: '✅', pile: Pile.learned);
  static const starredWords = Drill(id: 'starred', title: 'Starred', emoji: '⭐', starred: true);

  final String id;
  final String title;
  final String emoji;
  final String? unit;
  final String? level;
  final int? pile;
  final bool starred;

  /// Whether the user can narrow this deck to one level (it isn't a level deck already).
  bool get levelChoice => level == null;

  /// Whether "skip learned words" means anything (not for the learned pile itself).
  bool get canSkipLearned => pile != Pile.learned;

  bool _matches(DrillCountRow r, String? onlyLevel) =>
      (unit == null || r.unit == unit) &&
      (level == null || r.level == level) &&
      (onlyLevel == null || r.level == onlyLevel) &&
      (pile == null || r.pile == pile) &&
      (!starred || r.starred);

  /// How many of this deck's words (at [onlyLevel], if given) there are, learned and hard.
  DrillTally tally(List<DrillCountRow> rows, {String? onlyLevel}) {
    var total = 0, learned = 0, hard = 0;
    for (final r in rows.where((r) => _matches(r, onlyLevel))) {
      total += r.count;
      if (r.pile == Pile.learned) learned += r.count;
      if (r.pile == Pile.hard) hard += r.count;
    }
    return DrillTally(total: total, learned: learned, hard: hard);
  }

  /// The next round's cards, leaving out [except] (words already drilled this sitting).
  Future<List<CardWithWord>> load(AppDatabase db, DrillOptions options, {Iterable<int> except = const []}) => db.drillCards(
        unit: unit,
        level: level ?? options.level,
        pile: pile,
        starred: starred,
        skipLearned: options.skipLearned && canSkipLearned,
        exceptWordIds: except,
        limit: options.size,
      );
}

class DrillTally {
  const DrillTally({required this.total, required this.learned, required this.hard});
  final int total;
  final int learned;
  final int hard;
}

/// What the user picked before starting: one level, skip learned words, cards per round.
class DrillOptions {
  const DrillOptions({this.level, this.skipLearned = true, this.size = 20});
  final String? level;
  final bool skipLearned;

  /// Cards per round; null for the whole deck.
  final int? size;
}
