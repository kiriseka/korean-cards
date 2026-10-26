import 'hangul.dart';

/// Conjugation forms named the way the grammar lessons teach them.
enum Form {
  present('Present (polite)', '-아요/어요'),
  past('Past (polite)', '-았어요/었어요'),
  future('Future (polite)', '-(으)ㄹ 거예요'),
  progressive('Doing now', '-고 있어요'),
  formal('Formal present', '-ㅂ니다/습니다'),
  formalPast('Formal past', '-았습니다/었습니다'),
  negative('Negative', '안 + -아요/어요'),
  negativeJi('Negative', '-지 않아요'),
  want('Want to', '-고 싶어요'),
  please('Please do', '-(으)세요'),
  canDo('Can do', '-(으)ㄹ 수 있어요'),
  mustDo('Have to', '-아야/어야 해요'),
  shallWe('Shall we?', '-(으)ㄹ까요?'),
  letsDo("Let's", '-(으)ㅂ시다'),
  doForMe('Please do for me', '-아/어 주세요'),
  and('…and…', '-고'),
  but('…but…', '-지만'),
  so('…so / and then…', '-아서/어서'),
  because('…because…', '-(으)니까'),
  ifWhen('if / when…', '-(으)면'),
  modPresent('Describing a noun (now)', '-는'),
  modPast('Describing a noun (past)', '-(으)ㄴ'),
  modFuture('Describing a noun (future)', '-(으)ㄹ');

  const Form(this.label, this.pattern);
  final String label;
  final String pattern;
}

/// Conjugates a verb or adjective from its dictionary form.
///
/// KRDict lists each word's 아/어 form (들어) and 으니 form (들으니); with those, irregular
/// verbs come out right. Without them (custom words) regular rules are used, plus 하다 and 르.
class Conjugator {
  Conjugator(this.dictionary, {this.isAdjective = false, this.nounHada = false, String? aForm, String? euniForm})
      : assert(dictionary.endsWith('다') && dictionary.length >= 2),
        stem = dictionary.substring(0, dictionary.length - 1) {
    _a = _contract(_overrides[dictionary]?.$1 ?? aForm ?? _ruleA());
    final euni = _overrides[dictionary]?.$2 ?? euniForm ?? _ruleEuni();
    _eu = euni.substring(0, euni.length - 1);
  }

  /// Conjugates using the `forms` stored for a word ({"a": .., "euni": ..}).
  factory Conjugator.fromWord(String word, String pos, Map<String, dynamic>? forms, {String? hanja}) => Conjugator(
        word,
        isAdjective: pos == 'adjective' || pos == 'auxiliary adjective',
        nounHada: hanja != null && RegExp(r'[一-鿿]').hasMatch(hanja),
        aForm: forms?['a'] as String?,
        euniForm: forms?['euni'] as String?,
      );

  final String dictionary;
  final String stem;
  final bool isAdjective;

  /// A Sino-Korean noun + 하다 (공부하다), negated as 공부 안 해요 rather than 안 공부해요.
  final bool nounHada;
  late final String _a; // 아/어 form: 가, 먹어, 들어, 해
  late final String _eu; // 으니 form minus 니: 가, 먹으, 들으, 사(살다)

  /// Irregular words KRDict gives no forms for.
  static const _overrides = {
    '하얗다': ('하얘', '하야니'),
    '뵙다': ('봬', '뵈니'),
  };

  /// Words that are safe to use in generated drills (forms known or reliably regular).
  static bool drillable(String word, Map<String, dynamic>? forms) =>
      word.endsWith('다') &&
      word.length >= 2 &&
      word != '아니다' &&
      (forms != null || word.endsWith('하다') || word.endsWith('되다') || _overrides.containsKey(word));

  bool get _rieulStem => lastSyllable(stem)?.finalC == F.l;
  bool get _isHada => stem.endsWith('하');

  String _ruleA() {
    if (_isHada) return '${stem.substring(0, stem.length - 1)}해';
    final s = lastSyllable(stem)!;
    if (s.finalC != F.none) return stem + (s.medial == V.a || s.medial == V.o ? '아' : '어');
    if (stem.endsWith('르') && stem.length > 1) {
      // 르 irregular: 모르 → 몰라, 부르 → 불러
      final head = stem.substring(0, stem.length - 1);
      final prev = lastSyllable(head)!;
      return addBatchim(head, F.l) + (prev.medial == V.a || prev.medial == V.o ? '라' : '러');
    }
    if (s.medial == V.eu) {
      // 으 drops: 쓰 → 써, 아프 → 아파, 예쁘 → 예뻐
      final prev = stem.length > 1 ? lastSyllable(stem.substring(0, stem.length - 1)) : null;
      final bright = prev != null && (prev.medial == V.a || prev.medial == V.o);
      return replaceLast(stem, s.withMedial(bright ? V.a : V.eo));
    }
    return stem + (s.medial == V.a || s.medial == V.o ? '아' : '어');
  }

  String _ruleEuni() {
    final f = lastSyllable(stem)!.finalC;
    if (f == F.none) return '$stem니';
    if (f == F.l) return '${addBatchim(stem, F.none)}니'; // 살 → 사니
    return '$stem으니';
  }

  /// 가아 → 가, 보아 → 봐, 주어 → 줘, 마시어 → 마셔, 되어 → 돼. Only when the form is exactly
  /// stem + 아/어, so irregular forms like 모아 (모으다) or 지어 (짓다) are left alone.
  String _contract(String a) {
    if (a != '$stem아' && a != '$stem어') return a;
    final s = lastSyllable(stem)!;
    if (s.finalC != F.none) return a;
    final merged = switch (s.medial) {
      V.a || V.eo || V.ae || V.e || V.yeo => s,
      V.o => s.withMedial(V.wa),
      V.u => s.withMedial(V.wo),
      V.i => s.withMedial(V.yeo),
      V.oe => s.withMedial(V.wae),
      _ => null,
    };
    return merged == null ? a : replaceLast(stem, merged);
  }

  String get _past => addBatchim(_a, F.ss); // 갔, 먹었, 했
  String get _withN => addBatchim(_eu, F.n); // 간, 먹은, 추운
  String get _withL => addBatchim(_eu, F.l); // 갈, 먹을, 살
  bool get _hasItda => stem.endsWith('있') || stem.endsWith('없');

  String _formalStem() {
    final f = lastSyllable(stem)!.finalC;
    if (f == F.none) return addBatchim(stem, F.b);
    if (f == F.l) return addBatchim(stem, F.b); // 살 → 삽
    return '$stem습';
  }

  /// 공부하다 → 공부 안 해요; 가다 → 안 가요.
  String _negative() {
    if (nounHada && _isHada && stem.length > 1 && !isAdjective) {
      return '${stem.substring(0, stem.length - 1)} 안 해요';
    }
    return '안 $_a요';
  }

  String conjugate(Form form) => switch (form) {
        Form.present => '$_a요',
        Form.past => '$_past어요',
        Form.future => '$_withL 거예요',
        Form.progressive => '$stem고 있어요',
        Form.formal => '${_formalStem()}니다',
        Form.formalPast => '$_past습니다',
        Form.negative => _negative(),
        Form.negativeJi => '$stem지 않아요',
        Form.want => '$stem고 싶어요',
        Form.please => '$_eu세요',
        Form.canDo => '$_withL 수 있어요',
        Form.mustDo => '$_a야 해요',
        Form.shallWe => '$_withL까요?',
        Form.letsDo => '${addBatchim(_eu, F.b)}시다',
        Form.doForMe => '$_a 주세요',
        Form.and => '$stem고',
        Form.but => '$stem지만',
        Form.so => '$_a서',
        Form.because => '$_eu니까',
        Form.ifWhen => _rieulStem ? '$stem면' : '$_eu면',
        Form.modPresent => isAdjective && !_hasItda
            ? _withN
            : _rieulStem
                ? '${addBatchim(stem, F.none)}는'
                : '$stem는',
        Form.modPast => _withN,
        Form.modFuture => _withL,
      };

  /// Forms that make sense for this word (adjectives have no "please" or "let's").
  List<Form> get forms => isAdjective
      ? Form.values
          .where((f) => !{
                Form.please, Form.letsDo, Form.shallWe, Form.doForMe, Form.progressive, Form.canDo, Form.modPast,
              }.contains(f))
          .toList()
      : Form.values;
}
