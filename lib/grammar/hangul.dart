/// Hangul syllable arithmetic: a syllable is (initial, medial vowel, final consonant "batchim").
library;

const _base = 0xAC00;
const _count = 11172;

/// Medial vowel indexes.
abstract final class V {
  static const a = 0, ae = 1, eo = 4, e = 5, yeo = 6, o = 8, wa = 9, wae = 10, oe = 11;
  static const u = 13, wo = 14, wi = 16, eu = 18, ui = 19, i = 20;
}

/// Final consonant (batchim) indexes.
abstract final class F {
  static const none = 0, n = 4, l = 8, b = 17, ss = 20;
}

class Syllable {
  const Syllable(this.initial, this.medial, this.finalC);
  final int initial;
  final int medial;
  final int finalC;

  String get char => String.fromCharCode(_base + initial * 588 + medial * 28 + finalC);
  Syllable withMedial(int m) => Syllable(initial, m, finalC);
  Syllable withFinal(int f) => Syllable(initial, medial, f);
}

Syllable? syllableOf(String ch) {
  if (ch.isEmpty) return null;
  final code = ch.codeUnitAt(0) - _base;
  if (code < 0 || code >= _count) return null;
  return Syllable(code ~/ 588, (code % 588) ~/ 28, code % 28);
}

bool isHangul(String text) => text.runes.any((r) => r - _base >= 0 && r - _base < _count);

Syllable? lastSyllable(String word) => word.isEmpty ? null : syllableOf(word[word.length - 1]);

/// Whether the last syllable has a final consonant. Non-Hangul endings (numbers, Latin) count as none.
bool hasBatchim(String word) => (lastSyllable(word)?.finalC ?? F.none) != F.none;

String replaceLast(String word, Syllable s) => word.substring(0, word.length - 1) + s.char;

/// Puts [finalC] under the last syllable: 가 + ㄹ → 갈.
String addBatchim(String word, int finalC) {
  final s = lastSyllable(word);
  return s == null ? word : replaceLast(word, s.withFinal(finalC));
}

/// Particle form after [word]: 책은 / 사과는. With [rieulAsVowel], ㄹ batchim takes the vowel form, as for (으)로.
String particle(String word, String afterConsonant, String afterVowel, {bool rieulAsVowel = false}) {
  final f = lastSyllable(word)?.finalC ?? F.none;
  final vowelForm = f == F.none || (rieulAsVowel && f == F.l);
  return vowelForm ? afterVowel : afterConsonant;
}

abstract final class Particles {
  static String topic(String w) => w + particle(w, '은', '는');
  static String subject(String w) => w + particle(w, '이', '가');
  static String object(String w) => w + particle(w, '을', '를');
  static String and(String w) => w + particle(w, '과', '와');
  static String direction(String w) => w + particle(w, '으로', '로', rieulAsVowel: true);
  static String copula(String w) => w + particle(w, '이에요', '예요');
}
