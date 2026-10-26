import 'dart:math';

import '../grammar/hangul.dart';

/// How well what was heard matches what should have been said.
class SpeechMatch {
  const SpeechMatch({required this.score, required this.syllables, required this.passed, required this.heard});

  /// 0..1, from letter-level (jamo) edit distance.
  final double score;

  /// The target's syllables, each marked as heard correctly or not (spaces kept for display).
  final List<(String, bool)> syllables;
  final bool passed;
  final String heard;

  int get percent => (score * 100).round();
}

const wordPass = 0.8;
const sentencePass = 0.7;

/// Compares a recognizer transcript with the target. Spacing and punctuation are ignored, and
/// digits the recognizer writes ("3시", "15,000원") are tried as both Sino-Korean and native words.
SpeechMatch matchSpeech(String target, String heard, {double? passAt}) {
  final threshold = passAt ?? (_hangulOnly(target).length <= 4 ? wordPass : sentencePass);
  final goal = _hangulOnly(_digitsToWords(target, native: false));
  var best = (0.0, '');
  for (final variant in _variants(heard)) {
    final s = _score(goal, variant);
    if (s > best.$1) best = (s, variant);
  }
  return SpeechMatch(
    score: best.$1,
    syllables: _markSyllables(target, best.$2),
    passed: goal.isNotEmpty && best.$1 >= threshold,
    heard: heard,
  );
}

String _hangulOnly(String s) => s.split('').where((c) => syllableOf(c) != null).join();

Iterable<String> _variants(String heard) => {
      _hangulOnly(_digitsToWords(heard, native: false)),
      _hangulOnly(_digitsToWords(heard, native: true)),
      _hangulOnly(_digitsToWords(heard, native: true, counter: true)),
    };

List<int> _jamo(String s) => [
      for (final c in s.split(''))
        if (syllableOf(c) case final syl?) ...[syl.initial, 100 + syl.medial, if (syl.finalC != 0) 200 + syl.finalC],
    ];

int _distance<T>(List<T> a, List<T> b) {
  var prev = List<int>.generate(b.length + 1, (j) => j);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      cur[j] = min(min(cur[j - 1] + 1, prev[j] + 1), prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1));
    }
    prev = cur;
  }
  return prev[b.length];
}

double _score(String goal, String heard) {
  if (goal.isEmpty) return 0;
  final a = _jamo(goal), b = _jamo(heard);
  return (1 - _distance(a, b) / a.length).clamp(0.0, 1.0);
}

/// Aligns target syllables with heard ones (edit-distance backtrace) to mark each as right or wrong.
List<(String, bool)> _markSyllables(String target, String heard) {
  final display = target.split('');
  final t = [for (final c in display) if (syllableOf(c) != null) c];
  final h = heard.split('');
  final d = List.generate(t.length + 1, (i) => List<int>.filled(h.length + 1, 0));
  for (var i = 0; i <= t.length; i++) {
    d[i][0] = i;
  }
  for (var j = 0; j <= h.length; j++) {
    d[0][j] = j;
  }
  for (var i = 1; i <= t.length; i++) {
    for (var j = 1; j <= h.length; j++) {
      d[i][j] = min(min(d[i - 1][j] + 1, d[i][j - 1] + 1), d[i - 1][j - 1] + (t[i - 1] == h[j - 1] ? 0 : 1));
    }
  }
  final ok = List<bool>.filled(t.length, false);
  var i = t.length, j = h.length;
  while (i > 0 && j > 0) {
    if (t[i - 1] == h[j - 1] && d[i][j] == d[i - 1][j - 1]) {
      ok[i - 1] = true;
      i--;
      j--;
    } else if (d[i][j] == d[i - 1][j - 1] + 1) {
      i--;
      j--;
    } else if (d[i][j] == d[i - 1][j] + 1) {
      i--;
    } else {
      j--;
    }
  }
  var k = 0;
  return [for (final c in display) (c, syllableOf(c) == null ? true : ok[k++])];
}

// ---- Numbers -------------------------------------------------------------------

const _sinoDigits = ['', '일', '이', '삼', '사', '오', '육', '칠', '팔', '구'];

/// 15000 → 만 오천 (without spaces: 만오천), 2 → 이.
String sinoNumber(int n) {
  if (n == 0) return '영';
  String under10k(int x) {
    final out = StringBuffer();
    for (final (unit, name) in [(1000, '천'), (100, '백'), (10, '십')]) {
      final d = x ~/ unit % 10;
      if (d > 0) out.write('${d == 1 ? '' : _sinoDigits[d]}$name');
    }
    out.write(_sinoDigits[x % 10]);
    return out.toString();
  }

  final parts = StringBuffer();
  final eok = n ~/ 100000000, man = n ~/ 10000 % 10000, rest = n % 10000;
  if (eok > 0) parts.write('${under10k(eok)}억');
  if (man > 0) parts.write('${man == 1 ? '' : under10k(man)}만');
  parts.write(under10k(rest));
  return parts.toString();
}

const _nativeOnes = ['', '하나', '둘', '셋', '넷', '다섯', '여섯', '일곱', '여덟', '아홉'];
const _counterOnes = ['', '한', '두', '세', '네', '다섯', '여섯', '일곱', '여덟', '아홉'];
const _nativeTens = ['', '열', '스물', '서른', '마흔', '쉰', '예순', '일흔', '여든', '아흔'];

/// 1–99 in native Korean; [counter] gives the forms used before counters (한 개, 스무 살).
String? nativeNumber(int n, {bool counter = false}) {
  if (n < 1 || n > 99) return null;
  final tens = n ~/ 10, ones = n % 10;
  if (counter && n == 20) return '스무';
  return _nativeTens[tens] + (counter ? _counterOnes : _nativeOnes)[ones];
}

String _digitsToWords(String s, {required bool native, bool counter = false}) =>
    s.replaceAllMapped(RegExp(r'\d[\d,]*'), (m) {
      final n = int.tryParse(m.group(0)!.replaceAll(',', ''));
      if (n == null) return m.group(0)!;
      return (native ? nativeNumber(n, counter: counter) : null) ?? sinoNumber(n);
    });
