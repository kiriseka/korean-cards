import 'dart:math';

import '../data/db.dart';
import 'exercises.dart';

/// The three steps of "Today's session".
enum DailyStep {
  review('Review', '🔁', 'Flashcards that are due'),
  speakListen('Speak & listen', '🎧', 'Shadow, reply, dictation'),
  learn('Something new', '✨', 'A scene, lesson or grammar point');

  const DailyStep(this.title, this.emoji, this.description);
  final String title;
  final String emoji;
  final String description;

  /// Stored as the `value` of a `daily` activity when the step is finished.
  int get code => index + 1;
  static const completeCode = 99;
}

/// Time budget for one session.
class DailyBudget {
  const DailyBudget(this.minutes);
  final int minutes;

  /// About 40% of the time for flashcards at ~10 seconds a card.
  int get reviewCards => (minutes * 60 * 0.4 / 10).round();

  /// Roughly one speaking/listening item per 2.5 minutes of the session.
  int get speakListenItems => (minutes / 2.5).round().clamp(4, 8);
}

/// Speaking and listening practice drawn from words the user knows.
///
/// Spoken-style KRDict mini dialogues are preferred for shadowing (they're how people talk);
/// written example sentences feed dictation.
List<Exercise> speakListenSet({
  required List<Word> known,
  required List<Word> phrases,
  required List<Word> pool,
  required int count,
  required bool speakingOn,
  Random? random,
}) {
  final rng = random ?? Random();
  final gen = ExerciseGenerator(pool: pool, random: rng);
  final bank = SentenceBank.fromWords(known.isEmpty ? pool.take(200) : known, maxLength: 28);
  final dialogues = [...bank.dialogues]..shuffle(rng);
  final sentences = [...bank.sentences]..shuffle(rng);
  final allDialogues = [for (final d in SentenceBank.fromWords(pool).dialogues) d.$1];
  final out = <Exercise>[];

  void addShadow() {
    if (dialogues.isNotEmpty) {
      final (d, id) = dialogues.removeLast();
      out.add(gen.shadow(d[1], wordId: id));
    } else if (sentences.isNotEmpty) {
      final (s, id) = sentences.removeLast();
      out.add(gen.shadow(s, wordId: id));
    }
  }

  void addReply() {
    if (dialogues.isEmpty) return;
    final (d, id) = dialogues.removeLast();
    final ex = gen.reply(d, allDialogues, wordId: id);
    if (ex != null) out.add(ex);
  }

  void addDictation() {
    if (sentences.isEmpty) return;
    final (s, id) = sentences.removeLast();
    out.add(gen.dictation(s, wordId: id, decoys: [for (final x in sentences.take(6)) x.$1]));
  }

  void addPhrase() {
    if (phrases.isEmpty) return;
    final p = phrases[rng.nextInt(phrases.length)];
    out.add(speakingOn ? gen.speakSay(p) : gen.reverse(p));
  }

  final plan = speakingOn
      ? [addShadow, addReply, addDictation, addPhrase, addShadow, addReply, addShadow, addDictation]
      : [addReply, addDictation, addPhrase, addReply, addDictation, addPhrase, addReply, addDictation];
  for (final step in plan) {
    if (out.length >= count) break;
    step();
  }
  // Thin data (very early on): top up with listening questions.
  final words = (known.isEmpty ? pool : known).toList()..shuffle(rng);
  for (final w in words) {
    if (out.length >= count) break;
    out.add(gen.listening(w));
  }
  return out;
}
