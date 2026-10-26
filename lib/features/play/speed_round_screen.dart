import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../game/game_service.dart';
import '../../game/sound_service.dart';
import '../../learn/exercises.dart';
import '../../providers.dart';
import 'play_screen.dart';

/// 60 seconds of rapid-fire meaning questions. Wrong answers cost 3 seconds.
class SpeedRoundScreen extends ConsumerStatefulWidget {
  const SpeedRoundScreen({super.key, required this.words, required this.generator});
  final List<Word> words;
  final ExerciseGenerator generator;

  @override
  ConsumerState<SpeedRoundScreen> createState() => _SpeedRoundScreenState();
}

class _SpeedRoundScreenState extends ConsumerState<SpeedRoundScreen> {
  static const _length = 60;
  int _left = _length;
  int _score = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _turn = 0;
  late ChoiceExercise _current;
  int? _picked;
  Timer? _timer;
  AwardOutcome? _outcome;
  int? _bestBefore;
  final _confetti = ConfettiController(duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _bestBefore = ref.read(bestScoresProvider).value?['speed'];
    setState(() {
      _left = _length;
      _score = _combo = _bestCombo = 0;
      _outcome = null;
      _next();
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _left--);
      if (_left <= 0) _finish();
    });
  }

  void _next() {
    final w = (widget.words.toList()..shuffle()).first;
    _current = _turn.isEven ? widget.generator.meaning(w) : widget.generator.reverse(w);
    _picked = null;
    _turn++;
  }

  Future<void> _pick(int i) async {
    if (_picked != null || _outcome != null) return;
    final sound = ref.read(soundProvider);
    final ok = i == _current.answer;
    setState(() {
      _picked = i;
      if (ok) {
        _score++;
        _combo++;
        if (_combo > _bestCombo) _bestCombo = _combo;
      } else {
        _combo = 0;
        _left = (_left - 3).clamp(0, _length);
      }
    });
    sound.play(ok ? (_combo % 5 == 0 ? Sfx.combo : Sfx.correct) : Sfx.wrong);
    await Future.delayed(Duration(milliseconds: ok ? 250 : 700));
    if (mounted && _outcome == null && _left > 0) setState(_next);
  }

  Future<void> _finish() async {
    _timer?.cancel();
    if (_outcome != null) return;
    final game = ref.read(gameProvider);
    final outcome = await game.award([
      game.activity(ActivityKind.game, xp: _score * 2, value: _score, ref: 'speed'),
      if (_bestCombo > 0) game.activity(ActivityKind.combo, value: _bestCombo),
      if (_score > 0) game.activity(ActivityKind.answer, value: _score),
    ]);
    if (!mounted) return;
    setState(() => _outcome = outcome);
    ref.read(soundProvider).play(Sfx.complete);
    if (_bestBefore == null || _score > _bestBefore!) _confetti.play();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          if (_outcome != null)
            GameOverView(title: 'Speed Round', score: _score, best: _bestBefore, outcome: _outcome!, onAgain: _start)
          else
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    const CloseButton(),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _left / _length,
                        minHeight: 12,
                        borderRadius: BorderRadius.circular(6),
                        color: _left <= 10 ? Colors.red : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('⏱ $_left', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Score $_score', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    if (_combo >= 3) Text('🔥 $_combo', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.deepOrange)),
                  ]),
                  Expanded(
                    child: Center(
                      child: Text(
                        _current.prompt,
                        key: ValueKey(_turn),
                        textAlign: TextAlign.center,
                        style: _current.style == PromptStyle.korean
                            ? theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold)
                            : theme.textTheme.headlineMedium,
                      ),
                    ),
                  ),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.2,
                    children: [
                      for (final (i, o) in _current.options.indexed)
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            backgroundColor: _picked == null
                                ? null
                                : i == _current.answer
                                    ? Colors.green.shade300
                                    : i == _picked
                                        ? Colors.red.shade300
                                        : null,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => _pick(i),
                          child: Text(o, textAlign: TextAlign.center, maxLines: 2, style: TextStyle(fontSize: _current.optionsKorean ? 22 : 15)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(confettiController: _confetti, blastDirectionality: BlastDirectionality.explosive, numberOfParticles: 40),
          ),
        ]),
      ),
    );
  }
}
