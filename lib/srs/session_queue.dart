import '../data/db.dart';

/// Orders the cards of one study session.
///
/// Learning cards come first, then reviews with new cards spread evenly between them.
/// Cards rated into a short learning step come back once they are due; if nothing else is
/// left, the earliest one is shown early instead of ending the session.
class SessionQueue {
  SessionQueue({required List<CardWithWord> due, required List<CardWithWord> newCards}) {
    final learning = due.where((c) => c.card.state != CardState.review).toList();
    final reviews = due.where((c) => c.card.state == CardState.review).toList();
    _main.addAll(learning);
    _main.addAll(_interleave(reviews, newCards));
  }

  final List<CardWithWord> _main = [];
  final List<CardWithWord> _pending = [];

  static List<CardWithWord> _interleave(List<CardWithWord> reviews, List<CardWithWord> newCards) {
    if (reviews.isEmpty) return [...newCards];
    if (newCards.isEmpty) return [...reviews];
    final result = <CardWithWord>[];
    final gap = (reviews.length + newCards.length) / newCards.length;
    var r = 0, n = 0;
    for (var i = 0; r < reviews.length || n < newCards.length; i++) {
      final takeNew = n < newCards.length && (r >= reviews.length || i >= (n * gap + gap / 2).floor());
      result.add(takeNew ? newCards[n++] : reviews[r++]);
    }
    return result;
  }

  int get remaining => _main.length + _pending.length;
  bool get isEmpty => remaining == 0;

  /// The next card to show, removed from the queue; null when the session is over.
  CardWithWord? next(DateTime now) {
    _pending.sort((a, b) => a.card.due.compareTo(b.card.due));
    if (_pending.isNotEmpty && !_pending.first.card.due.isAfter(now)) return _pending.removeAt(0);
    if (_main.isNotEmpty) return _main.removeAt(0);
    if (_pending.isNotEmpty) return _pending.removeAt(0);
    return null;
  }

  /// Puts a just-rated card back if it is due again within the session.
  void requeueIfDueSoon(CardWithWord item, DateTime now) {
    final soon = now.add(const Duration(minutes: 20));
    if (item.card.state != CardState.review && item.card.due.isBefore(soon)) {
      _pending.add(item);
    }
  }
}
