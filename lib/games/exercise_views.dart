import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/sound_service.dart';
import '../learn/exercises.dart';
import '../providers.dart';
import '../settings.dart';

typedef AnswerCallback = void Function(bool correct);

/// Shows any [Exercise]; calls [onAnswer] once. After that it shows what was right.
class ExerciseView extends StatelessWidget {
  const ExerciseView({super.key, required this.exercise, required this.onAnswer, this.instant = false});
  final Exercise exercise;
  final AnswerCallback onAnswer;

  /// Arcade mode: tapping an option answers immediately, no Check button.
  final bool instant;

  @override
  Widget build(BuildContext context) => switch (exercise) {
        final ChoiceExercise e => ChoiceView(exercise: e, onAnswer: onAnswer),
        final MatchExercise e => MatchView(exercise: e, onAnswer: onAnswer),
        final SyllableExercise e => SyllableView(exercise: e, onAnswer: onAnswer),
        final TypingExercise e => TypingView(exercise: e, onAnswer: onAnswer),
        final SentenceExercise e => SentenceView(exercise: e, onAnswer: onAnswer),
      };
}

class _Instruction extends StatelessWidget {
  const _Instruction(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      );
}

// ---- Multiple choice --------------------------------------------------------

class ChoiceView extends ConsumerStatefulWidget {
  const ChoiceView({super.key, required this.exercise, required this.onAnswer});
  final ChoiceExercise exercise;
  final AnswerCallback onAnswer;

  @override
  ConsumerState<ChoiceView> createState() => _ChoiceViewState();
}

class _ChoiceViewState extends ConsumerState<ChoiceView> {
  int? _picked;

  ChoiceExercise get e => widget.exercise;

  @override
  void initState() {
    super.initState();
    final autoPlay = ref.read(settingsProvider).autoPlay;
    if (e.speak != null && (e.style == PromptStyle.audio || (e.style == PromptStyle.korean && autoPlay))) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.speak(e.style == PromptStyle.audio ? e.prompt : e.speak!));
    }
  }

  void _pick(int i) {
    if (_picked != null) return;
    setState(() => _picked = i);
    final correct = i == e.answer;
    widget.onAnswer(correct);
    if (e.speak != null && e.style != PromptStyle.audio && (e.optionsKorean || e.style == PromptStyle.sentence)) {
      ref.speak(e.speak!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Instruction(e.instruction),
        Expanded(
          flex: 2,
          child: Center(
            child: switch (e.style) {
              PromptStyle.audio => _AudioPrompt(text: e.prompt),
              PromptStyle.korean => Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(e.prompt, style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.volume_up_rounded), onPressed: () => ref.speak(e.prompt)),
                  ]),
                  if (e.subPrompt != null) Text(e.subPrompt!, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                ]),
              PromptStyle.english => Text(e.prompt, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
              PromptStyle.sentence => Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(e.prompt, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
                  if (e.subPrompt != null) ...[
                    const SizedBox(height: 8),
                    Text(e.subPrompt!, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: scheme.outline)),
                  ],
                ]),
            },
          ),
        ),
        Expanded(
          flex: 3,
          child: ListView(
            children: [
              for (final (i, option) in e.options.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _OptionButton(
                    text: option,
                    korean: e.optionsKorean,
                    state: _picked == null
                        ? _OptionState.idle
                        : i == e.answer
                            ? _OptionState.right
                            : i == _picked
                                ? _OptionState.wrong
                                : _OptionState.dim,
                    onTap: () => _pick(i),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _OptionState { idle, right, wrong, dim }

class _OptionButton extends StatelessWidget {
  const _OptionButton({required this.text, required this.korean, required this.state, required this.onTap});
  final String text;
  final bool korean;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg, border) = switch (state) {
      _OptionState.idle => (scheme.surface, scheme.onSurface, scheme.outlineVariant),
      _OptionState.right => (Colors.green.shade100, Colors.green.shade900, Colors.green),
      _OptionState.wrong => (Colors.red.shade100, Colors.red.shade900, Colors.red),
      _OptionState.dim => (scheme.surface, scheme.onSurface.withValues(alpha: 0.4), scheme.outlineVariant),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 2),
        boxShadow: [if (state == _OptionState.idle) BoxShadow(color: border, offset: const Offset(0, 3))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: state == _OptionState.idle ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: korean ? 22 : 17, color: fg, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

class _AudioPrompt extends ConsumerWidget {
  const _AudioPrompt({required this.text});
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton(
          style: FilledButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(28)),
          onPressed: () => ref.speak(text),
          child: const Icon(Icons.volume_up_rounded, size: 48),
        ),
        const SizedBox(width: 16),
        IconButton.filledTonal(
          tooltip: 'Slowly',
          icon: const Text('🐢', style: TextStyle(fontSize: 22)),
          onPressed: () => ref.read(ttsProvider).speak(text, rate: 0.25),
          style: IconButton.styleFrom(backgroundColor: scheme.secondaryContainer),
        ),
      ],
    );
  }
}

// ---- Match pairs ----------------------------------------------------------

class MatchView extends ConsumerStatefulWidget {
  const MatchView({super.key, required this.exercise, required this.onAnswer, this.onPair});
  final MatchExercise exercise;
  final AnswerCallback onAnswer;

  /// Called for each correct pair (arcade scoring).
  final VoidCallback? onPair;

  @override
  ConsumerState<MatchView> createState() => _MatchViewState();
}

class _MatchViewState extends ConsumerState<MatchView> {
  late final List<int> _left; // pair indexes in Korean column order
  late final List<int> _right;
  final Set<int> _done = {};
  int? _selLeft, _selRight;
  int? _wrongLeft, _wrongRight;
  int _mistakes = 0;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final n = widget.exercise.pairs.length;
    _left = List.generate(n, (i) => i)..shuffle(rng);
    _right = List.generate(n, (i) => i)..shuffle(rng);
  }

  void _tap({int? left, int? right}) {
    setState(() {
      _wrongLeft = _wrongRight = null;
      if (left != null) {
        _selLeft = left;
        ref.speak(widget.exercise.pairs[left].$1);
      }
      if (right != null) _selRight = right;
    });
    if (_selLeft == null || _selRight == null) return;
    final sound = ref.read(soundProvider);
    if (_selLeft == _selRight) {
      setState(() => _done.add(_selLeft!));
      sound.play(Sfx.tap);
      widget.onPair?.call();
      if (_done.length == widget.exercise.pairs.length) widget.onAnswer(_mistakes <= 1);
    } else {
      _mistakes++;
      sound.play(Sfx.wrong);
      setState(() {
        _wrongLeft = _selLeft;
        _wrongRight = _selRight;
      });
    }
    setState(() => _selLeft = _selRight = null);
  }

  Widget _tile(String text, {required bool selected, required bool done, required bool wrong, required bool korean, required VoidCallback onTap}) {
    final scheme = Theme.of(context).colorScheme;
    final color = done
        ? Colors.green.withValues(alpha: 0.15)
        : wrong
            ? Colors.red.shade100
            : selected
                ? scheme.primaryContainer
                : scheme.surface;
    return Padding(
      padding: const EdgeInsets.all(5),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: done ? 0.35 : 1,
        child: Material(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: selected ? scheme.primary : scheme.outlineVariant, width: 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: done ? null : onTap,
            child: Container(
              height: 64,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(text,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: korean ? 20 : 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pairs = widget.exercise.pairs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Instruction('Tap the matching pairs'),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(children: [
                  for (final i in _left)
                    _tile(pairs[i].$1,
                        korean: true,
                        selected: _selLeft == i,
                        done: _done.contains(i),
                        wrong: _wrongLeft == i,
                        onTap: () => _tap(left: i)),
                ]),
              ),
              Expanded(
                child: Column(children: [
                  for (final i in _right)
                    _tile(pairs[i].$2,
                        korean: false,
                        selected: _selRight == i,
                        done: _done.contains(i),
                        wrong: _wrongRight == i,
                        onTap: () => _tap(right: i)),
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---- Tiles: syllables and sentences ------------------------------------------

/// Tap tiles from a bank into an answer row; tap a placed tile to put it back.
class _TileBuilder extends StatelessWidget {
  const _TileBuilder({
    required this.tiles,
    required this.placed,
    required this.onPlace,
    required this.onRemove,
    required this.locked,
    this.result,
    this.large = false,
  });

  final List<String> tiles;
  final List<int> placed; // indexes into tiles
  final void Function(int) onPlace;
  final void Function(int) onRemove;
  final bool locked;
  final bool? result;
  final bool large;

  Widget _chip(BuildContext context, String text, {VoidCallback? onTap, bool ghost = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: ghost ? scheme.surfaceContainerHighest : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: ghost ? Colors.transparent : scheme.outlineVariant, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: ghost || locked ? null : onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: large ? 18 : 14, vertical: large ? 12 : 10),
          child: Text(text,
              style: TextStyle(
                  fontSize: large ? 26 : 19, fontWeight: FontWeight.w600, color: ghost ? Colors.transparent : null)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = switch (result) {
      true => Colors.green,
      false => Colors.red,
      null => scheme.outlineVariant,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: border, width: 2), top: BorderSide(color: border, width: 2)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final i in placed) _chip(context, tiles[i], onTap: () => onRemove(i))],
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final (i, t) in tiles.indexed) _chip(context, t, ghost: placed.contains(i), onTap: () => onPlace(i)),
          ],
        ),
      ],
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({required this.enabled, required this.onPressed});
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
        onPressed: enabled ? onPressed : null,
        child: const Text('Check', style: TextStyle(fontSize: 18)),
      );
}

class SyllableView extends ConsumerStatefulWidget {
  const SyllableView({super.key, required this.exercise, required this.onAnswer});
  final SyllableExercise exercise;
  final AnswerCallback onAnswer;

  @override
  ConsumerState<SyllableView> createState() => _SyllableViewState();
}

class _SyllableViewState extends ConsumerState<SyllableView> {
  final List<int> _placed = [];
  bool? _result;

  @override
  Widget build(BuildContext context) {
    final e = widget.exercise;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Instruction('Build the word'),
        Text(e.english, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        _TileBuilder(
          tiles: e.tiles,
          placed: _placed,
          large: true,
          locked: _result != null,
          result: _result,
          onPlace: (i) => setState(() => _placed.add(i)),
          onRemove: (i) => setState(() => _placed.remove(i)),
        ),
        const Spacer(),
        if (_result == null)
          _CheckButton(
            enabled: _placed.length == e.answer.length,
            onPressed: () {
              final ok = _placed.map((i) => e.tiles[i]).join() == e.answer;
              setState(() => _result = ok);
              ref.speak(e.answer);
              widget.onAnswer(ok);
            },
          ),
      ],
    );
  }
}

class SentenceView extends ConsumerStatefulWidget {
  const SentenceView({super.key, required this.exercise, required this.onAnswer});
  final SentenceExercise exercise;
  final AnswerCallback onAnswer;

  @override
  ConsumerState<SentenceView> createState() => _SentenceViewState();
}

class _SentenceViewState extends ConsumerState<SentenceView> {
  final List<int> _placed = [];
  bool? _result;

  @override
  Widget build(BuildContext context) {
    final e = widget.exercise;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Instruction('Build the sentence'),
        Row(children: [
          const Text('🐯', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(e.english, style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
        ]),
        const SizedBox(height: 24),
        _TileBuilder(
          tiles: e.tiles,
          placed: _placed,
          locked: _result != null,
          result: _result,
          onPlace: (i) {
            setState(() => _placed.add(i));
            ref.speak(e.tiles[i]);
          },
          onRemove: (i) => setState(() => _placed.remove(i)),
        ),
        const Spacer(),
        if (_result == null)
          _CheckButton(
            enabled: _placed.isNotEmpty,
            onPressed: () {
              final ok = _placed.map((i) => e.tiles[i]).join(' ') == e.sentence;
              setState(() => _result = ok);
              ref.speak(e.sentence);
              widget.onAnswer(ok);
            },
          ),
      ],
    );
  }
}

// ---- Typing ---------------------------------------------------------------------

class TypingView extends ConsumerStatefulWidget {
  const TypingView({super.key, required this.exercise, required this.onAnswer});
  final TypingExercise exercise;
  final AnswerCallback onAnswer;

  @override
  ConsumerState<TypingView> createState() => _TypingViewState();
}

class _TypingViewState extends ConsumerState<TypingView> {
  final _controller = TextEditingController();
  bool? _result;
  bool _showHint = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check() {
    if (_result != null || _controller.text.trim().isEmpty) return;
    final ok = widget.exercise.accepts(_controller.text);
    setState(() => _result = ok);
    ref.speak(widget.exercise.answer);
    widget.onAnswer(ok);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.exercise;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Instruction('Type it in Korean'),
        Text(e.prompt, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        TextField(
          controller: _controller,
          autofocus: true,
          enabled: _result == null,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28),
          decoration: InputDecoration(
            hintText: '한글로 쓰세요',
            border: const OutlineInputBorder(),
            suffixIcon: _result == null
                ? null
                : Icon(_result! ? Icons.check_circle : Icons.cancel, color: _result! ? Colors.green : Colors.red),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _check(),
        ),
        const SizedBox(height: 8),
        if (e.hint != null)
          Align(
            child: TextButton.icon(
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(_showHint ? e.hint! : 'Hint'),
              onPressed: () => setState(() => _showHint = true),
            ),
          ),
        const Spacer(),
        if (_result == null) _CheckButton(enabled: _controller.text.trim().isNotEmpty, onPressed: _check),
      ],
    );
  }
}
