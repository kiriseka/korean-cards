import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:korean_cards/learn/exercises.dart';
import 'package:korean_cards/learn/numbers.dart';
import 'package:korean_cards/learn/skills.dart';
import 'package:korean_cards/speech/speech_match.dart';

void main() {
  test('Sino numbers are spaced every 만', () {
    expect(sinoSpaced(27), '이십칠');
    expect(sinoSpaced(3500), '삼천오백');
    expect(sinoSpaced(10000), '만');
    expect(sinoSpaced(15000), '만 오천');
    expect(sinoSpaced(123400), '십이만 삼천사백');
    expect(sinoSpaced(1000000), '백만');
  });

  test('months, ages and counters', () {
    expect(monthName(6), '유월');
    expect(monthName(10), '시월');
    expect(monthName(11), '십일월');
    expect(counted(1, '개'), '한 개');
    expect(counted(4, '잔'), '네 잔');
    expect(counted(20, '살'), '스무 살');
    expect(counted(25, '살'), '스물다섯 살');
    expect(counted(100, '개'), '백 개');
  });

  test('speaking a price with digits still matches', () {
    expect(matchSpeech('만 오천 원', '15,000원').passed, isTrue);
    expect(matchSpeech('세 시 삼십 분', '3시 30분').passed, isTrue);
  });

  test('every number skill makes valid exercises at every level', () {
    for (final seed in [1, 2, 3]) {
      final t = NumbersTrainer(random: Random(seed));
      for (final s in skills.where((s) => s.group == SkillGroup.numbers)) {
        for (final mastery in [0.0, 0.5, 0.9]) {
          for (var i = 0; i < 30; i++) {
            final e = t.forSkill(s.id, mastery: mastery, speakingOn: true);
            expect(e.skillIds, [s.id]);
            if (e is ChoiceExercise) {
              expect(e.options.toSet().length, e.options.length, reason: '${s.id}: ${e.prompt} ${e.options}');
              expect(e.options.length, greaterThanOrEqualTo(2), reason: '${s.id}: ${e.prompt}');
              expect(e.answer, inInclusiveRange(0, e.options.length - 1));
            } else {
              expect(e, isA<SpeakExercise>());
            }
          }
        }
      }
    }
  });
}
