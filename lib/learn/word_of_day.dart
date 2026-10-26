import '../data/db.dart';

/// One word a day from the words learned so far (or the most common ones early on); the same
/// all study day, in the app and on the home-screen widget.
Word wordOfTheDay(List<Word> words, Set<int> learned, DateTime now) {
  var pool = words.where((w) => learned.contains(w.id)).toList();
  if (pool.length < 10) pool = (words.where((w) => w.level != '중급').toList()..sort((a, b) => a.rank.compareTo(b.rank))).take(300).toList();
  final day = studyDayStart(now);
  return pool[(day.year * 400 + day.month * 31 + day.day) % pool.length];
}
