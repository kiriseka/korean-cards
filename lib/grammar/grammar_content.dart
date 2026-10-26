import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../data/db.dart';
import '../learn/exercises.dart';
import 'conjugator.dart';
import 'hangul.dart';

class GrammarExample {
  const GrammarExample(this.ko, this.en);
  final String ko;
  final String en;
}

class LearnCard {
  const LearnCard({required this.title, this.body, this.formula = const [], this.table = const [], this.examples = const []});
  final String title;

  /// Text with **bold** and *italic* spans.
  final String? body;

  /// Chips like "먹|stem".
  final List<String> formula;
  final List<List<String>> table;
  final List<GrammarExample> examples;

  factory LearnCard.fromJson(Map<String, dynamic> j) => LearnCard(
        title: j['title'] as String,
        body: j['body'] as String?,
        formula: ((j['formula'] as List?) ?? const []).cast<String>(),
        table: [for (final row in (j['table'] as List?) ?? const []) (row as List).cast<String>()],
        examples: [
          for (final e in (j['examples'] as List?) ?? const [])
            GrammarExample((e as Map)['ko'] as String, e['en'] as String),
        ],
      );
}

class GrammarLesson {
  const GrammarLesson({
    required this.id,
    required this.unitId,
    required this.index,
    required this.title,
    required this.subtitle,
    required this.cards,
    required this.practice,
    required this.drills,
  });

  final String id;
  final String unitId;
  final int index;
  final String title;
  final String subtitle;
  final List<LearnCard> cards;
  final List<Map<String, dynamic>> practice;
  final List<Map<String, dynamic>> drills;

  String get progressId => 'grammar:$id';

  /// The hand-written sentence-builder items (also used by the Sentence Builder game).
  Iterable<Map<String, dynamic>> get buildItems => practice.where((p) => p['type'] == 'build');
}

class GrammarUnit {
  const GrammarUnit({required this.id, required this.title, required this.titleKo, required this.emoji, required this.lessons});
  final String id;
  final String title;
  final String titleKo;
  final String emoji;
  final List<GrammarLesson> lessons;
}

List<GrammarUnit> parseGrammar(String raw) {
  final units = (jsonDecode(raw)['units'] as List).cast<Map<String, dynamic>>();
  return [
    for (final u in units)
      GrammarUnit(
        id: u['id'] as String,
        title: u['title'] as String,
        titleKo: u['titleKo'] as String,
        emoji: u['emoji'] as String,
        lessons: [
          for (final (i, l) in (u['lessons'] as List).cast<Map<String, dynamic>>().indexed)
            GrammarLesson(
              id: l['id'] as String,
              unitId: u['id'] as String,
              index: i,
              title: l['title'] as String,
              subtitle: l['subtitle'] as String,
              cards: [for (final c in l['cards'] as List) LearnCard.fromJson(c as Map<String, dynamic>)],
              practice: ((l['practice'] as List?) ?? const []).cast<Map<String, dynamic>>(),
              drills: ((l['drills'] as List?) ?? const []).cast<Map<String, dynamic>>(),
            ),
        ],
      ),
  ];
}

Future<List<GrammarUnit>> loadGrammar([AssetBundle? bundle]) async =>
    parseGrammar(await (bundle ?? rootBundle).loadString('assets/data/grammar.json'));

/// Builds a grammar lesson's practice: the written items plus generated drills.
class GrammarExerciseBuilder {
  GrammarExerciseBuilder({required this.words, this.learned = const {}, Random? random}) : rng = random ?? Random();

  final List<Word> words;

  /// Word ids the user has studied; drills prefer them.
  final Set<int> learned;
  final Random rng;

  /// Hand-written item → exercise. The first listed option is the right one.
  Exercise fromItem(Map<String, dynamic> item) {
    final type = item['type'] as String;
    if (type == 'build') {
      final answer = (item['ko'] as String).split(' ');
      final extra = ((item['extra'] as List?) ?? const []).cast<String>();
      return SentenceExercise(
        english: item['en'] as String,
        answer: answer,
        tiles: [...answer, ...extra]..shuffle(rng),
        explanation: item['explain'] as String?,
      );
    }
    final options = (item['options'] as List).cast<String>();
    final shuffled = [...options]..shuffle(rng);
    final answer = shuffled.indexOf(options.first);
    return switch (type) {
      'choice' => ChoiceExercise(
          instruction: 'Fill in the blank',
          prompt: item['q'] as String,
          subPrompt: item['en'] as String?,
          style: PromptStyle.sentence,
          options: shuffled,
          answer: answer,
          optionsKorean: true,
          speak: (item['q'] as String).replaceAll('___', options.first),
          explanation: item['explain'] as String?,
        ),
      'meaning' => ChoiceExercise(
          instruction: 'What does this mean?',
          prompt: item['ko'] as String,
          style: PromptStyle.korean,
          options: shuffled,
          answer: answer,
          speak: item['ko'] as String,
          explanation: item['explain'] as String?,
        ),
      _ => ChoiceExercise(
          instruction: 'Quick check',
          prompt: item['q'] as String,
          style: PromptStyle.english,
          options: shuffled,
          answer: answer,
          optionsKorean: options.any(isHangul),
          explanation: item['explain'] as String?,
        ),
    };
  }

  List<Word> _candidates(bool Function(Word) test, int count) {
    // One entry per spelling, the most common sense (듣다 "listen", not 듣다 "drip").
    final bySpelling = <String, Word>{};
    for (final w in words) {
      final seen = bySpelling[w.word];
      if (seen == null || w.rank < seen.rank) bySpelling[w.word] = w;
    }
    final all = bySpelling.values.where(test).toList()..shuffle(rng);
    // Prefer words already studied, then the most common ones.
    all.sort((a, b) {
      final la = learned.contains(a.id) ? 0 : 1, lb = learned.contains(b.id) ? 0 : 1;
      if (la != lb) return la - lb;
      return a.rank.compareTo(b.rank);
    });
    final top = all.take(max(count * 4, 12)).toList()..shuffle(rng);
    return top.take(count).toList();
  }

  bool _isIrregular(Word w) {
    final forms = w.formsMap;
    if (forms == null) return false;
    final adjective = w.pos == 'adjective';
    final rules = Conjugator(w.word, isAdjective: adjective);
    final real = Conjugator.fromWord(w.word, w.pos, forms, hanja: w.hanja);
    return rules.conjugate(Form.present) != real.conjugate(Form.present) ||
        rules.conjugate(Form.future) != real.conjugate(Form.future);
  }

  List<Exercise> drill(Map<String, dynamic> spec) {
    final count = spec['count'] as int? ?? 3;
    final particle = spec['particle'] as String?;
    if (particle != null) return _particleDrill(particle, count);

    final forms = [for (final f in spec['forms'] as List) Form.values.byName(f as String)];
    final pos = spec['pos'] as String?;
    final hada = spec['hada'] == true;
    final irregular = spec['irregular'] == true;
    final picks = _candidates((w) {
      if (!(w.pos == 'verb' || w.pos == 'adjective')) return false;
      if (pos != null && w.pos != pos) return false;
      if (!Conjugator.drillable(w.word, w.formsMap)) return false;
      if (hada && !w.word.endsWith('하다')) return false;
      if (irregular && !_isIrregular(w)) return false;
      return true;
    }, count * 2);
    final gen = ExerciseGenerator(pool: words, random: rng);
    final out = <Exercise>[];
    for (final (i, w) in picks.indexed) {
      final ex = gen.conjugation(w, forms[i % forms.length]);
      if (ex != null) out.add(ex);
      if (out.length == count) break;
    }
    return out;
  }

  List<Exercise> _particleDrill(String kind, int count) {
    final (consonant, vowel, label, rieul) = switch (kind) {
      'topic' => ('은', '는', 'topic', false),
      'subject' => ('이', '가', 'subject', false),
      'object' => ('을', '를', 'object', false),
      'and' => ('과', '와', 'and', false),
      'direction' => ('으로', '로', 'by / toward', true),
      _ => ('이에요', '예요', 'is', false),
    };
    final nouns = _candidates(
      (w) => w.pos == 'noun' && w.word.length >= 2 && w.word.length <= 3 && w.word.split('').every((c) => syllableOf(c) != null),
      count,
    );
    return [
      for (final n in nouns)
        () {
          final right = particle(n.word, consonant, vowel, rieulAsVowel: rieul);
          final options = [consonant, vowel]..shuffle(rng);
          final ends = hasBatchim(n.word)
              ? (rieul && lastSyllable(n.word)!.finalC == F.l ? 'ㄹ' : 'a consonant')
              : 'a vowel';
          return ChoiceExercise(
            instruction: 'Pick the $label particle',
            prompt: '${n.word} ___',
            subPrompt: shortGloss(n),
            style: PromptStyle.sentence,
            options: options,
            answer: options.indexOf(right),
            optionsKorean: true,
            speak: n.word + right,
            explanation: '${n.word} ends in $ends → ${n.word}$right',
            wordIds: [n.id],
          );
        }(),
    ];
  }

  /// Written items first in order, drills mixed in after the first two.
  List<Exercise> lessonPractice(GrammarLesson lesson, {required bool typingOn, bool speakingOn = false}) {
    final written = [for (final item in lesson.practice) fromItem(item)];
    final drills = [for (final d in lesson.drills) ...drill(d)]..shuffle(rng);
    final out = [...written.take(2), ...drills, ...written.skip(2)];
    if (speakingOn) {
      // Repeat one of the lesson's own example sentences out loud.
      final examples = [for (final c in lesson.cards) ...c.examples].where((e) => e.ko.length <= 30).toList();
      if (examples.isNotEmpty) {
        final e = examples[rng.nextInt(examples.length)];
        out.insert(min(3, out.length), SpeakExercise(target: e.ko, mode: SpeakMode.shadow, english: e.en));
      }
    }
    if (typingOn) {
      // One typed conjugation for tense-style lessons keeps the keyboard in play.
      final conj = drills.whereType<ChoiceExercise>().where((e) => e.instruction.startsWith('Conjugate')).firstOrNull;
      if (conj != null) {
        out.add(TypingExercise(
          prompt: '${conj.prompt} → ${conj.instruction.replaceFirst('Conjugate: ', '')}',
          answer: conj.correct,
          hint: conj.subPrompt,
          wordIds: conj.wordIds,
        ));
      }
    }
    return out;
  }
}
