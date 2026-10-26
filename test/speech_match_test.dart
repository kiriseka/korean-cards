import 'package:flutter_test/flutter_test.dart';
import 'package:korean_cards/speech/speech_match.dart';

void main() {
  test('exact match ignores spacing and punctuation', () {
    final m = matchSpeech('저는 밥을 먹어요.', '저는밥을 먹어요');
    expect(m.score, 1.0);
    expect(m.passed, isTrue);
    expect(m.syllables.where((s) => s.$1 != ' ' && s.$1 != '.').every((s) => s.$2), isTrue);
  });

  test('one wrong vowel costs little; a missing word costs more', () {
    final close = matchSpeech('감사합니다', '감사함니다');
    expect(close.score, greaterThan(0.85));
    final missing = matchSpeech('저는 학교에 가요', '저는 가요');
    expect(missing.score, lessThan(0.7));
    expect(missing.passed, isFalse);
    // 학교에 marked as missed, 저는 and 가요 as heard.
    final marks = {for (final (c, ok) in missing.syllables) c: ok};
    expect(marks['학'], isFalse);
    expect(marks['저'], isTrue);
    expect(marks['요'], isTrue);
  });

  test('silence or nonsense fails', () {
    expect(matchSpeech('안녕하세요', '').passed, isFalse);
    expect(matchSpeech('안녕하세요', 'hello').score, 0);
  });

  test('digits from the recognizer count as Sino or native numbers', () {
    expect(matchSpeech('세 시에 만나요', '3시에 만나요').passed, isTrue);
    expect(matchSpeech('만 오천 원이에요', '15,000원이에요').score, 1.0);
    expect(matchSpeech('이 층에 있어요', '2층에 있어요').score, 1.0);
    expect(matchSpeech('스무 살이에요', '20살이에요').score, 1.0);
    expect(matchSpeech('사과 하나 주세요', '사과 1 주세요').score, 1.0);
  });

  test('number words', () {
    expect(sinoNumber(15000), '만오천');
    expect(sinoNumber(10000), '만');
    expect(sinoNumber(2026), '이천이십육');
    expect(sinoNumber(110), '백십');
    expect(nativeNumber(3), '셋');
    expect(nativeNumber(3, counter: true), '세');
    expect(nativeNumber(21, counter: true), '스물한');
    expect(nativeNumber(100), isNull);
  });

  test('short words need a closer match than sentences', () {
    expect(matchSpeech('물', '불').passed, isFalse);
    expect(matchSpeech('사과', '사과').passed, isTrue);
  });
}
