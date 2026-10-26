import 'dart:math';

import '../speech/speech_match.dart';
import 'exercises.dart';

/// Sino-Korean reading with the standard spacing every 만: 15000 → 만 오천, 123400 → 십이만 삼천사백.
String sinoSpaced(int n) {
  if (n < 10000) return sinoNumber(n);
  final parts = <String>[];
  final eok = n ~/ 100000000, man = n ~/ 10000 % 10000, rest = n % 10000;
  if (eok > 0) parts.add('${sinoNumber(eok)}억');
  if (man > 0) parts.add('${man == 1 ? '' : sinoNumber(man)}만');
  if (rest > 0) parts.add(sinoNumber(rest));
  return parts.join(' ');
}

/// Month names: 6월 is 유월 and 10월 is 시월 (the consonant drops).
String monthName(int m) => switch (m) {
      6 => '유월',
      10 => '시월',
      _ => '${sinoNumber(m)}월',
    };

/// Native number before a counter (한 개, 스무 살); Sino above 99 (백 개).
String counted(int n, String counter) => '${nativeNumber(n, counter: true) ?? sinoSpaced(n)} $counter';

String _comma(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

class _Counter {
  const _Counter(this.counter, this.noun, this.emoji, this.en);
  final String counter;
  final String noun;
  final String emoji;
  final String en;
}

const _counters = [
  _Counter('개', '사과', '🍎', 'things (apples)'),
  _Counter('명', '사람', '🧑', 'people'),
  _Counter('잔', '커피', '☕', 'cups (coffee)'),
  _Counter('권', '책', '📕', 'books'),
  _Counter('장', '표', '🎫', 'flat things (tickets)'),
  _Counter('마리', '고양이', '🐱', 'animals (cats)'),
];

/// Number, time, money and counter practice, harder as mastery grows.
class NumbersTrainer {
  NumbersTrainer({Random? random}) : rng = random ?? Random();
  final Random rng;

  int _upTo(double mastery, List<int> caps) => caps[mastery < 0.3 ? 0 : mastery < 0.6 ? 1 : 2];

  ChoiceExercise _choice({
    required String instruction,
    required String prompt,
    required String right,
    required Iterable<String> wrong,
    required String skillId,
    PromptStyle style = PromptStyle.english,
    String? subPrompt,
    String? speak,
    String? explanation,
    bool optionsKorean = true,
  }) {
    final options = <String>{right, ...wrong.where((w) => w != right)}.take(4).toList()..shuffle(rng);
    return ChoiceExercise(
      instruction: instruction,
      prompt: prompt,
      subPrompt: subPrompt,
      style: style,
      options: options,
      answer: options.indexOf(right),
      optionsKorean: optionsKorean,
      speak: speak ?? right,
      explanation: explanation,
      skillIds: [skillId],
    );
  }

  /// Nearby numbers that sound or look alike: 27 → 72, 17, 37.
  List<int> _nearby(int n, int max) {
    final out = <int>{};
    final s = n.toString();
    if (s.length == 2) out.add(int.parse(s.split('').reversed.join()));
    out.addAll([n + 10, n - 10, n + 1, n * 10, n ~/ 10]);
    return out.where((x) => x > 0 && x != n && x <= max * 10).toList()..shuffle(rng);
  }

  Exercise forSkill(String skillId, {double mastery = 0, bool speakingOn = false}) => switch (skillId) {
        'n_sino' => _sino(mastery),
        'n_native' => _native(mastery),
        'n_time' => _time(speakingOn),
        'n_money' => _money(mastery, speakingOn),
        _ => _counter(),
      };

  Exercise _sino(double mastery) {
    final roll = rng.nextInt(4);
    if (roll == 0) {
      final m = 1 + rng.nextInt(12);
      return _choice(
        instruction: 'How do you say the month?',
        prompt: '$m월',
        subPrompt: 'month $m',
        right: monthName(m),
        wrong: ['${sinoNumber(m)}월', '${nativeNumber(m, counter: true) ?? sinoNumber(m)} 월', monthName(m % 12 + 1)],
        skillId: 'n_sino',
        explanation: m == 6 || m == 10 ? '6월 = 유월 and 10월 = 시월: the last sound drops.' : 'Months use Sino numbers + 월.',
      );
    }
    final n = 1 + rng.nextInt(_upTo(mastery, [20, 100, 1000]));
    if (roll == 1) {
      // Hear it, pick the digits.
      final options = [n, ..._nearby(n, 1000).take(3)];
      return _choice(
        instruction: 'Which number did you hear?',
        prompt: sinoSpaced(n),
        style: PromptStyle.audio,
        right: '$n',
        wrong: options.skip(1).map((x) => '$x'),
        skillId: 'n_sino',
        speak: sinoSpaced(n),
        optionsKorean: false,
      );
    }
    return _choice(
      instruction: 'Read it the Sino-Korean way (일, 이, 삼…)',
      prompt: '$n',
      subPrompt: 'used for dates, money, minutes, phone numbers',
      right: sinoSpaced(n),
      wrong: [?nativeNumber(n), ..._nearby(n, 1000).take(3).map(sinoSpaced)],
      skillId: 'n_sino',
    );
  }

  Exercise _native(double mastery) {
    final n = 1 + rng.nextInt(_upTo(mastery, [10, 30, 99]));
    if (rng.nextBool()) {
      return _choice(
        instruction: 'How old? (native number + 살)',
        prompt: '$n years old',
        right: counted(n, '살'),
        wrong: ['${sinoSpaced(n)} 살', '${nativeNumber(n)} 살', counted(n + 1, '살')],
        skillId: 'n_native',
        explanation: 'Age uses native numbers before 살: 한 살, 스무 살, 서른 살.',
      );
    }
    final c = _counters[rng.nextInt(_counters.length)];
    return _choice(
      instruction: 'Count them (native number + counter)',
      prompt: '${c.noun} $n${c.counter}',
      subPrompt: n <= 10 ? List.filled(n, c.emoji).join() : '$n ${c.en}',
      right: '${c.noun} ${counted(n, c.counter)}',
      wrong: ['${c.noun} ${sinoSpaced(n)} ${c.counter}', '${c.noun} ${nativeNumber(n) ?? sinoSpaced(n)} ${c.counter}', '${c.noun} ${counted(n == 1 ? 2 : n - 1, c.counter)}'],
      skillId: 'n_native',
      explanation: 'Counters take native numbers, and 1–4 and 20 shorten: 한, 두, 세, 네, 스무.',
    );
  }

  Exercise _time(bool speakingOn) {
    final h = 1 + rng.nextInt(12);
    final m = [0, 5, 10, 15, 20, 30, 40, 45, 50][rng.nextInt(9)];
    final digital = '$h:${m.toString().padLeft(2, '0')}';
    final reading = m == 0 ? counted(h, '시') : '${counted(h, '시')} ${sinoSpaced(m)} 분';
    final roll = rng.nextInt(3);
    if (roll == 0 && speakingOn) return SpeakExercise(target: reading, mode: SpeakMode.sayIt, english: 'It is $digital.', skillIds: const ['n_time']);
    if (roll == 1) {
      return _choice(
        instruction: 'What time did you hear?',
        prompt: reading,
        style: PromptStyle.audio,
        right: digital,
        wrong: ['${h % 12 + 1}:${m.toString().padLeft(2, '0')}', '$h:${((m + 20) % 60).toString().padLeft(2, '0')}', '${(h + 2) % 12 + 1}:${m.toString().padLeft(2, '0')}'],
        skillId: 'n_time',
        speak: reading,
        optionsKorean: false,
      );
    }
    final sinoHour = m == 0 ? '${sinoNumber(h)} 시' : '${sinoNumber(h)} 시 ${sinoSpaced(m)} 분';
    final nativeMinute = m == 0 || nativeNumber(m) == null ? '${counted(h, '시')} ${sinoSpaced(m + 5)} 분' : '${counted(h, '시')} ${nativeNumber(m, counter: true)} 분';
    return _choice(
      instruction: 'Read the time',
      prompt: digital,
      right: reading,
      wrong: [sinoHour, nativeMinute],
      skillId: 'n_time',
      explanation: 'Hours are native (세 시), minutes are Sino (삼십 분).${m == 30 ? ' 30 minutes can also be 반: ${counted(h, '시')} 반.' : ''}',
    );
  }

  Exercise _money(double mastery, bool speakingOn) {
    final step = _upTo(mastery, [1000, 500, 100]);
    final max = _upTo(mastery, [10000, 100000, 1000000]);
    final n = step * (1 + rng.nextInt(max ~/ step));
    final reading = '${sinoSpaced(n)} 원';
    final roll = rng.nextInt(3);
    if (roll == 0 && speakingOn) return SpeakExercise(target: reading, mode: SpeakMode.sayIt, english: '₩${_comma(n)}', skillIds: const ['n_money']);
    final near = [n * 10, n ~/ 10 < step ? n + step : n ~/ 10, n + 10 * step, if (n >= 2 * step) n - step].where((x) => x > 0 && x != n).toList()..shuffle(rng);
    if (roll == 1) {
      return _choice(
        instruction: 'How much did you hear?',
        prompt: reading,
        style: PromptStyle.audio,
        right: '₩${_comma(n)}',
        wrong: near.take(3).map((x) => '₩${_comma(x)}'),
        skillId: 'n_money',
        speak: reading,
        optionsKorean: false,
      );
    }
    return _choice(
      instruction: 'Say the price',
      prompt: '₩${_comma(n)}',
      right: reading,
      wrong: near.take(3).map((x) => '${sinoSpaced(x)} 원'),
      skillId: 'n_money',
      explanation: 'Money uses Sino numbers, grouped by 만 (10,000): ₩15,000 = 만 오천 원 (no 일 before 만).',
    );
  }

  Exercise _counter() {
    final c = _counters[rng.nextInt(_counters.length)];
    final n = 1 + rng.nextInt(5);
    final others = _counters.where((x) => x.counter != c.counter).toList()..shuffle(rng);
    return _choice(
      instruction: 'Which counter?',
      prompt: '${c.noun} ${nativeNumber(n, counter: true)} ___',
      subPrompt: List.filled(n, c.emoji).join(),
      right: c.counter,
      wrong: others.take(3).map((x) => x.counter),
      skillId: 'n_counter',
      speak: '${c.noun} ${counted(n, c.counter)}',
      style: PromptStyle.sentence,
      explanation: '${c.counter} counts ${c.en}: ${c.noun} ${counted(n, c.counter)}.',
    );
  }
}
