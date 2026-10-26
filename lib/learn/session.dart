import 'package:flutter/foundation.dart';

import '../game/rules.dart';
import 'exercises.dart';

/// Runs a list of exercises: tracks the current one, combo, XP and mistakes.
///
/// A missed exercise comes back once at the end (Duolingo-style). With [hearts] set, that many
/// mistakes end the run (unit challenges).
class ExerciseSession extends ChangeNotifier {
  ExerciseSession(List<Exercise> exercises, {this.hearts, this.retryMistakes = true})
      : _queue = [...exercises],
        total = exercises.length;

  final List<Exercise> _queue;
  final int total;
  final int? hearts;
  final bool retryMistakes;

  final Set<Exercise> _missed = {};
  int _index = 0;
  int combo = 0;
  int bestCombo = 0;
  int xp = 0;
  int correctFirstTry = 0;
  int mistakes = 0;
  int sentencesBuilt = 0;
  final Set<int> missedWordIds = {};

  /// Set after each answer until [next] is called.
  bool? lastCorrect;
  int lastXp = 0;

  Exercise? get current => _index < _queue.length && !failed ? _queue[_index] : null;
  bool get finished => current == null;
  bool get failed => hearts != null && mistakes >= hearts!;
  int get heartsLeft => hearts == null ? 0 : (hearts! - mistakes).clamp(0, hearts!);

  /// Progress through the first pass, 0..1 (retries don't move the bar back).
  double get progress => (_index.clamp(0, total) / total).clamp(0, 1).toDouble();

  /// Share of exercises answered right on the first try.
  double get accuracy => total == 0 ? 1 : correctFirstTry / total;

  /// 3 stars for 90%+, 2 for 70%+, otherwise 1.
  int get stars => accuracy >= 0.9 ? 3 : accuracy >= 0.7 ? 2 : 1;
  bool get perfect => mistakes == 0;

  void answer(bool correct) {
    final ex = current;
    if (ex == null || lastCorrect != null) return;
    lastCorrect = correct;
    final retry = _missed.contains(ex);
    if (correct) {
      combo++;
      if (combo > bestCombo) bestCombo = combo;
      lastXp = Xp.forAnswer(combo);
      xp += lastXp;
      if (!retry) correctFirstTry++;
      if (ex is SentenceExercise) sentencesBuilt++;
    } else {
      combo = 0;
      lastXp = 0;
      mistakes++;
      missedWordIds.addAll(ex.wordIds);
      if (retryMistakes && !retry) {
        _missed.add(ex);
        _queue.add(ex);
      }
    }
    notifyListeners();
  }

  void next() {
    if (lastCorrect == null) return;
    lastCorrect = null;
    _index++;
    notifyListeners();
  }
}
