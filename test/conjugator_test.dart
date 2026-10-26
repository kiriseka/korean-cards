import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:korean_cards/grammar/conjugator.dart';
import 'package:korean_cards/grammar/hangul.dart';

void main() {
  final words = (jsonDecode(File('assets/data/words.json').readAsStringSync())['words'] as List)
      .cast<Map<String, dynamic>>();

  /// The first bundled entry for [word] with the given part of speech, conjugated with its KRDict forms.
  Conjugator bundled(String word, {String pos = 'verb'}) {
    final w = words.firstWhere((w) => w['word'] == word && w['pos'] == pos,
        orElse: () => throw StateError('$word ($pos) not in words.json'));
    return Conjugator.fromWord(word, pos, w['forms'] as Map<String, dynamic>?, hanja: w['hanja'] as String?);
  }

  // word: present, past, future, formal
  const tenses = {
    '가다': ['가요', '갔어요', '갈 거예요', '갑니다'],
    '오다': ['와요', '왔어요', '올 거예요', '옵니다'],
    '보다': ['봐요', '봤어요', '볼 거예요', '봅니다'],
    '마시다': ['마셔요', '마셨어요', '마실 거예요', '마십니다'],
    '먹다': ['먹어요', '먹었어요', '먹을 거예요', '먹습니다'],
    '하다': ['해요', '했어요', '할 거예요', '합니다'],
    '공부하다': ['공부해요', '공부했어요', '공부할 거예요', '공부합니다'],
    '듣다': ['들어요', '들었어요', '들을 거예요', '듣습니다'],
    '살다': ['살아요', '살았어요', '살 거예요', '삽니다'],
    '만들다': ['만들어요', '만들었어요', '만들 거예요', '만듭니다'],
    '모르다': ['몰라요', '몰랐어요', '모를 거예요', '모릅니다'],
    '쓰다': ['써요', '썼어요', '쓸 거예요', '씁니다'],
    '낫다': ['나아요', '나았어요', '나을 거예요', '낫습니다'],
    '되다': ['돼요', '됐어요', '될 거예요', '됩니다'],
    '주다': ['줘요', '줬어요', '줄 거예요', '줍니다'],
    '기다리다': ['기다려요', '기다렸어요', '기다릴 거예요', '기다립니다'],
    '배우다': ['배워요', '배웠어요', '배울 거예요', '배웁니다'],
    '쉬다': ['쉬어요', '쉬었어요', '쉴 거예요', '쉽니다'],
    '모으다': ['모아요', '모았어요', '모을 거예요', '모읍니다'],
    '짓다': ['지어요', '지었어요', '지을 거예요', '짓습니다'],
  };
  const adjTenses = {
    '덥다': ['더워요', '더웠어요', '더울 거예요', '덥습니다'],
    '춥다': ['추워요', '추웠어요', '추울 거예요', '춥습니다'],
    '좋다': ['좋아요', '좋았어요', '좋을 거예요', '좋습니다'],
    '예쁘다': ['예뻐요', '예뻤어요', '예쁠 거예요', '예쁩니다'],
    '있다': ['있어요', '있었어요', '있을 거예요', '있습니다'],
    '없다': ['없어요', '없었어요', '없을 거예요', '없습니다'],
  };

  void checkTenses(Conjugator c, List<String> expected) {
    expect(
      [Form.present, Form.past, Form.future, Form.formal].map(c.conjugate).toList(),
      expected,
      reason: c.dictionary,
    );
  }

  test('verb tenses from KRDict forms', () {
    tenses.forEach((word, expected) => checkTenses(bundled(word), expected));
  });

  test('adjective tenses from KRDict forms', () {
    adjTenses.forEach((word, expected) => checkTenses(bundled(word, pos: 'adjective'), expected));
  });

  test('regular rules match KRDict for words that have forms', () {
    // Without forms the rules must still get regular verbs, 하다, 으 and 르 right.
    const regular = ['가다', '오다', '마시다', '먹다', '공부하다', '배우다', '기다리다', '쓰다', '모르다', '살다', '만들다', '주다'];
    for (final w in regular) {
      checkTenses(Conjugator(w), tenses[w]!);
    }
    checkTenses(Conjugator('예쁘다', isAdjective: true), adjTenses['예쁘다']!);
    checkTenses(Conjugator('좋다', isAdjective: true), adjTenses['좋다']!);
  });

  test('connecting endings and patterns', () {
    final eat = bundled('먹다');
    final listen = bundled('듣다');
    final live = bundled('살다');
    final go = bundled('가다');
    expect(eat.conjugate(Form.and), '먹고');
    expect(eat.conjugate(Form.but), '먹지만');
    expect(eat.conjugate(Form.so), '먹어서');
    expect(listen.conjugate(Form.so), '들어서');
    expect(listen.conjugate(Form.because), '들으니까');
    expect(listen.conjugate(Form.ifWhen), '들으면');
    expect(live.conjugate(Form.ifWhen), '살면');
    expect(go.conjugate(Form.ifWhen), '가면');
    expect(eat.conjugate(Form.want), '먹고 싶어요');
    expect(go.conjugate(Form.please), '가세요');
    expect(live.conjugate(Form.please), '사세요');
    expect(listen.conjugate(Form.please), '들으세요');
    expect(eat.conjugate(Form.canDo), '먹을 수 있어요');
    expect(eat.conjugate(Form.mustDo), '먹어야 해요');
    expect(go.conjugate(Form.shallWe), '갈까요?');
    expect(eat.conjugate(Form.letsDo), '먹읍시다');
    expect(live.conjugate(Form.letsDo), '삽시다');
    expect(go.conjugate(Form.doForMe), '가 주세요');
    expect(eat.conjugate(Form.progressive), '먹고 있어요');
    expect(go.conjugate(Form.negative), '안 가요');
    expect(bundled('공부하다').conjugate(Form.negative), '공부 안 해요');
    expect(bundled('좋아하다').conjugate(Form.negative), '안 좋아해요');
    expect(go.conjugate(Form.negativeJi), '가지 않아요');
    expect(go.conjugate(Form.formalPast), '갔습니다');
  });

  test('noun modifiers -는 / -(으)ㄴ / -(으)ㄹ', () {
    final eat = bundled('먹다');
    final make = bundled('만들다');
    final listen = bundled('듣다');
    expect([Form.modPresent, Form.modPast, Form.modFuture].map(eat.conjugate), ['먹는', '먹은', '먹을']);
    expect([Form.modPresent, Form.modPast, Form.modFuture].map(make.conjugate), ['만드는', '만든', '만들']);
    expect([Form.modPresent, Form.modPast, Form.modFuture].map(listen.conjugate), ['듣는', '들은', '들을']);
    expect(bundled('예쁘다', pos: 'adjective').conjugate(Form.modPresent), '예쁜');
    expect(bundled('춥다', pos: 'adjective').conjugate(Form.modPresent), '추운');
    expect(bundled('있다', pos: 'adjective').conjugate(Form.modPresent), '있는');
    expect(bundled('맛있다', pos: 'adjective').conjugate(Form.modPresent), '맛있는');
  });

  test('every drillable bundled word conjugates to Hangul without throwing', () {
    var count = 0;
    for (final w in words) {
      final word = w['word'] as String;
      final pos = w['pos'] as String;
      if (!(pos == 'verb' || pos == 'adjective')) continue;
      final forms = w['forms'] as Map<String, dynamic>?;
      if (!Conjugator.drillable(word, forms)) continue;
      final c = Conjugator.fromWord(word, pos, forms, hanja: w['hanja'] as String?);
      for (final f in c.forms) {
        final out = c.conjugate(f);
        expect(isHangul(out), isTrue, reason: '$word $f');
        expect(out.contains('다 '), isFalse, reason: '$word $f → $out');
      }
      count++;
    }
    expect(count, greaterThan(600));
  });

  test('particles follow the batchim', () {
    expect(Particles.topic('저'), '저는');
    expect(Particles.topic('책'), '책은');
    expect(Particles.subject('친구'), '친구가');
    expect(Particles.subject('물'), '물이');
    expect(Particles.object('사과'), '사과를');
    expect(Particles.object('밥'), '밥을');
    expect(Particles.and('빵'), '빵과');
    expect(Particles.and('우유'), '우유와');
    expect(Particles.direction('버스'), '버스로');
    expect(Particles.direction('지하철'), '지하철로');
    expect(Particles.direction('손'), '손으로');
    expect(Particles.copula('학생'), '학생이에요');
    expect(Particles.copula('의사'), '의사예요');
  });
}
