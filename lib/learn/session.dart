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

  /// Speaking exercises passed (also counts toward "spoken" quests and badges).
  int spoken = 0;

  /// Exercises skipped with "Can't talk now"; they don't count for or against accuracy.
  int skipped = 0;
  final Set<int> missedWordIds = {};
  final Set<String> missedSkillIds = {};

  /// First-try results per skill: (right, wrong). Drives skill scheduling after a Gym round.
  final Map<String, (int, int)> skillResults = {};

  /// Set after each answer until [next] is called.
  bool? lastCorrect;
  int lastXp = 0;

  Exercise? get current => _index < _queue.length && !failed ? _queue[_index] : null;
  bool get finished => current == null;
  bool get failed => hearts != null && mistakes >= hearts!;
  int get heartsLeft => hearts == null ? 0 : (hearts! - mistakes).clamp(0, hearts!);

  /// Progress through the first pass, 0..1 (retries don't move the bar back).
  double get progress => (_index.clamp(0, total) / total).clamp(0, 1).toDouble();

  /// Share of exercises answered right on the first try (skipped ones left out).
  double get accuracy => total - skipped <= 0 ? 1 : (correctFirstTry / (total - skipped)).clamp(0.0, 1.0);

  /// 3 stars for 90%+, 2 for 70%+, otherwise 1.
  int get stars => accuracy >= 0.9 ? 3 : accuracy >= 0.7 ? 2 : 1;
  bool get perfect => mistakes == 0;

  void answer(bool correct) {
    final ex = current;
    if (ex == null || lastCorrect != null) return;
    lastCorrect = correct;
    final retry = _missed.contains(ex);
    if (!retry) {
      for (final s in ex.skillIds) {
        final (r, w) = skillResults[s] ?? (0, 0);
        skillResults[s] = correct ? (r + 1, w) : (r, w + 1);
      }
    }
    if (correct) {
      combo++;
      if (combo > bestCombo) bestCombo = combo;
      lastXp = Xp.forAnswer(combo);
      xp += lastXp;
      if (!retry) correctFirstTry++;
      if (ex is SentenceExercise || ex is DictationExercise) sentencesBuilt++;
      if (ex is SpeakExercise) spoken++;
    } else {
      combo = 0;
      lastXp = 0;
      mistakes++;
      missedWordIds.addAll(ex.wordIds);
      missedSkillIds.addAll(ex.skillIds);
      if (retryMistakes && !retry) {
        _missed.add(ex);
        _queue.add(ex);
      }
    }
    notifyListeners();
  }

  /// Moves past the current exercise without judging it.
  void skip() {
    if (current == null || lastCorrect != null) return;
    if (!_missed.contains(current)) skipped++;
    _index++;
    notifyListeners();
  }

  void next() {
    if (lastCorrect == null) return;
    lastCorrect = null;
    _index++;
    notifyListeners();
  }
}
