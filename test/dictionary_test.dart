import 'package:flutter_test/flutter_test.dart';
import 'package:korean_cards/dictionary/dictionary_service.dart';
import 'package:korean_cards/dictionary/lemmatizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lemma candidates undo particles and conjugation', () {
    expect(lemmaCandidates('먹었어요'), contains('먹다'));
    expect(lemmaCandidates('갔어요'), contains('가다'));
    expect(lemmaCandidates('봤어요'), contains('보다'));
    expect(lemmaCandidates('마셨어요'), contains('마시다'));
    expect(lemmaCandidates('학교에서'), contains('학교'));
    expect(lemmaCandidates('친구한테'), contains('친구'));
    expect(lemmaCandidates('공부했어요'), containsAll(['공부하다', '공부']));
    expect(lemmaCandidates('갈'), contains('가다'));
    expect(lemmaCandidates('만든'), contains('만들다'));
    expect(lemmaCandidates('사는'), contains('살다'));
    expect(lemmaCandidates('갑니다'), contains('가다'));
    expect(lemmaCandidates('들었어요', formIndex: {'들어': ['들다', '듣다']}), contains('듣다'));
    expect(lemmaCandidates('추워요', formIndex: {'추워': ['춥다']}), contains('춥다'));
    expect(tokenize('어제 친구를 만났어요! OK?'), ['어제', '친구를', '만났어요']);
  });

  test('the bundled dictionary loads, looks up real text and adds words', () async {
    SharedPreferences.setMockInitialValues({});
    final db = memoryDb();
    final dict = DictionaryService(db, await SharedPreferences.getInstance());
    expect(await dict.ready, isFalse);
    await dict.ensureLoaded();
    expect(await dict.ready, isTrue);
    expect((await db.select(db.dictionary).get()).length, greaterThan(50000));

    Future<List<String>> words(String token) async => (await dict.lookup(token)).map((e) => e.word).toList();
    expect((await words('먹었어요')).first, '먹다');
    expect(await words('들었어요'), contains('듣다'));
    expect(await words('추웠어요'), contains('춥다'));
    expect(await words('학교에서'), contains('학교'));
    expect(await words('갈'), contains('가다'));

    final apple = await dict.search('apple');
    expect(apple.map((e) => e.word), contains('사과'));
    final korean = await dict.search('사과');
    expect(korean.first.word, '사과');

    final entry = korean.first;
    expect(await dict.addToDeck(entry), isTrue);
    expect(await dict.addToDeck(entry), isFalse);
    final added = await (db.select(db.words)..where((w) => w.id.equals(entry.id))).getSingle();
    expect(added.isCustom, isTrue);
    expect(await db.select(db.cards).get(), hasLength(2));
    await db.close();
  }, timeout: const Timeout(Duration(minutes: 3)));
}
