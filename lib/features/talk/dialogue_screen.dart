import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../game/game_service.dart';
import '../../game/rules.dart';
import '../../game/sound_service.dart';
import '../../games/speak_view.dart';
import '../../learn/exercises.dart';
import '../../learn/topic_lesson.dart';
import '../../providers.dart';
import '../../services/tts_service.dart';
import '../../settings.dart';
import '../../talk/dialogue.dart';

enum _Step { listen, understand, shadow, rolePlay, results }

/// One conversation scene: listen → understand → shadow your lines → role-play → results.
class DialogueScreen extends ConsumerStatefulWidget {
  const DialogueScreen({super.key, required this.scene});
  final Scene scene;

  @override
  ConsumerState<DialogueScreen> createState() => _DialogueScreenState();
}

class _DialogueScreenState extends ConsumerState<DialogueScreen> {
  _Step _step = _Step.listen;
  late final TtsService _tts;
  late final bool _speaking;
  final _confetti = ConfettiController(duration: const Duration(seconds: 2));

  // Listen step
  int? _playing;
  bool _showText = true;
  int _playToken = 0;

  // Shadow step
  int _shadowIndex = 0;
  bool _shadowAnswered = false;
  int _shadowPassed = 0;

  // Role-play step
  int _line = 0;
  bool _turnAnswered = false;
  int _rolePassed = 0;
  int _spoken = 0;
  AwardOutcome? _outcome;

  Scene get scene => widget.scene;

  @override
  void initState() {
    super.initState();
    _tts = ref.read(ttsProvider);
    _speaking = ref.read(settingsProvider).speakingExercises;
    WidgetsBinding.instance.addPostFrameCallback((_) => _playAll());
  }

  @override
  void dispose() {
    _playToken++;
    _tts.stop();
    _confetti.dispose();
    super.dispose();
  }

  double get _rate => ref.read(settingsProvider).speechRate;

  Future<void> _say(DialogueLine l) => _tts.speak(l.ko, rate: _rate, pitch: l.isYou ? youPitch : partnerPitch);

  Future<void> _playAll() async {
    final token = ++_playToken;
    for (var i = 0; i < scene.lines.length; i++) {
      if (!mounted || token != _playToken) return;
      setState(() => _playing = i);
      await _say(scene.lines[i]);
      await Future.delayed(const Duration(milliseconds: 350));
    }
    if (mounted && token == _playToken) setState(() => _playing = null);
  }

  void _goTo(_Step step) {
    _playToken++;
    _tts.stop();
    setState(() => _step = step);
    if (step == _Step.rolePlay) _advanceRolePlay();
  }

  // ---- Role-play ----------------------------------------------------------------

  /// Plays partner lines until it's your turn (or the scene ends).
  Future<void> _advanceRolePlay() async {
    final token = ++_playToken;
    while (mounted && token == _playToken && _line < scene.lines.length && !scene.lines[_line].isYou) {
      await _say(scene.lines[_line]);
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted || token != _playToken) return;
      setState(() => _line++);
    }
    if (mounted && _line >= scene.lines.length) _finish();
  }

  void _yourTurnDone(bool passed) {
    if (passed) _rolePassed++;
    if (passed && _speaking) _spoken++;
    setState(() => _turnAnswered = true);
  }

  void _nextTurn() {
    setState(() {
      _turnAnswered = false;
      _line++;
    });
    _advanceRolePlay();
  }

  Future<void> _finish() async {
    final yours = scene.yourLines.length;
    final ratio = yours == 0 ? 1.0 : _rolePassed / yours;
    final stars = ratio >= 0.9 ? 3 : ratio >= 0.6 ? 2 : 1;
    final game = ref.read(gameProvider);
    await game.recordLesson(scene.progressId, stars: stars, accuracy: ratio);
    await markWordsLearned(ref, scene.phraseIds);
    final xp = _rolePassed * 5 + _shadowPassed * 3 + Xp.lesson;
    final outcome = await game.award([
      game.activity(ActivityKind.dialogue, xp: xp, value: (ratio * 100).round(), ref: scene.id),
      if (_spoken > 0) game.activity(ActivityKind.spoken, value: _spoken),
    ]);
    if (!mounted) return;
    setState(() {
      _outcome = outcome;
      _step = _Step.results;
    });
    ref.read(soundProvider).play(Sfx.complete);
    if (stars >= 2) _confetti.play();
  }

  // ---- UI ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final steps = [_Step.listen, _Step.understand, if (_speaking) _Step.shadow, _Step.rolePlay];
    return Scaffold(
      appBar: AppBar(
        title: Text('${scene.emoji} ${scene.title}'),
        bottom: _step == _Step.results
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(32),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Row(
                    children: [
                      for (final s in steps)
                        Expanded(
                          child: Column(children: [
                            Text(
                              _stepLabel(s),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, fontWeight: s == _step ? FontWeight.bold : null),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: s.index <= _step.index ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ]),
                        ),
                    ],
                  ),
                ),
              ),
      ),
      body: SafeArea(
        child: Stack(children: [
          switch (_step) {
            _Step.listen => _listenView(context, showEnglish: false),
            _Step.understand => _listenView(context, showEnglish: true),
            _Step.shadow => _shadowView(context),
            _Step.rolePlay => _rolePlayView(context),
            _Step.results => _resultsView(context),
          },
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(confettiController: _confetti, blastDirectionality: BlastDirectionality.explosive, numberOfParticles: 30),
          ),
        ]),
      ),
    );
  }

  String _stepLabel(_Step s) => switch (s) {
        _Step.listen => '1 Listen',
        _Step.understand => '2 Understand',
        _Step.shadow => '3 Shadow',
        _Step.rolePlay => _speaking ? '4 Role-play' : '3 Role-play',
        _Step.results => '',
      };

  Widget _bubble(BuildContext context, DialogueLine l, {bool highlight = false, bool showKorean = true, bool showEnglish = false}) {
    final scheme = Theme.of(context).colorScheme;
    final mine = l.isYou;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!mine) const Text('🧑', style: TextStyle(fontSize: 26)),
            Flexible(
              child: GestureDetector(
                onTap: () => _say(l),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  constraints: const BoxConstraints(maxWidth: 290),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: mine ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(18),
                    border: highlight ? Border.all(color: Colors.amber, width: 3) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(showKorean ? l.ko : '• • •', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      if (showEnglish) Text(l.en, style: TextStyle(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ),
            if (mine) const Text('🙋', style: TextStyle(fontSize: 26)),
          ],
        ),
      ),
    );
  }

  Widget _listenView(BuildContext context, {required bool showEnglish}) {
    final theme = Theme.of(context);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Text(
          showEnglish ? 'Tap any line to hear it again.' : 'Listen to the whole conversation. You are 🙋 Alex; ${scene.partner} is 🧑.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
      if (!showEnglish)
        SwitchListTile(
          dense: true,
          title: const Text('Show Korean text'),
          value: _showText,
          onChanged: (v) => setState(() => _showText = v),
        ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final (i, l) in scene.lines.indexed)
              _bubble(context, l, highlight: _playing == i, showKorean: showEnglish || _showText, showEnglish: showEnglish),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.replay),
            label: const Text('Play all'),
            onPressed: _playAll,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: () => _goTo(showEnglish ? (_speaking ? _Step.shadow : _Step.rolePlay) : _Step.understand),
              child: const Text('Next', style: TextStyle(fontSize: 17)),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _shadowView(BuildContext context) {
    final yours = scene.yourLines;
    final line = yours[_shadowIndex];
    final last = _shadowIndex == yours.length - 1;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Text('Your lines · ${_shadowIndex + 1}/${yours.length}', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Expanded(
          child: SpeakView(
            key: ValueKey('shadow$_shadowIndex'),
            exercise: SpeakExercise(target: line.ko, mode: SpeakMode.shadow, english: line.en),
            onAnswer: (ok) {
              if (ok) {
                _shadowPassed++;
                _spoken++;
              }
              ref.read(soundProvider).play(ok ? Sfx.correct : Sfx.wrong);
              setState(() => _shadowAnswered = true);
            },
            onSkip: () => setState(() => _shadowAnswered = true),
          ),
        ),
        if (_shadowAnswered)
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () {
              if (last) {
                _goTo(_Step.rolePlay);
              } else {
                setState(() {
                  _shadowIndex++;
                  _shadowAnswered = false;
                });
              }
            },
            child: Text(last ? 'Start the role-play 🎭' : 'Next line', style: const TextStyle(fontSize: 17)),
          ),
      ]),
    );
  }

  Widget _rolePlayView(BuildContext context) {
    final done = scene.lines.take(_line).toList();
    final current = _line < scene.lines.length ? scene.lines[_line] : null;
    final yourTurn = current != null && current.isYou;
    return Column(children: [
      Expanded(
        flex: 2,
        child: ListView(
          reverse: true,
          padding: const EdgeInsets.all(12),
          children: [
            if (yourTurn && _turnAnswered) _bubble(context, current),
            for (final l in done.reversed) _bubble(context, l),
          ],
        ),
      ),
      if (yourTurn)
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow),
            child: Column(children: [
              Expanded(
                child: _speaking
                    ? SpeakView(
                        key: ValueKey('turn$_line'),
                        exercise: SpeakExercise(target: current.ko, mode: SpeakMode.sayIt, english: current.en),
                        onAnswer: (ok) {
                          ref.read(soundProvider).play(ok ? Sfx.correct : Sfx.wrong);
                          _yourTurnDone(ok);
                        },
                        onSkip: () => _yourTurnDone(false),
                      )
                    : _ChooseLine(key: ValueKey('choose$_line'), scene: scene, line: current, onAnswer: _yourTurnDone),
              ),
              if (_turnAnswered)
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: _nextTurn,
                  child: const Text('Continue', style: TextStyle(fontSize: 17)),
                ),
            ]),
          ),
        )
      else
        const Padding(padding: EdgeInsets.all(24), child: Text('🧑 …')),
    ]);
  }

  Widget _resultsView(BuildContext context) {
    final theme = Theme.of(context);
    final yours = scene.yourLines.length;
    final ratio = yours == 0 ? 1.0 : _rolePassed / yours;
    final stars = ratio >= 0.9 ? 3 : ratio >= 0.6 ? 2 : 1;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const Spacer(),
        const Text('🎭', style: TextStyle(fontSize: 72)),
        Text(stars == 3 ? '완벽해요!' : '잘했어요!', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text('You said $_rolePassed of $yours lines', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < 3; i++) Icon(Icons.star_rounded, size: 56, color: i < stars ? Colors.amber : theme.colorScheme.surfaceContainerHighest),
        ]),
        const SizedBox(height: 12),
        if (_outcome != null) Text('+${_outcome!.xp} XP', style: TextStyle(fontSize: 22, color: Colors.amber.shade800, fontWeight: FontWeight.bold)),
        if (scene.phraseIds.isNotEmpty) const Text('Key phrases from this scene are now in your flashcards.'),
        for (final b in _outcome?.badges ?? const []) ListTile(leading: Text(b.emoji, style: const TextStyle(fontSize: 28)), title: Text('New badge: ${b.title}')),
        const Spacer(),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Continue', style: TextStyle(fontSize: 18)),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _line = 0;
              _rolePassed = 0;
              _turnAnswered = false;
            });
            _goTo(_Step.rolePlay);
          },
          child: const Text('Role-play again'),
        ),
      ]),
    );
  }
}

/// Without the microphone: pick what you'd say.
class _ChooseLine extends StatefulWidget {
  const _ChooseLine({super.key, required this.scene, required this.line, required this.onAnswer});
  final Scene scene;
  final DialogueLine line;
  final void Function(bool) onAnswer;

  @override
  State<_ChooseLine> createState() => _ChooseLineState();
}

class _ChooseLineState extends State<_ChooseLine> {
  late final List<String> _options;
  String? _picked;

  @override
  void initState() {
    super.initState();
    final others = widget.scene.lines.where((l) => l.isYou && l.ko != widget.line.ko).map((l) => l.ko).toList()..shuffle();
    _options = [widget.line.ko, ...others.take(2)]..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('What do you say? · ${widget.line.en}', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      for (final o in _options)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(14),
              backgroundColor: _picked == null
                  ? null
                  : o == widget.line.ko
                      ? Colors.green.shade100
                      : o == _picked
                          ? Colors.red.shade100
                          : null,
            ),
            onPressed: _picked != null
                ? null
                : () {
                    setState(() => _picked = o);
                    widget.onAnswer(o == widget.line.ko);
                  },
            child: Text(o, style: const TextStyle(fontSize: 17)),
          ),
        ),
    ]);
  }
}
