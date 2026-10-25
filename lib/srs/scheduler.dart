import 'package:drift/drift.dart' show Value;
import 'package:fsrs/fsrs.dart' as fsrs;

import '../data/db.dart';

enum Rating {
  again(fsrs.Rating.again, 'Again'),
  hard(fsrs.Rating.hard, 'Hard'),
  good(fsrs.Rating.good, 'Good'),
  easy(fsrs.Rating.easy, 'Easy');

  const Rating(this.fsrsRating, this.label);
  final fsrs.Rating fsrsRating;
  final String label;
}

/// The outcome of rating a card, computed before the user picks so the buttons can show intervals.
class ReviewOutcome {
  const ReviewOutcome(this.card, this.interval);
  final StudyCard card;
  final Duration interval;
}

/// Wraps FSRS: converts between database rows and fsrs cards.
class Scheduler {
  Scheduler({fsrs.Scheduler? scheduler})
      : _fsrs = scheduler ??
            fsrs.Scheduler(
              learningSteps: const [Duration(minutes: 1), Duration(minutes: 10)],
              relearningSteps: const [Duration(minutes: 10)],
            );

  final fsrs.Scheduler _fsrs;

  /// Rating outcomes for every button. Fuzzing makes each call slightly random, so the
  /// chosen outcome must be the one shown, not a fresh computation.
  Map<Rating, ReviewOutcome> preview(StudyCard card, DateTime now) {
    final utcNow = now.toUtc();
    return {
      for (final rating in Rating.values) rating: _review(card, rating, utcNow),
    };
  }

  ReviewOutcome _review(StudyCard card, Rating rating, DateTime utcNow) {
    final result = _fsrs.reviewCard(_toFsrs(card), rating.fsrsRating, reviewDateTime: utcNow);
    final next = result.card;
    final updated = card.copyWith(
      state: next.state.value,
      step: Value(next.step),
      stability: Value(next.stability),
      difficulty: Value(next.difficulty),
      due: next.due.toLocal(),
      lastReview: Value(utcNow.toLocal()),
      reps: card.reps + 1,
      lapses: card.lapses + (rating == Rating.again && card.state == CardState.review ? 1 : 0),
    );
    return ReviewOutcome(updated, next.due.difference(utcNow));
  }

  fsrs.Card _toFsrs(StudyCard card) {
    if (card.state == CardState.newCard) {
      return fsrs.Card(cardId: card.id, due: card.due.toUtc());
    }
    return fsrs.Card(
      cardId: card.id,
      state: fsrs.State.fromValue(card.state),
      step: card.step,
      stability: card.stability,
      difficulty: card.difficulty,
      due: card.due.toUtc(),
      lastReview: card.lastReview?.toUtc(),
    );
  }
}

/// "1m", "10m", "3h", "4d", "2.5mo", "1.2y".
String formatInterval(Duration d) {
  final minutes = d.inMinutes;
  if (minutes < 60) return '${minutes < 1 ? 1 : minutes}m';
  final hours = d.inHours;
  if (hours < 24) return '${hours}h';
  final days = (d.inHours / 24).round();
  if (days < 30) return '${days}d';
  if (days < 365) return '${_oneDecimal(days / 30)}mo';
  return '${_oneDecimal(days / 365)}y';
}

String _oneDecimal(double v) => v.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
