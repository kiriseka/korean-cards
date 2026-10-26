import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../data/db.dart';
import '../learn/exercises.dart';
import 'conjugator.dart';
import 'hangul.dart';

enum Tense {
  present(Form.present),
  past(Form.past),
  future(Form.future),
  progressive(Form.progressive);

  const Tense(this.form);
  final Form form;
}

/// A sentence word with the grammatical role of its particle, so one slot can be blanked.
class Slot {
  const Slot(this.base, {this.particle = '', this.role});
  final String base;
  final String particle;

  /// topic, subject, object, to, at, by, also, verb — or null for words that aren't drilled.
  final String? role;

  String get text => base + particle;
}

class Clause {
  const Clause(this.slots, this.en, {this.question, this.questionEn, this.verb, this.tense});
  final List<Slot> slots;
  final String en;

  /// A who-question the clause answers (for 이/가 practice).
  final String? question;
  final String? questionEn;

  /// Dictionary form of the clause's verb, when it has one.
  final String? verb;
  final Tense? tense;

  String get ko => slots.map((s) => s.text).join(' ');
  Slot? slot(String role) => slots.where((s) => s.role == role).firstOrNull;
}

/// Hand-written building blocks (assets/data/sentence_frames.json).
class Frames {
  Frames(this.raw);
  final Map<String, dynamic> raw;

  static Future<Frames> load([AssetBundle? bundle]) async =>
      Frames(jsonDecode(await (bundle ?? rootBundle).loadString('assets/data/sentence_frames.json')) as Map<String, dynamic>);

  List<Map<String, dynamic>> list(String key) => (raw[key] as List).cast<Map<String, dynamic>>();
  List<Map<String, dynamic>> objects(String kind) => ((raw['objects'] as Map)[kind] as List).cast<Map<String, dynamic>>();
  List<Map<String, dynamic>> times(Tense t) => ((raw['times'] as Map)[t.name] as List).cast<Map<String, dynamic>>();
  Map<String, dynamic> get likes => raw['likes'] as Map<String, dynamic>;
}

/// Particle forms after [noun] for each role.
String particleFor(String noun, String role) => switch (role) {
      'topic' => particle(noun, '은', '는'),
      'subject' => particle(noun, '이', '가'),
      'object' => particle(noun, '을', '를'),
      'to' => '에',
      'at' => '에서',
      'by' => particle(noun, '으로', '로', rieulAsVowel: true),
      'also' => '도',
      _ => '',
    };

/// Particles a learner might confuse with each role (always shown in the right batchim form).
const _confusable = {
  'topic': ['subject', 'object'],
  'subject': ['topic', 'object'],
  'object': ['subject', 'topic', 'to'],
  'to': ['at', 'object'],
  'at': ['to', 'object'],
  'by': ['to', 'at'],
  'also': ['topic', 'subject'],
};

/// Generates particle and tense practice from sentence frames and real conjugations.
class SentenceGenerator {
  SentenceGenerator(this.frames, Iterable<Word> words, {Random? random}) : rng = random ?? Random() {
    for (final w in words) {
      if (!(w.pos == 'verb' || w.pos == 'adjective') || !w.word.endsWith('다')) continue;
      final seen = _words[w.word];
      if (seen == null || w.rank < seen.rank) _words[w.word] = w;
    }
  }

  final Frames frames;
  final Random rng;
  final Map<String, Word> _words = {};

  T _pick<T>(List<T> xs) => xs[rng.nextInt(xs.length)];

  Conjugator conj(String verb) {
    final w = _words[verb];
    return w == null ? Conjugator(verb) : Conjugator.fromWord(verb, w.pos, w.formsMap, hanja: w.hanja);
  }

  Word? word(String verb) => _words[verb];

  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _enVerb(Map<String, dynamic> subj, List en, Tense t, {bool negative = false}) {
    final third = subj['third'] as bool;
    if (negative) return '${third ? "doesn't" : "don't"} ${en[0]}';
    return switch (t) {
      Tense.present => third ? en[1] as String : en[0] as String,
      Tense.past => en[2] as String,
      Tense.future => 'will ${en[0]}',
      Tense.progressive => '${third ? 'is' : 'am'} ${en[3]}',
    };
  }

  String _sentence(Map<String, dynamic> subj, String verb, String rest, Map<String, dynamic>? time) =>
      '${_cap(subj['en'] as String)} $verb${rest.isEmpty ? '' : ' $rest'}${time == null ? '' : ' ${time['en']}'}.';

  Slot _noun(String noun, String role) => Slot(noun, particle: particleFor(noun, role), role: role);

  String _verbForm(String verb, Tense t, {bool negative = false}) {
    final c = conj(verb);
    return negative ? c.conjugate(Form.negative) : c.conjugate(t.form);
  }

  // ---- Clauses ----------------------------------------------------------------------

  /// 저는 어제 빵을 먹었어요. — I ate bread yesterday.
  Clause transitive(Tense t, {bool negative = false}) {
    final subj = _pick(frames.list('subjects'));
    final verb = _pick(frames.list('transitive'));
    final obj = _pick(frames.objects(_pick((verb['objects'] as List).cast<String>())));
    final time = negative ? null : _pick(frames.times(t));
    final v = verb['verb'] as String;
    return Clause(
      [
        _noun(subj['ko'] as String, 'topic'),
        if (time != null) Slot(time['ko'] as String),
        _noun(obj['ko'] as String, 'object'),
        Slot('${_verbForm(v, t, negative: negative)}.', role: 'verb'),
      ],
      _sentence(subj, _enVerb(subj, verb['en'] as List, t, negative: negative), obj['en'] as String, time),
      verb: v,
      tense: t,
    );
  }

  /// 친구는 내일 학교에 갈 거예요.
  Clause goPlace(Tense t) {
    final subj = _pick(frames.list('subjects'));
    final verb = _pick(frames.list('goVerbs'));
    final place = _pick(frames.list('places'));
    final time = _pick(frames.times(t));
    final v = verb['verb'] as String;
    return Clause(
      [
        _noun(subj['ko'] as String, 'topic'),
        Slot(time['ko'] as String),
        _noun(place['ko'] as String, 'to'),
        Slot('${_verbForm(v, t)}.', role: 'verb'),
      ],
      _sentence(subj, _enVerb(subj, verb['en'] as List, t), place['to'] as String, time),
      verb: v,
      tense: t,
    );
  }

  /// 저는 매일 도서관에서 공부해요.
  Clause placeAction(Tense t) {
    final subj = _pick(frames.list('subjects'));
    final verb = _pick(frames.list('placeVerbs'));
    final placeName = _pick((verb['places'] as List).cast<String>());
    final place = frames.list('places').firstWhere((p) => p['ko'] == placeName);
    final time = _pick(frames.times(t));
    final v = verb['verb'] as String;
    return Clause(
      [
        _noun(subj['ko'] as String, 'topic'),
        Slot(time['ko'] as String),
        _noun(placeName, 'at'),
        Slot('${_verbForm(v, t)}.', role: 'verb'),
      ],
      _sentence(subj, _enVerb(subj, verb['en'] as List, t), place['at'] as String, time),
      verb: v,
      tense: t,
    );
  }

  /// 저는 매일 학교에 버스로 가요.
  Clause byVehicle(Tense t) {
    final subj = _pick(frames.list('subjects'));
    final place = _pick(frames.list('places'));
    final vehicle = _pick(frames.list('vehicles'));
    final time = _pick(frames.times(t));
    const go = ['go', 'goes', 'went', 'going'];
    return Clause(
      [
        _noun(subj['ko'] as String, 'topic'),
        Slot(time['ko'] as String),
        _noun(place['ko'] as String, 'to'),
        _noun(vehicle['ko'] as String, 'by'),
        Slot('${_verbForm('가다', t)}.', role: 'verb'),
      ],
      _sentence(subj, _enVerb(subj, go, t), '${place['to']} ${vehicle['en']}', time),
      verb: '가다',
      tense: t,
    );
  }

  /// 저는 학생이에요.
  Clause identity() {
    final subj = _pick(frames.list('subjects'));
    final job = _pick(frames.list('jobs'));
    final be = subj['third'] as bool ? 'is' : 'am';
    return Clause(
      [_noun(subj['ko'] as String, 'topic'), Slot('${Particles.copula(job['ko'] as String)}.')],
      'Introducing: ${subj['en']} $be ${job['en']}.',
    );
  }

  /// 커피는 좋아해요. 우유는 안 좋아해요. — contrast with 은/는.
  Clause contrast() {
    final kind = _pick((frames.likes['objects'] as List).cast<String>());
    final objs = [...frames.objects(kind)]..shuffle(rng);
    final a = objs[0], b = objs[1];
    return Clause(
      [_noun(a['ko'] as String, 'topic'), Slot('좋아해요.'), Slot(b['ko'] as String, particle: particleFor(b['ko'] as String, 'topic')), Slot('안 좋아해요.')],
      "I like ${a['en']}, but I don't like ${b['en']}.",
    );
  }

  /// 저는 커피를 좋아해요. 친구도 커피를 좋아해요.
  Clause alsoPair() {
    final kind = _pick((frames.likes['objects'] as List).cast<String>());
    final obj = _pick(frames.objects(kind));
    final other = _pick(frames.list('subjects').where((s) => s['ko'] != '저').toList());
    final o = obj['ko'] as String;
    return Clause(
      [
        Slot('저는'),
        Slot(o, particle: particleFor(o, 'object')),
        Slot('좋아해요.'),
        _noun(other['ko'] as String, 'also'),
        Slot(o, particle: particleFor(o, 'object')),
        Slot('좋아해요.'),
      ],
      'I like ${obj['en']}. ${_cap(other['en'] as String)} likes ${obj['en']} too.',
    );
  }

  /// 누가 빵을 먹었어요? → 친구가 빵을 먹었어요.
  Clause whoAnswer(Tense t) {
    final subj = _pick(frames.list('subjects').where((s) => s['ko'] != '저').toList());
    final verb = _pick(frames.list('transitive'));
    final obj = _pick(frames.objects(_pick((verb['objects'] as List).cast<String>())));
    final v = verb['verb'] as String;
    final form = _verbForm(v, t);
    final o = obj['ko'] as String;
    final whoEn = switch (t) {
      Tense.present => '${(verb['en'] as List)[1]}',
      Tense.past => '${(verb['en'] as List)[2]}',
      Tense.future => 'will ${(verb['en'] as List)[0]}',
      Tense.progressive => 'is ${(verb['en'] as List)[3]}',
    };
    return Clause(
      [_noun(subj['ko'] as String, 'subject'), Slot(o, particle: particleFor(o, 'object')), Slot('$form.', role: 'verb')],
      _sentence(subj, _enVerb(subj, verb['en'] as List, t), obj['en'] as String, null),
      question: '누가 $o${particleFor(o, 'object')} $form?',
      questionEn: 'Who $whoEn ${obj['en']}?',
      verb: v,
      tense: t,
    );
  }

  /// 저는 시간이 있어요. / 날씨가 좋아요.
  Clause existence() {
    if (rng.nextBool()) {
      final thing = _pick(frames.list('have'));
      final has = rng.nextBool();
      return Clause(
        [Slot('저는'), _noun(thing['ko'] as String, 'subject'), Slot(has ? '있어요.' : '없어요.')],
        has ? 'I have ${thing['en']}.' : "I don't have ${thing['en']}.",
      );
    }
    final d = _pick(frames.list('descriptions'));
    return Clause([_noun(d['ko'] as String, 'subject'), Slot('${conj(d['adj'] as String).conjugate(Form.present)}.')], d['en'] as String);
  }

  // ---- Exercises ----------------------------------------------------------------------

  static const _reasons = {
    'topic': '은/는 marks the topic: what you\'re talking about (introducing yourself, or contrasting things).',
    'subject': '이/가 marks the subject: the new information — who did it, or what exists / is described.',
    'object': '을/를 marks the object: the thing that gets eaten, watched, bought…',
    'to': '에: going or coming TO a place (also: at a time).',
    'at': '에서: the place where you DO something.',
    'by': '(으)로: by a means — 로 after a vowel or ㄹ, 으로 after other consonants.',
    'also': '도 means "too / also" and replaces 은/는 or 이/가.',
  };

  /// Pick the particle for one blanked slot.
  ChoiceExercise particleChoice(Clause c, String role, String skillId) {
    final target = c.slot(role)!;
    final right = target.particle;
    final options = <String>{right};
    // 질문은 없어요 is natural too, so 은/는 is only a wrong answer when the sentence answers 누가.
    final confusable = role == 'subject' && c.question == null ? const ['object', 'to'] : _confusable[role]!;
    for (final r in confusable) {
      options.add(particleFor(target.base, r));
    }
    options.remove('');
    final list = options.toList()..shuffle(rng);
    final blanked = c.slots.map((s) => identical(s, target) ? '${s.base}___' : s.text).join(' ');
    final ends = hasBatchim(target.base) ? 'ends in a consonant' : 'ends in a vowel';
    return ChoiceExercise(
      instruction: 'Pick the particle',
      prompt: c.question == null ? blanked : '${c.question}\n→ $blanked',
      subPrompt: c.questionEn == null ? c.en : '${c.questionEn} → ${c.en}',
      style: PromptStyle.sentence,
      options: list,
      answer: list.indexOf(right),
      optionsKorean: true,
      speak: c.ko,
      explanation: '${_reasons[role]} ${target.base} $ends → ${target.text}.',
      skillIds: [skillId],
    );
  }

  /// Just the batchim rule: 책 ___ → 은 / 는.
  ChoiceExercise particleForm(String role, String skillId) {
    final nouns = [
      ...frames.objects('food'),
      ...frames.objects('drinks'),
      ...frames.objects('reading'),
      ...frames.list('places'),
      ...frames.list('vehicles'),
    ].map((m) => m['ko'] as String).toList();
    final noun = _pick(nouns);
    final (a, b) = switch (role) {
      'topic' => ('은', '는'),
      'subject' => ('이', '가'),
      'by' => ('으로', '로'),
      _ => ('을', '를'),
    };
    final right = particleFor(noun, role == 'by' ? 'by' : role);
    final options = [a, b]..shuffle(rng);
    return ChoiceExercise(
      instruction: 'Pick the right form',
      prompt: '$noun ___',
      subPrompt: const {'topic': 'topic marker', 'subject': 'subject marker', 'object': 'object marker', 'by': 'by (bus, hand…)'}[role],
      style: PromptStyle.sentence,
      options: options,
      answer: options.indexOf(right),
      optionsKorean: true,
      speak: noun + right,
      explanation: '$noun ${hasBatchim(noun) ? (role == 'by' && lastSyllable(noun)!.finalC == F.l ? 'ends in ㄹ' : 'ends in a consonant') : 'ends in a vowel'} → $noun$right',
      skillIds: [skillId],
    );
  }

  /// Fill in the verb in a given tense; wrong options are look-alike mistakes and other tenses.
  ChoiceExercise? tenseForm(Clause c, Form form, String skillId) {
    final w = word(c.verb!);
    if (w == null) return null;
    final base = ExerciseGenerator(pool: const [], random: rng).conjugation(w, form);
    if (base == null) return null;
    final verbSlot = c.slot('verb')!;
    final blanked = c.slots.map((s) => identical(s, verbSlot) ? '___.' : s.text).join(' ');
    return ChoiceExercise(
      instruction: '${form.label}: fill in the verb',
      prompt: blanked,
      subPrompt: '${c.verb} · ${c.en}',
      style: PromptStyle.sentence,
      options: base.options,
      answer: base.answer,
      optionsKorean: true,
      speak: c.slots.map((s) => identical(s, verbSlot) ? '${base.correct}.' : s.text).join(' '),
      explanation: '${c.verb} → ${base.correct} (${form.pattern})',
      skillIds: [skillId],
    );
  }

  /// The time word decides the tense: 어제 → past, 내일 → future, 지금 → right now.
  ChoiceExercise tenseFromCue() {
    final t = _pick(Tense.values);
    final c = rng.nextBool() ? transitive(t) : goPlace(t);
    final cn = conj(c.verb!);
    final allowed = switch (t) {
      Tense.future => [Tense.future, Tense.past, Tense.progressive],
      Tense.past => [Tense.past, Tense.present, Tense.future, Tense.progressive],
      Tense.present => [Tense.present, Tense.past, Tense.future],
      Tense.progressive => [Tense.progressive, Tense.past, Tense.future],
    };
    final options = [for (final o in allowed) cn.conjugate(o.form)]..shuffle(rng);
    final right = cn.conjugate(t.form);
    final verbSlot = c.slot('verb')!;
    final time = c.slots[1].base;
    final enVerb = _verbEnglish(c.verb!);
    return ChoiceExercise(
      instruction: 'Which tense fits the time word?',
      prompt: c.slots.map((s) => identical(s, verbSlot) ? '___.' : s.text).join(' '),
      subPrompt: '${c.verb}${enVerb == null ? '' : ' · $enVerb'}',
      style: PromptStyle.sentence,
      options: options,
      answer: options.indexOf(right),
      optionsKorean: true,
      speak: c.ko,
      explanation: '$time → ${t.form.label.toLowerCase()}: $right',
      skillIds: const ['t_context'],
    );
  }

  String? _verbEnglish(String verb) {
    for (final v in [...frames.list('transitive'), ...frames.list('goVerbs'), ...frames.list('placeVerbs')]) {
      if (v['verb'] == verb) return 'to ${(v['en'] as List)[0]}';
    }
    return null;
  }

  /// "I don't eat bread": 안 먹어요 or 먹지 않아요 — not 못 (can't) or the past.
  ChoiceExercise negativeChoice() {
    final c = transitive(Tense.present, negative: true);
    final cn = conj(c.verb!);
    final useAn = rng.nextBool();
    final right = useAn ? cn.conjugate(Form.negative) : cn.conjugate(Form.negativeJi);
    final present = cn.conjugate(Form.present);
    final mot = cn.conjugate(Form.negative).replaceFirst('안 ', '못 ');
    final pastNeg = cn.conjugate(Form.negativeJi).replaceFirst('않아요', '않았어요');
    final options = <String>{right, mot, present, pastNeg}.toList()..shuffle(rng);
    final verbSlot = c.slot('verb')!;
    return ChoiceExercise(
      instruction: 'Say it in the negative',
      prompt: c.slots.map((s) => identical(s, verbSlot) ? '___.' : s.text).join(' '),
      subPrompt: '${c.verb} · ${c.en}',
      style: PromptStyle.sentence,
      options: options,
      answer: options.indexOf(right),
      optionsKorean: true,
      speak: c.slots.map((s) => identical(s, verbSlot) ? '$right.' : s.text).join(' '),
      explanation: "Don't = 안 + verb, or verb stem + 지 않아요. 못 means can't.",
      skillIds: const ['t_negative'],
    );
  }

  /// Build the whole sentence; decoys carry the wrong particle or tense.
  SentenceExercise build(Clause c, String skillId, {String? role}) {
    final answer = c.ko.split(' ');
    final decoys = <String>{};
    final target = role == null ? null : c.slot(role);
    if (target != null) {
      for (final r in _confusable[role]!) {
        final wrong = target.base + particleFor(target.base, r);
        if (!answer.contains(wrong)) decoys.add(wrong);
        if (decoys.isNotEmpty) break;
      }
    }
    if (c.verb != null && c.tense != null) {
      final other = Tense.values.where((t) => t != c.tense).toList()..shuffle(rng);
      final wrong = '${conj(c.verb!).conjugate(other.first.form)}.';
      if (!answer.contains(wrong)) decoys.add(wrong);
    }
    return SentenceExercise(
      english: c.questionEn == null ? c.en : '${c.questionEn} → ${c.en}',
      answer: answer,
      tiles: [...answer, ...decoys]..shuffle(rng),
      skillIds: [skillId],
    );
  }

  TypingExercise? typeVerb(Clause c, Form form, String skillId) {
    final verbSlot = c.slot('verb');
    if (verbSlot == null) return null;
    final answer = verbSlot.text.replaceAll('.', '');
    return TypingExercise(
      prompt: '${c.slots.map((s) => identical(s, verbSlot) ? '___' : s.text).join(' ')}\n${c.verb} · ${c.en}',
      answer: answer,
      hint: form.pattern,
      skillIds: [skillId],
    );
  }

  SpeakExercise speak(Clause c, String skillId) =>
      SpeakExercise(target: c.ko, mode: SpeakMode.sayIt, english: c.en, skillIds: [skillId]);

  /// The clause each particle skill is practised in.
  Clause clauseFor(String skillId) => switch (skillId) {
        'p_topic' => rng.nextInt(3) < 2 ? identity() : contrast(),
        'p_subject' => rng.nextBool() ? whoAnswer(_pick(Tense.values)) : existence(),
        'p_object' => transitive(_pick(Tense.values)),
        'p_also' => alsoPair(),
        'p_to' => goPlace(_pick(Tense.values)),
        'p_at' => placeAction(_pick(Tense.values)),
        'p_by' => byVehicle(_pick(Tense.values)),
        _ => transitive(Tense.present),
      };

  static const _roles = {
    'p_topic': 'topic',
    'p_subject': 'subject',
    'p_object': 'object',
    'p_also': 'also',
    'p_to': 'to',
    'p_at': 'at',
    'p_by': 'by',
  };

  static const _tenseForms = {
    't_present': (Tense.present, Form.present),
    't_past': (Tense.past, Form.past),
    't_future': (Tense.future, Form.future),
    't_progressive': (Tense.progressive, Form.progressive),
    't_formal': (Tense.present, Form.formal),
  };

  /// One exercise for a particle or tense skill, in a varied format.
  Exercise forSkill(String skillId, {bool typingOn = false, bool speakingOn = false}) {
    final role = _roles[skillId];
    final roll = rng.nextInt(10);
    if (role != null) {
      final c = clauseFor(skillId);
      if (roll < 2 && const {'topic', 'subject', 'object', 'by'}.contains(role)) return particleForm(role, skillId);
      if (roll < 4) return build(c, skillId, role: role);
      if (roll < 5 && speakingOn) return speak(c, skillId);
      return particleChoice(c, role, skillId);
    }
    if (skillId == 't_context') return tenseFromCue();
    if (skillId == 't_negative') {
      if (roll < 2 && speakingOn) return speak(transitive(Tense.present, negative: true), skillId);
      return negativeChoice();
    }
    final (tense, form) = _tenseForms[skillId] ?? (Tense.present, Form.present);
    final c = rng.nextBool() ? transitive(tense) : (rng.nextBool() ? goPlace(tense) : placeAction(tense));
    if (form == Form.formal) {
      return tenseForm(c, form, skillId) ?? build(c, skillId);
    }
    if (roll < 2) return build(c, skillId);
    if (roll < 4 && typingOn) return typeVerb(c, form, skillId) ?? build(c, skillId);
    if (roll < 5 && speakingOn) return speak(c, skillId);
    return tenseForm(c, form, skillId) ?? build(c, skillId);
  }
}
