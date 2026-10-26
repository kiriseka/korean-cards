import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../game/game_service.dart';
import '../../game/sound_service.dart';
import '../../games/exercise_views.dart';
import '../../learn/exercises.dart';
import '../../providers.dart';
import 'play_screen.dart';

/// Clear boards of 5 pairs before 90 seconds run out. Each pair scores 1; a cleared board adds 5 seconds.
class MatchMadnessScreen extends ConsumerStatefulWidget {
  const MatchMadnessScreen({super.key, required this.words, required this.generator});
  final List<Word> words;
  final ExerciseGenerator generator;

  @override
  ConsumerState<MatchMadnessScreen> createState() => _MatchMadnessScreenState();
}

class _MatchMadnessScreenState extends ConsumerState<MatchMadnessScreen> {
  static const _length = 90;
  int _left = _length;
  int _score = 0;
  int _board = 0;
  late MatchExercise _current;
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
    _bestBefore = ref.read(bestScoresProvider).value?['match'];
    setState(() {
      _left = _length;
      _score = 0;
      _outcome = null;
      _newBoard();
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _left--);
      if (_left <= 0) _finish();
    });
  }

  void _newBoard() {
    final seen = <String>{};
    final picks = (widget.words.toList()..shuffle()).where((w) => seen.add(w.word) && seen.add('en:${shortGloss(w)}')).take(5).toList();
    _current = widget.generator.match(picks);
    _board++;
  }

  void _boardCleared(bool _) {
    ref.read(soundProvider).play(Sfx.combo);
    setState(() {
      _left = (_left + 5).clamp(0, _length);
      _newBoard();
    });
  }

  Future<void> _finish() async {
    _timer?.cancel();
    if (_outcome != null) return;
    final game = ref.read(gameProvider);
    final outcome = await game.award([game.activity(ActivityKind.game, xp: _score, value: _score, ref: 'match')]);
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
            GameOverView(title: 'Match Madness', score: _score, best: _bestBefore, outcome: _outcome!, onAgain: _start)
          else
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Row(children: [
                  const CloseButton(),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _left / _length,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                      color: _left <= 15 ? Colors.red : Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('⏱ $_left', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 8),
                Text('Pairs: $_score', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: MatchView(
                    key: ValueKey(_board),
                    exercise: _current,
                    onAnswer: _boardCleared,
                    onPair: () => setState(() => _score++),
                  ),
                ),
              ]),
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
