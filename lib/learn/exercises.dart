import 'dart:math';

import '../data/db.dart';
import '../grammar/conjugator.dart';
import '../grammar/hangul.dart';

/// One question in a lesson, challenge or arcade game.
sealed class Exercise {
  const Exercise({this.wordIds = const [], this.skillIds = const []});

  /// Words this exercise practises (for "words you got wrong").
  final List<int> wordIds;

  /// Grammar/number skills this exercise trains (Gym, smart review).
  final List<String> skillIds;
}

enum PromptStyle { korean, english, audio, sentence, dialogue }

/// Pick one of several options. Covers meaning checks, listening, particles and conjugation.
class ChoiceExercise extends Exercise {
  const ChoiceExercise({
    required this.instruction,
    required this.prompt,
    required this.style,
    required this.options,
    required this.answer,
    this.speak,
    this.subPrompt,
    this.explanation,
    this.optionsKorean = false,
    super.wordIds,
    super.skillIds,
  });

  final String instruction;
  final String prompt;
  final PromptStyle style;
  final List<String> options;
  final int answer;

  /// Korean text read aloud when the question appears (audio prompts) or on the answer.
  final String? speak;
  final String? subPrompt;
  final String? explanation;
  final bool optionsKorean;

  String get correct => options[answer];
}

/// Tap matching Korean/English pairs.
class MatchExercise extends Exercise {
  const MatchExercise({required this.pairs, super.wordIds});
  final List<(String korean, String english)> pairs;
}

/// Build the Korean word from shuffled syllable blocks (with decoys).
class SyllableExercise extends Exercise {
  const SyllableExercise({required this.english, required this.answer, required this.tiles, super.wordIds});
  final String english;
  final String answer;
  final List<String> tiles;
}

/// Type the Korean.
class TypingExercise extends Exercise {
  const TypingExercise({required this.prompt, required this.answer, this.hint, super.wordIds, super.skillIds});
  final String prompt;
  final String answer;
  final String? hint;

  /// Accepts the answer ignoring spaces and final punctuation.
  bool accepts(String input) {
    String norm(String s) => s.replaceAll(RegExp(r'[\s.?!]'), '');
    return norm(input) == norm(answer);
  }
}

/// Arrange word tiles into a sentence.
class SentenceExercise extends Exercise {
  const SentenceExercise({required this.english, required this.answer, required this.tiles, this.explanation, super.skillIds});
  final String english;
  final List<String> answer;
  final List<String> tiles;
  final String? explanation;

  String get sentence => answer.join(' ');
}

enum SpeakMode {
  /// Korean shown; read it aloud.
  readAloud,

  /// English shown; say it in Korean (recall).
  sayIt,

  /// Hear it first, then repeat; the text appears after trying.
  shadow,
}

/// Say something out loud; the phone's speech recognition checks it.
class SpeakExercise extends Exercise {
  const SpeakExercise({required this.target, required this.mode, this.english, super.wordIds, super.skillIds});
  final String target;
  final SpeakMode mode;
  final String? english;
}

/// Hear a sentence, rebuild it from word tiles (or type it).
class DictationExercise extends Exercise {
  const DictationExercise({required this.answer, required this.tiles, super.wordIds});
  final List<String> answer;
  final List<String> tiles;

  String get sentence => answer.join(' ');
}

/// Korean example sentences and spoken mini dialogues from KRDict, for listening and speaking.
class SentenceBank {
  SentenceBank(this.sentences, this.dialogues);

  /// (sentence, word id)
  final List<(String, int)> sentences;

  /// ([line A, line B], word id)
  final List<(List<String>, int)> dialogues;

  /// Collects short sentences from [words]; [maxLength] keeps them speakable.
  factory SentenceBank.fromWords(Iterable<Word> words, {int maxLength = 32}) {
    final sentences = <(String, int)>[];
    final dialogues = <(List<String>, int)>[];
    final seen = <String>{};
    for (final w in words) {
      for (final sense in w.senseList) {
        for (final e in sense.examples) {
          if (e.length <= maxLength && seen.add(e)) sentences.add((e, w.id));
        }
        for (final d in sense.dialogues) {
          if (d.length == 2 && seen.add(d.join('|'))) dialogues.add((d, w.id));
        }
      }
    }
    return SentenceBank(sentences, dialogues);
  }

  bool get isEmpty => sentences.isEmpty && dialogues.isEmpty;
}

/// Hangul letters standing alone (ㄹ, ㅂ) — never valid inside a finished word.
final _looseJamo = RegExp('[ㄱ-ㆎ]');

/// The first one or two meanings, short enough for an answer button.
String shortGloss(Word w) {
  final meanings = w.senseList.isEmpty ? <String>[] : w.senseList.first.meanings;
  return meanings.take(2).join(', ');
}

/// Builds exercises from words. [pool] supplies wrong options; same unit and part of speech first.
class ExerciseGenerator {
  ExerciseGenerator({required this.pool, Random? random}) : rng = random ?? Random();

  final List<Word> pool;
  final Random rng;

  List<Word> _distractors(Word target, int count, {required bool byKorean}) {
    String key(Word w) => byKorean ? w.word : shortGloss(w);
    final seen = {key(target), if (byKorean) target.word else shortGloss(target)};
    final ranked = [...pool]..shuffle(rng);
    int score(Word w) => (w.unitId == target.unitId ? 2 : 0) + (w.pos == target.pos ? 1 : 0);
    ranked.sort((a, b) => score(b).compareTo(score(a)));
    final out = <Word>[];
    for (final w in ranked) {
      if (w.id == target.id || !seen.add(key(w)) || key(w).isEmpty) continue;
      out.add(w);
      if (out.length == count) break;
    }
    return out;
  }

  ChoiceExercise _choice({
    required Word target,
    required String instruction,
    required String prompt,
    required PromptStyle style,
    required bool optionsKorean,
    String? speak,
  }) {
    final wrong = _distractors(target, 3, byKorean: optionsKorean);
    final options = [target, ...wrong]..shuffle(rng);
    return ChoiceExercise(
      instruction: instruction,
      prompt: prompt,
      style: style,
      options: [for (final w in options) optionsKorean ? w.word : shortGloss(w)],
      answer: options.indexOf(target),
      optionsKorean: optionsKorean,
      speak: speak ?? target.word,
      wordIds: [target.id],
    );
  }

  ChoiceExercise meaning(Word w) => _choice(
        target: w,
        instruction: 'What does this mean?',
        prompt: w.word,
        style: PromptStyle.korean,
        optionsKorean: false,
      );

  ChoiceExercise reverse(Word w) => _choice(
        target: w,
        instruction: 'Pick the Korean word',
        prompt: shortGloss(w),
        style: PromptStyle.english,
        optionsKorean: true,
      );

  ChoiceExercise listening(Word w, {bool pickKorean = true}) => _choice(
        target: w,
        instruction: pickKorean ? 'What did you hear?' : 'Listen: what does it mean?',
        prompt: w.word,
        style: PromptStyle.audio,
        optionsKorean: pickKorean,
      );

  MatchExercise match(List<Word> words) => MatchExercise(
        pairs: [for (final w in words) (w.word, shortGloss(w))],
        wordIds: [for (final w in words) w.id],
      );

  SyllableExercise? syllables(Word w) {
    final chars = w.word.replaceAll(' ', '').split('');
    if (chars.length < 2 || !chars.every((c) => syllableOf(c) != null)) return null;
    final decoys = <String>{};
    for (final other in [...pool]..shuffle(rng)) {
      for (final c in other.word.split('')) {
        if (syllableOf(c) != null && !chars.contains(c)) decoys.add(c);
      }
      if (decoys.length >= 2) break;
    }
    return SyllableExercise(
      english: shortGloss(w),
      answer: chars.join(),
      tiles: [...chars, ...decoys.take(2)]..shuffle(rng),
      wordIds: [w.id],
    );
  }

  TypingExercise typing(Word w) => TypingExercise(
        prompt: shortGloss(w),
        answer: w.word,
        hint: '${w.word.replaceAll(' ', '').length} syllables · starts with ${w.word[0]}',
        wordIds: [w.id],
      );

  SpeakExercise speakRead(Word w) => SpeakExercise(target: w.word, mode: SpeakMode.readAloud, english: shortGloss(w), wordIds: [w.id]);

  SpeakExercise speakSay(Word w) => SpeakExercise(target: w.word, mode: SpeakMode.sayIt, english: shortGloss(w), wordIds: [w.id]);

  SpeakExercise shadow(String sentence, {int? wordId, String? english}) =>
      SpeakExercise(target: sentence, mode: SpeakMode.shadow, english: english, wordIds: [?wordId]);

  /// Rebuild [sentence] after hearing it; two decoy words come from [decoys].
  DictationExercise dictation(String sentence, {int? wordId, List<String> decoys = const []}) {
    final answer = sentence.split(' ');
    final extra = <String>{};
    for (final d in [...decoys]..shuffle(rng)) {
      for (final token in d.split(' ')) {
        if (!answer.contains(token) && token.length >= 2) extra.add(token);
      }
      if (extra.length >= 2) break;
    }
    return DictationExercise(answer: answer, tiles: [...answer, ...extra.take(2)]..shuffle(rng), wordIds: [?wordId]);
  }

  /// Line A of a mini dialogue → pick B among replies from other dialogues.
  ChoiceExercise? reply(List<String> dialogue, List<List<String>> others, {int? wordId}) {
    final wrong = <String>{};
    for (final o in [...others]..shuffle(rng)) {
      if (o[1] != dialogue[1] && o[0] != dialogue[0]) wrong.add(o[1]);
      if (wrong.length == 3) break;
    }
    if (wrong.length < 2) return null;
    final options = [dialogue[1], ...wrong]..shuffle(rng);
    return ChoiceExercise(
      instruction: 'Pick the natural reply',
      prompt: dialogue[0],
      style: PromptStyle.dialogue,
      options: options,
      answer: options.indexOf(dialogue[1]),
      optionsKorean: true,
      speak: dialogue[1],
      wordIds: [?wordId],
    );
  }

  /// About 14 exercises covering every word of a topic lesson, easy to hard.
  /// Phrase lessons lean on speaking: saying a phrase is the whole point.
  List<Exercise> topicPractice(List<Word> words, {required bool typingOn, bool speakingOn = false}) {
    if (words.isNotEmpty && words.every((w) => w.pos == 'phrase')) {
      return _phrasePractice(words, typingOn: typingOn, speakingOn: speakingOn);
    }
    final shuffled = [...words]..shuffle(rng);
    final firstPass = shuffled.take(6).toList();
    final rest = shuffled.skip(6).toList();
    final matchWords = [...rest, ...firstPass.take(5 - rest.length.clamp(0, 5))].take(5).toList();
    final pick = [...words]..shuffle(rng);
    final out = <Exercise>[
      ...firstPass.map(meaning),
      if (matchWords.length >= 3) match(matchWords),
      reverse(pick[0]),
      listening(pick[1 % pick.length]),
      reverse(pick[2 % pick.length]),
      listening(pick[3 % pick.length], pickKorean: false),
      reverse(pick[4 % pick.length]),
    ];
    final built = pick.map(syllables).whereType<SyllableExercise>().firstOrNull;
    if (built != null) out.add(built);
    if (typingOn) {
      final short = pick.where((w) => w.word.length <= 4).toList();
      if (short.isNotEmpty) out.add(typing(short.last));
    }
    if (speakingOn) {
      out.insert(out.length ~/ 2, speakRead(pick[5 % pick.length]));
      out.add(speakSay(pick[6 % pick.length]));
    }
    return out;
  }

  List<Exercise> _phrasePractice(List<Word> words, {required bool typingOn, required bool speakingOn}) {
    final pick = [...words]..shuffle(rng);
    final out = <Exercise>[
      for (final w in pick.take(5)) meaning(w),
      if (pick.length >= 3) match(pick.take(5).toList()),
      for (final w in pick.skip(5).take(3)) reverse(w),
      listening(pick[0], pickKorean: false),
      listening(pick[1 % pick.length]),
    ];
    if (speakingOn) {
      for (final w in pick.take(2)) {
        out.add(speakRead(w));
      }
      for (final w in pick.skip(2).take(3)) {
        out.add(speakSay(w));
      }
    } else {
      for (final w in pick.skip(2).take(3)) {
        out.add(reverse(w));
      }
    }
    if (typingOn) {
      final short = pick.where((w) => w.word.replaceAll(RegExp(r'[.?!,]'), '').length <= 5).toList();
      if (short.isNotEmpty) out.add(typing(short.first));
    }
    return out;
  }

  /// A mixed quiz over many words (unit challenge, speed round).
  List<Exercise> quiz(List<Word> words, int count) {
    final picks = [...words]..shuffle(rng);
    return [
      for (var i = 0; i < count && picks.isNotEmpty; i++)
        switch (i % 4) {
          0 => meaning(picks[i % picks.length]),
          1 => reverse(picks[i % picks.length]),
          2 => listening(picks[i % picks.length]),
          _ => meaning(picks[i % picks.length]),
        },
    ];
  }

  /// "먹다 → past": the right form plus look-alike wrong ones.
  ChoiceExercise? conjugation(Word w, Form form) {
    if (!Conjugator.drillable(w.word, w.formsMap)) return null;
    final c = Conjugator.fromWord(w.word, w.pos, w.formsMap, hanja: w.hanja);
    if (!c.forms.contains(form)) return null;
    final right = c.conjugate(form);
    // The classic mistake of gluing the ending onto the dictionary stem without the vowel
    // rules (가다 → 가어요, 듣다 → 듣었어요), then sibling tenses of the same word.
    // Vowel-final stems are skipped: 주어요 or 되었어요 are uncontracted but still correct.
    final consonantStem = hasBatchim(c.stem) || c.stem.endsWith('하');
    final naive = switch (form) {
      _ when !consonantStem => <String>[],
      Form.present => ['${c.stem}어요', '${c.stem}아요'],
      Form.past => ['${c.stem}었어요', '${c.stem}았어요'],
      Form.future => ['${c.stem}을 거예요'],
      Form.formal => ['${c.stem}습니다', '${c.stem}니다'],
      _ => <String>[],
    }..shuffle(rng);
    // Present and formal present are both "present", so neither is a wrong answer for the other.
    final siblings = [Form.present, Form.past, Form.future, Form.formal, Form.negativeJi, Form.want]
        .where((f) => !(form == Form.present && f == Form.formal) && !(form == Form.formal && f == Form.present))
        .where(c.forms.contains)
        .map(c.conjugate)
        .toList()
      ..shuffle(rng);
    final others = c.forms
        .where((f) => !(form == Form.present && f == Form.formal) && !(form == Form.formal && f == Form.present))
        .map(c.conjugate)
        .toList()
      ..shuffle(rng);
    final wrong = <String>{};
    for (final candidate in [...naive.take(1), ...siblings, ...naive.skip(1), ...others]) {
      if (candidate != right && isHangul(candidate) && !_looseJamo.hasMatch(candidate)) wrong.add(candidate);
      if (wrong.length == 3) break;
    }
    final options = [right, ...wrong.take(3)]..shuffle(rng);
    // Adjectives describe nouns with -(으)ㄴ, not -는 (예쁜 꽃).
    final pattern = form == Form.modPresent && c.isAdjective && !right.endsWith('는') ? '-(으)ㄴ' : form.pattern;
    return ChoiceExercise(
      instruction: 'Conjugate: ${form.label}',
      prompt: w.word,
      subPrompt: '${shortGloss(w)} · $pattern',
      style: PromptStyle.korean,
      options: options,
      answer: options.indexOf(right),
      optionsKorean: true,
      speak: right,
      explanation: '${w.word} → $right',
      wordIds: [w.id],
    );
  }
}
