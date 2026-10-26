import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../game/game_service.dart';
import '../../game/sound_service.dart';
import '../../games/speak_view.dart';
import '../../learn/exercises.dart';
import '../../providers.dart';
import '../../settings.dart';
import 'play_screen.dart';

/// Hear a short sentence, say it back. As many as you can in 2 minutes.
class EchoScreen extends ConsumerStatefulWidget {
  const EchoScreen({super.key, required this.words});
  final List<Word> words;

  @override
  ConsumerState<EchoScreen> createState() => _EchoScreenState();
}

class _EchoScreenState extends ConsumerState<EchoScreen> {
  static const _length = 120;
  int _left = _length;
  int _score = 0;
  int _turn = 0;
  late List<String> _sentences;
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
    final bank = SentenceBank.fromWords(widget.words, maxLength: 20);
    // Spoken-style dialogue lines first: that's how people actually talk.
    _sentences = [
      for (final d in bank.dialogues) ...d.$1.where((l) => l.length <= 20),
      for (final s in bank.sentences) s.$1,
    ]..shuffle();
    if (_sentences.isEmpty) _sentences = [for (final w in widget.words) w.word];
    _bestBefore = ref.read(bestScoresProvider).value?['echo'];
    setState(() {
      _left = _length;
      _score = 0;
      _turn = 0;
      _outcome = null;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _left--);
      if (_left <= 0) _finish();
    });
  }

  Future<void> _answered(bool ok) async {
    if (ok) {
      setState(() => _score++);
      ref.read(soundProvider).play(Sfx.correct);
    }
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted && _outcome == null) setState(() => _turn++);
  }

  Future<void> _finish() async {
    _timer?.cancel();
    if (_outcome != null) return;
    final game = ref.read(gameProvider);
    final outcome = await game.award([
      game.activity(ActivityKind.game, xp: _score * 3, value: _score, ref: 'echo'),
      if (_score > 0) game.activity(ActivityKind.spoken, value: _score),
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
    final speaking = ref.watch(settingsProvider.select((s) => s.speakingExercises));
    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          if (!speaking)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🦜', style: TextStyle(fontSize: 64)),
                  const Text('Echo needs speaking exercises. Turn them on in Me → Settings.', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
                ]),
              ),
            )
          else if (_outcome != null)
            GameOverView(title: 'Echo', score: _score, best: _bestBefore, outcome: _outcome!, onAgain: _start)
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
                      color: _left <= 20 ? Colors.red : Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('⏱ $_left', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 8),
                Text('🦜 Echoed: $_score', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: SpeakView(
                    key: ValueKey(_turn),
                    exercise: SpeakExercise(target: _sentences[_turn % _sentences.length], mode: SpeakMode.shadow),
                    onAnswer: _answered,
                    onSkip: () => setState(() => _turn++),
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
