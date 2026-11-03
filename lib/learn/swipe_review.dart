import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db.dart';
import '../game/rules.dart';
import '../game/sound_service.dart';
import '../providers.dart';
import '../srs/scheduler.dart';

/// Records a card swipe: right puts the word in the learned pile and rates the card Good,
/// left puts it in the hard pile and rates it Again (so it comes back soon).
///
/// With [schedule] false only the pile changes: re-drilling a deck the same day shouldn't
/// earn XP again or push the card's next review further out. Returns the card as saved.
Future<StudyCard> recordSwipe(
  WidgetRef ref,
  CardWithWord item, {
  required bool learned,
  required DateTime shownAt,
  bool schedule = true,
}) async {
  HapticFeedback.lightImpact();
  ref.read(soundProvider).play(learned ? Sfx.tap : Sfx.flip);
  final db = ref.read(dbProvider);
  await db.setPile(item.word.id, learned ? Pile.learned : Pile.hard);
  if (!schedule) return item.card;

  final rating = learned ? Rating.good : Rating.again;
  final now = DateTime.now();
  final outcome = ref.read(schedulerProvider).preview(item.card, now)[rating]!;
  await db.saveReview(
    outcome.card,
    ReviewLogsCompanion.insert(
      cardId: item.card.id,
      rating: rating.fsrsRating.value,
      stateBefore: item.card.state,
      reviewedAt: now,
      elapsedMs: now.difference(shownAt).inMilliseconds,
    ),
  );
  final game = ref.read(gameProvider);
  game.award([
    game.activity(ActivityKind.review, xp: learned ? Xp.review : Xp.reviewAgain, value: rating.fsrsRating.value),
  ]);
  return outcome.card;
}
