/// Decides when a spoken answer is over.
///
/// Android's recognizer stops at the first short pause, and the plugin's own pause timer starts
/// counting before the learner has said a word. So the app keeps listening through both and
/// asks this policy instead: generous time to start, a natural pause allowed mid-sentence, and
/// a hard cap so the mic never stays on forever.
class ListenPolicy {
  const ListenPolicy({
    this.startGrace = const Duration(seconds: 8),
    this.trailingSilence = const Duration(seconds: 3),
    this.maxTake = const Duration(seconds: 25),
  });

  /// How long to wait for the first word.
  final Duration startGrace;

  /// Quiet after the last word that means "done".
  final Duration trailingSilence;

  /// The longest a take may run.
  final Duration maxTake;

  /// Whether to stop listening, given when the take [started] and when the words last
  /// changed ([lastHeard], null while nothing has been heard).
  bool shouldStop({required DateTime started, required DateTime? lastHeard, required DateTime now}) {
    if (now.difference(started) >= maxTake) return true;
    if (lastHeard == null) return now.difference(started) >= startGrace;
    return now.difference(lastHeard) >= trailingSilence;
  }
}
