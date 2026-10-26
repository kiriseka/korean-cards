import '../grammar/hangul.dart';

/// Particles that stick to nouns, longest first so 에서 wins over 에.
const _particles = [
  '에게서', '한테서', '에서는', '에서도', '에게는', '으로는', '이랑은',
  '에서', '에게', '한테', '으로', '부터', '까지', '처럼', '보다', '하고', '이랑', '이나', '께서', '마다', '밖에',
  '은', '는', '이', '가', '을', '를', '에', '도', '의', '로', '와', '과', '랑', '만', '요', '나',
];

/// Verb/adjective endings, longest first. Removing one leaves a stem (or a contracted 아/어 form).
const _endings = [
  '었습니다', '았습니다', '였습니다', '했습니다', '습니다', '니다',
  '었어요', '았어요', '였어요', '했어요', '셨어요', '으세요', '세요', '어요', '아요', '해요', '여요',
  '었어', '았어', '했어', '었다', '았다', '했다', '는데', '은데', '지만', '니까', '으니까', '으면', '면서',
  '어서', '아서', '해서', '고요', '네요', '군요', '죠', '지요', '어', '아', '해', '고', '면', '서', '게', '지', '기', '는', '은', '을', '다', '요',
];

/// Dictionary forms a word in running text could come from, most likely first.
///
/// 먹었어요 → 먹다; 갔어요 → 가다; 들었어요 → 듣다 (through [formIndex], KRDict's 아/어 and 으니
/// forms); 학교에서 → 학교; 공부했어요 → 공부하다, 공부; 갈 → 가다 / 갈다; 만든 → 만들다.
List<String> lemmaCandidates(String token, {Map<String, List<String>> formIndex = const {}}) {
  final t = token.replaceAll(RegExp(r'[^가-힣]'), '');
  if (t.isEmpty) return const [];
  final out = <String>[];
  void add(String s) {
    if (s.isNotEmpty && !out.contains(s)) out.add(s);
  }

  add(t);
  // Nouns: strip a particle.
  for (final p in _particles) {
    if (t.length > p.length && t.endsWith(p)) add(t.substring(0, t.length - p.length));
  }
  // Verbs: strip an ending, then undo the ways stems change.
  final stems = <String>[t];
  for (final e in _endings) {
    if (t.length > e.length && t.endsWith(e)) stems.add(t.substring(0, t.length - e.length));
  }
  for (final s in stems) {
    _verbCandidates(s, formIndex, add);
  }
  return out;
}

void _verbCandidates(String stem, Map<String, List<String>> formIndex, void Function(String) add) {
  if (stem.isEmpty) return;
  formIndex[stem]?.forEach(add);
  // 했 / 해 → 하다 (공부했 → 공부하다, and the noun 공부)
  if (stem.endsWith('했') || stem.endsWith('해') || stem.endsWith('하')) {
    final head = stem.substring(0, stem.length - 1);
    add('$head하다');
    add(head);
  }
  final last = lastSyllable(stem);
  if (last == null) return;
  // A past ㅆ, a future ㄹ, a modifier ㄴ or a formal ㅂ under the last syllable: take it off.
  final bare = last.finalC == F.ss || last.finalC == F.l || last.finalC == F.n || last.finalC == F.b ? addBatchim(stem, F.none) : null;
  for (final s in [stem, ?bare]) {
    add('$s다');
    formIndex[s]?.forEach(add);
    formIndex['$s니']?.forEach(add);
    // ㄹ-drop verbs: 사는 / 산 / 삽니다 → 살다; 만드는 → 만들다
    final ls = lastSyllable(s)!;
    if (ls.finalC == F.none) add('${addBatchim(s, F.l)}다');
    // Undo vowel contractions: 봐 → 보, 줘 → 주, 마셔 → 마시, 돼 → 되
    final undo = switch (ls.medial) {
      V.wa => ls.withMedial(V.o),
      V.wo => ls.withMedial(V.u),
      V.yeo => ls.withMedial(V.i),
      V.wae => ls.withMedial(V.oe),
      _ => null,
    };
    if (undo != null) add('${replaceLast(s, undo)}다');
  }
}

/// Splits running text into word tokens worth looking up (Hangul runs only).
List<String> tokenize(String text) =>
    RegExp(r'[가-힣]+').allMatches(text).map((m) => m.group(0)!).toList();
