import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../learn/exercises.dart';
import '../providers.dart';
import '../settings.dart';
import '../speech/speech_match.dart';
import '../speech/speech_service.dart';

/// Say it out loud: big mic button, live transcript, then which syllables were heard right.
///
/// Two tries; "Can't talk now" skips without penalty. If the phone has no speech recognizer,
/// an honest "I said it" button stands in.
class SpeakView extends ConsumerStatefulWidget {
  const SpeakView({super.key, required this.exercise, required this.onAnswer, required this.onSkip});
  final SpeakExercise exercise;
  final void Function(bool correct) onAnswer;
  final VoidCallback onSkip;

  @override
  ConsumerState<SpeakView> createState() => _SpeakViewState();
}

class _SpeakViewState extends ConsumerState<SpeakView> {
  bool _listening = false;
  bool? _available;
  String _transcript = '';
  SpeechMatch? _result;
  int _tries = 0;
  bool _answered = false;
  bool _showText = false;
  late final SpeechService _speech;

  SpeakExercise get e => widget.exercise;

  @override
  void initState() {
    super.initState();
    _showText = e.mode == SpeakMode.readAloud;
    _speech = ref.read(speechProvider);
    _speech.init().then((ok) {
      if (mounted) setState(() => _available = ok);
    });
    if (e.mode == SpeakMode.shadow || (e.mode == SpeakMode.readAloud && ref.read(settingsProvider).autoPlay)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.speak(e.target));
    }
  }

  @override
  void dispose() {
    if (_listening) _speech.stop();
    super.dispose();
  }

  Future<void> _listen() async {
    if (_listening || _answered) return;
    await ref.read(ttsProvider).stop();
    setState(() {
      _listening = true;
      _transcript = '';
      _result = null;
    });
    await _speech.listen(
      onResult: (text, isFinal) {
        if (mounted) setState(() => _transcript = text);
      },
      onDone: _finish,
    );
  }

  void _finish() {
    if (!mounted || !_listening) return;
    final result = matchSpeech(e.target, _transcript);
    setState(() {
      _listening = false;
      _result = result;
      _tries++;
      _showText = true;
    });
    if (result.passed || _tries >= 2) _answer(result.passed);
  }

  void _answer(bool correct) {
    if (_answered) return;
    _answered = true;
    widget.onAnswer(correct);
  }

  String get _instruction => switch (e.mode) {
    SpeakMode.readAloud => 'Read it aloud 🎤',
    SpeakMode.sayIt => 'Say it in Korean 🎤',
    SpeakMode.shadow => 'Listen and repeat 🎤',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final result = _result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_instruction, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Expanded(
          // Centered when there's room, scrollable in a short panel (role-play).
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (e.mode == SpeakMode.sayIt)
                      Text(e.english ?? '', textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
                    if (e.mode == SpeakMode.shadow)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton.filled(
                            iconSize: 36,
                            icon: const Icon(Icons.volume_up_rounded),
                            onPressed: () => ref.speak(e.target),
                          ),
                          const SizedBox(width: 12),
                          IconButton.filledTonal(
                            icon: const Text('🐢', style: TextStyle(fontSize: 22)),
                            onPressed: () => ref.read(ttsProvider).speak(e.target, rate: 0.25),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    if (_showText)
                      result == null
                          ? Text(
                              e.target,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
                            )
                          : Text.rich(
                              TextSpan(
                                children: [
                                  for (final (c, ok) in result.syllables)
                                    TextSpan(
                                      text: c,
                                      style: TextStyle(color: ok ? Colors.green.shade600 : Colors.red.shade600),
                                    ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                            )
                    else
                      TextButton(onPressed: () => setState(() => _showText = true), child: const Text('Show the text')),
                    if (e.mode == SpeakMode.readAloud && e.english != null)
                      Text(
                        e.english!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(color: scheme.outline),
                      ),
                    if (e.mode != SpeakMode.readAloud && !_showText && e.mode == SpeakMode.sayIt)
                      TextButton(onPressed: () => setState(() => _showText = true), child: const Text('Show me')),
                    const SizedBox(height: 16),
                    if (_transcript.isNotEmpty || result != null)
                      Text(
                        result == null
                            ? '“$_transcript”'
                            : 'Heard: “${result.heard.isEmpty ? '…' : result.heard}” · ${result.percent}%',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(color: scheme.outline),
                      ),
                    if (result != null && !result.passed && _tries < 2)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Almost! Listen once more and try again.',
                          style: TextStyle(color: Colors.orange.shade800),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_available == false && !_answered) ...[
          Text(
            'Speech recognition isn\'t available. Install Google speech services / the Korean offline speech pack, or say it to yourself:',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () {
              setState(() => _showText = true);
              _answer(true);
            },
            child: const Text('I said it ✓'),
          ),
        ] else if (!_answered)
          Center(
            child: GestureDetector(
              onTap: _listening ? _speech.stop : _listen,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: _listening ? 104 : 88,
                height: _listening ? 104 : 88,
                decoration: BoxDecoration(
                  color: _listening ? Colors.red : scheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (_listening)
                      BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 24, spreadRadius: 6),
                  ],
                ),
                child: Icon(_listening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 44),
              ),
            ),
          ),
        const SizedBox(height: 8),
        if (!_answered) TextButton(onPressed: widget.onSkip, child: const Text("Can't talk now")),
      ],
    );
  }
}
