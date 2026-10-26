import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_service.dart';
import '../game/sound_service.dart';
import '../games/exercise_views.dart';
import '../providers.dart';
import 'exercises.dart';
import 'session.dart';

const _praise = ['잘했어요!', '맞아요!', '대박!', '완벽해요!', '최고예요!', '좋아요!', '멋져요!'];
const _comfort = ['아쉬워요…', '괜찮아요!', '다시 해 봐요!'];

/// Runs a lesson: optional intro (meet the words / learn the grammar), the exercises, then results.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({
    super.key,
    required this.title,
    required this.exercises,
    required this.onComplete,
    this.intro,
    this.hearts,
  });

  final String title;
  final List<Exercise> exercises;

  /// Records progress and XP once the lesson ends (also when a challenge runs out of hearts).
  final Future<AwardOutcome> Function(ExerciseSession session) onComplete;
  final Widget Function(BuildContext context, VoidCallback start)? intro;
  final int? hearts;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

enum _Phase { intro, practice, results }

class _LessonScreenState extends ConsumerState<LessonScreen> {
  late final ExerciseSession _session;
  late _Phase _phase;
  AwardOutcome? _outcome;
  final _confetti = ConfettiController(duration: const Duration(seconds: 2));
  final _rng = Random();
  String _message = '';
  int _turn = 0;

  @override
  void initState() {
    super.initState();
    _session = ExerciseSession(widget.exercises, hearts: widget.hearts, retryMistakes: widget.hearts == null);
    _phase = widget.intro == null ? _Phase.practice : _Phase.intro;
  }

  @override
  void dispose() {
    _confetti.dispose();
    _session.dispose();
    super.dispose();
  }

  void _onAnswer(bool correct) {
    _session.answer(correct);
    final sound = ref.read(soundProvider);
    if (correct) {
      sound.play(_session.combo > 0 && _session.combo % 5 == 0 ? Sfx.combo : Sfx.correct);
      _message = _session.combo >= 5 ? '대박! 🔥 ${_session.combo} in a row' : _praise[_rng.nextInt(_praise.length)];
    } else {
      sound.play(Sfx.wrong);
      _message = _comfort[_rng.nextInt(_comfort.length)];
    }
    setState(() {});
  }

  /// "Can't talk now": move on without judging the exercise.
  Future<void> _skip() async {
    _session.skip();
    await _afterStep();
  }

  Future<void> _continue() async {
    _session.next();
    await _afterStep();
  }

  Future<void> _afterStep() async {
    _turn++;
    if (_session.finished) {
      final outcome = await widget.onComplete(_session);
      if (!mounted) return;
      setState(() {
        _outcome = outcome;
        _phase = _Phase.results;
      });
      if (!_session.failed) {
        ref.read(soundProvider).play(Sfx.complete);
        _confetti.play();
      }
    } else {
      setState(() {});
    }
  }

  Future<bool> _confirmQuit() async {
    if (_phase != _Phase.practice) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quit this lesson?'),
            content: const Text("You'll lose this lesson's progress."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Quit')),
              FilledButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep going')),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _phase != _Phase.practice,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmQuit() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              switch (_phase) {
                _Phase.intro => widget.intro!(context, () => setState(() => _phase = _Phase.practice)),
                _Phase.practice => _practice(context),
                _Phase.results => _ResultsView(session: _session, outcome: _outcome!, title: widget.title),
              },
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  numberOfParticles: 30,
                  gravity: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _practice(BuildContext context) {
    final ex = _session.current;
    final answered = _session.lastCorrect != null;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  if (await _confirmQuit() && context.mounted) Navigator.of(context).pop();
                },
              ),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: _session.progress),
                  duration: const Duration(milliseconds: 400),
                  builder: (_, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 14,
                    borderRadius: BorderRadius.circular(7),
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (widget.hearts != null)
                Text('❤️ ${_session.heartsLeft}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
              else
                _ComboBadge(combo: _session.combo),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: ex == null
                ? const SizedBox()
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => SlideTransition(
                      position: Tween(begin: const Offset(0.15, 0), end: Offset.zero).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_turn),
                      child: ExerciseView(exercise: ex, onAnswer: _onAnswer, onSkip: _skip),
                    ),
                  ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: answered ? _FeedbackBar(session: _session, exercise: ex!, message: _message, onContinue: _continue) : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _ComboBadge extends StatelessWidget {
  const _ComboBadge({required this.combo});
  final int combo;

  @override
  Widget build(BuildContext context) {
    final flames = combo >= 15 ? '🔥🔥🔥' : combo >= 8 ? '🔥🔥' : '🔥';
    return AnimatedScale(
      scale: combo >= 3 ? 1 : 0.6,
      duration: const Duration(milliseconds: 200),
      child: AnimatedOpacity(
        opacity: combo >= 3 ? 1 : 0.3,
        duration: const Duration(milliseconds: 200),
        child: Text('$flames $combo', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
      ),
    );
  }
}

class _FeedbackBar extends StatelessWidget {
  const _FeedbackBar({required this.session, required this.exercise, required this.message, required this.onContinue});
  final ExerciseSession session;
  final Exercise exercise;
  final String message;
  final VoidCallback onContinue;

  String? get _correctAnswer => switch (exercise) {
        final ChoiceExercise e => e.correct,
        final SyllableExercise e => e.answer,
        final TypingExercise e => e.answer,
        final SentenceExercise e => e.sentence,
        final SpeakExercise e => e.target,
        final DictationExercise e => e.sentence,
        MatchExercise() => null,
      };

  String? get _explanation => switch (exercise) {
        final ChoiceExercise e => e.explanation,
        final SentenceExercise e => e.explanation,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final ok = session.lastCorrect!;
    final color = ok ? Colors.green : Colors.red;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      color: color.withValues(alpha: 0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(ok ? '🐯' : '😿', style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message, style: theme.textTheme.titleLarge?.copyWith(color: color.shade800, fontWeight: FontWeight.bold)),
              ),
              if (ok && session.lastXp > 0)
                Text('+${session.lastXp} XP', style: TextStyle(color: color.shade800, fontWeight: FontWeight.bold)),
            ],
          ),
          if (!ok && _correctAnswer != null) ...[
            const SizedBox(height: 6),
            Text('Correct answer:', style: TextStyle(color: color.shade800)),
            Text(_correctAnswer!, style: theme.textTheme.titleMedium?.copyWith(color: color.shade900, fontWeight: FontWeight.bold)),
          ],
          if (_explanation != null) ...[
            const SizedBox(height: 6),
            Text(_explanation!, style: TextStyle(color: color.shade900)),
          ],
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: color, minimumSize: const Size.fromHeight(52)),
            onPressed: onContinue,
            child: const Text('Continue', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.session, required this.outcome, required this.title});
  final ExerciseSession session;
  final AwardOutcome outcome;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failed = session.failed;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Text(failed ? '😿' : session.perfect ? '🐯✨' : '🐯', style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 8),
          Text(failed ? '다음에 다시 해요!' : session.perfect ? '완벽해요!' : '수고했어요!',
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(failed ? 'Out of hearts — practise a bit and try again' : '$title complete',
              textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          const SizedBox(height: 24),
          if (!failed)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 400 + 250 * i),
                    curve: Curves.elasticOut,
                    builder: (_, v, child) => Transform.scale(scale: v, child: child),
                    child: Icon(Icons.star_rounded, size: 64, color: i < session.stars ? Colors.amber : theme.colorScheme.surfaceContainerHighest),
                  ),
              ],
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              _Stat(label: 'XP', value: '+${outcome.xp}', color: Colors.amber.shade700),
              _Stat(label: 'Accuracy', value: '${(session.accuracy * 100).round()}%', color: Colors.green),
              _Stat(label: 'Best combo', value: '🔥 ${session.bestCombo}', color: Colors.deepOrange),
            ],
          ),
          const SizedBox(height: 16),
          for (final b in outcome.badges)
            ListTile(leading: Text(b.emoji, style: const TextStyle(fontSize: 28)), title: Text('New badge: ${b.title}'), subtitle: Text(b.description)),
          for (final q in outcome.quests)
            ListTile(
              leading: Text(q.quest?.emoji ?? '🎁', style: const TextStyle(fontSize: 28)),
              title: Text(q.quest == null ? 'All quests done!' : 'Quest complete: ${q.quest!.title}'),
              trailing: Text('+${q.xp} XP'),
            ),
          const Spacer(),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card.outlined(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color, width: 2)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(children: [
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      );
}
