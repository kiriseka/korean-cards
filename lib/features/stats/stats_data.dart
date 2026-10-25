import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../providers.dart';

/// The last year of reviews: enough for the streak, the 30-day chart and retention.
final recentLogsProvider = StreamProvider<List<ReviewLog>>((ref) {
  final since = addDays(studyDayStart(DateTime.now()), -365);
  return ref.watch(dbProvider).watchLogsSince(since);
});

/// Consecutive study days with a review, counting today only once something is reviewed.
int streakOf(List<ReviewLog> logs, DateTime now) {
  final days = {for (final l in logs) studyDayStart(l.reviewedAt)};
  var day = studyDayStart(now);
  if (!days.contains(day)) day = addDays(day, -1);
  var streak = 0;
  while (days.contains(day)) {
    streak++;
    day = addDays(day, -1);
  }
  return streak;
}

/// Reviews per study day for the last [days] days, oldest first.
List<DayCount> reviewsPerDay(List<ReviewLog> logs, DateTime now, {int days = 30}) {
  final counts = <DateTime, int>{};
  for (final l in logs) {
    final d = studyDayStart(l.reviewedAt);
    counts[d] = (counts[d] ?? 0) + 1;
  }
  final today = studyDayStart(now);
  return [
    for (var i = days - 1; i >= 0; i--)
      DayCount(addDays(today, -i), counts[addDays(today, -i)] ?? 0),
  ];
}

/// Share of reviews of graduated cards (not learning steps) that were not "Again", or null if none.
double? retentionOf(List<ReviewLog> logs, DateTime since) {
  final reviews = logs.where((l) => l.stateBefore == CardState.review && !l.reviewedAt.isBefore(since)).toList();
  if (reviews.isEmpty) return null;
  return reviews.where((l) => l.rating != 1).length / reviews.length;
}
