import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Korean speech recognition. An interface so tests (and phones without a recognizer) can swap it.
abstract class SpeechService {
  /// Asks for the microphone the first time; false if speech recognition can't be used.
  Future<bool> init();

  /// Listens for one utterance. [onResult] gets partial transcripts, then the final one;
  /// [onDone] fires once listening ends (also after silence or an error).
  Future<void> listen({required void Function(String text, bool isFinal) onResult, required void Function() onDone});

  Future<void> stop();
}

class DeviceSpeechService implements SpeechService {
  final SpeechToText _stt = SpeechToText();
  Future<bool>? _ready;
  String _locale = 'ko_KR';
  void Function()? _onDone;

  @override
  Future<bool> init() => _ready ??= _init();

  Future<bool> _init() async {
    try {
      final ok = await _stt.initialize(onStatus: _status, onError: _error);
      if (!ok) return false;
      final korean = (await _stt.locales()).where((l) => l.localeId.toLowerCase().startsWith('ko'));
      if (korean.isNotEmpty) _locale = korean.first.localeId;
      return true;
    } catch (_) {
      return false;
    }
  }

  void _status(String status) {
    if (status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) _finish();
  }

  void _error(SpeechRecognitionError error) => _finish();

  void _finish() {
    final done = _onDone;
    _onDone = null;
    done?.call();
  }

  @override
  Future<void> listen({required void Function(String text, bool isFinal) onResult, required void Function() onDone}) async {
    if (!await init()) {
      onDone();
      return;
    }
    _onDone = onDone;
    await _stt.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenOptions: SpeechListenOptions(
        localeId: _locale,
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 2),
        listenMode: ListenMode.dictation,
      ),
    );
  }

  @override
  Future<void> stop() => _stt.stop();
}
