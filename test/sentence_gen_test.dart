import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:korean_cards/data/db.dart';
import 'package:korean_cards/grammar/conjugator.dart';
import 'package:korean_cards/grammar/hangul.dart';
import 'package:korean_cards/grammar/sentence_gen.dart';
import 'package:korean_cards/learn/exercises.dart';
import 'package:korean_cards/learn/skills.dart';

import 'content_test.dart' show bundledWords;

void main() {
  final frames = Frames(jsonDecode(File('assets/data/sentence_frames.json').readAsStringSync()) as Map<String, dynamic>);
  final words = bundledWords();
  final looseJamo = RegExp('[ㄱ-ㆎ]');

  test('every frame verb and adjective is a bundled word with conjugation data', () {
    final verbs = {
      for (final key in ['transitive', 'goVerbs', 'placeVerbs']) ...frames.list(key).map((v) => v['verb'] as String),
      frames.likes['verb'] as String,
      ...frames.list('descriptions').map((d) => d['adj'] as String),
    };
    for (final v in verbs) {
      final w = words.where((w) => w.word == v && (w.pos == 'verb' || w.pos == 'adjective')).toList();
      expect(w, isNotEmpty, reason: v);
      expect(w.any((x) => Conjugator.drillable(x.word, x.formsMap)), isTrue, reason: v);
    }
  });

  test('clauses read correctly in both languages', () {
    final gen = SentenceGenerator(frames, words, random: Random(1));
    final past = gen.transitive(Tense.past);
    expect(past.slot('object')!.text, endsWith(particleFor(past.slot('object')!.base, 'object')));
    expect(past.slot('topic')!.particle, anyOf('은', '는'));
    expect(past.en, endsWith('.'));
    final go = gen.goPlace(Tense.future);
    expect(go.slot('to')!.particle, '에');
    expect(go.slot('verb')!.text, contains('거예요'));
    expect(go.en, contains('will'));
    final at = gen.placeAction(Tense.progressive);
    expect(at.slot('at')!.particle, '에서');
    expect(at.slot('verb')!.text, contains('고 있어요'));
    expect(at.en, anyOf(contains(' am '), contains(' is ')));
    final who = gen.whoAnswer(Tense.past);
    expect(who.question, startsWith('누가'));
    expect(who.slot('subject')!.particle, anyOf('이', '가'));
    expect(gen.alsoPair().slot('also')!.particle, '도');
    final bus = gen.byVehicle(Tense.present);
    expect(bus.slot('by')!.particle, anyOf('로', '으로'));
    // 지하철 ends in ㄹ → 로
    expect(particleFor('지하철', 'by'), '로');
    expect(particleFor('손', 'by'), '으로');
  });

  test('every skill generates well-formed exercises', () {
    for (final seed in [1, 2, 3, 4]) {
      final gen = SentenceGenerator(frames, words, random: Random(seed));
      for (final skill in skills.where((s) => s.group != SkillGroup.numbers)) {
        for (var i = 0; i < 40; i++) {
          final ex = gen.forSkill(skill.id, typingOn: true, speakingOn: true);
          expect(ex.skillIds, contains(skill.id), reason: skill.id);
          switch (ex) {
            case ChoiceExercise e:
              expect(e.options.toSet().length, e.options.length, reason: '${skill.id}: ${e.prompt} ${e.options}');
              expect(e.options.length, greaterThanOrEqualTo(2));
              expect(e.answer, inInclusiveRange(0, e.options.length - 1));
              expect(e.prompt, contains('___'), reason: e.prompt);
              for (final o in e.options) {
                expect(looseJamo.hasMatch(o), isFalse, reason: '${skill.id}: $o');
              }
              expect(isHangul(e.speak!), isTrue);
              expect(e.speak!.contains('___'), isFalse);
            case SentenceExercise e:
              expect(e.tiles, containsAll(e.answer));
              expect(e.answer.every(isHangul), isTrue, reason: e.sentence);
            case SpeakExercise e:
              expect(isHangul(e.target), isTrue);
              expect(e.english, isNotEmpty);
            case TypingExercise e:
              expect(isHangul(e.answer), isTrue);
            default:
              fail('unexpected ${ex.runtimeType} for ${skill.id}');
          }
        }
      }
    }
  });

  test('the time word always decides the tense, with no second right answer', () {
    final gen = SentenceGenerator(frames, words, random: Random(9));
    const cues = {
      '어제': Form.past, '지난주에': Form.past, '아까': Form.past,
      '매일': Form.present, '아침마다': Form.present,
      '내일': Form.future, '다음': Form.future, '이따가': Form.future,
      '지금': Form.progressive,
    };
    for (var i = 0; i < 200; i++) {
      final e = gen.tenseFromCue();
      final verb = e.subPrompt!.split(' ').first;
      final cn = gen.conj(verb);
      final cue = e.prompt.split(' ')[1];
      final form = cues[cue]!;
      expect(e.correct, cn.conjugate(form), reason: e.prompt);
      if (form == Form.future || form == Form.progressive) {
        // Korean present also works with 내일/지금, so it must never be offered there.
        expect(e.options, isNot(contains(cn.conjugate(Form.present))), reason: '${e.prompt} ${e.options}');
      }
      if (form == Form.present) expect(e.options, isNot(contains(cn.conjugate(Form.progressive))));
    }
  });
}
