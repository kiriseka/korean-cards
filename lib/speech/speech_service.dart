import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'listen_policy.dart';

/// Korean speech recognition. An interface so tests (and phones without a recognizer) can swap it.
abstract class SpeechService {
  /// Asks for the microphone the first time; false if speech recognition can't be used.
  Future<bool> init();

  /// Listens for one answer. [onResult] gets the transcript so far, then the final one;
  /// [onDone] fires once listening ends (the user stopped, they went quiet, or an error).
  Future<void> listen({required void Function(String text, bool isFinal) onResult, required void Function() onDone});

  Future<void> stop();
}

/// One answer, which may span several recognizer sessions.
class _Take {
  _Take(this.onResult, this.onDone, this.started);
  final void Function(String text, bool isFinal) onResult;
  final void Function() onDone;
  final DateTime started;

  /// Words heard by each recognizer session, in order. A late result only rewrites its own slot.
  final List<String> segments = [];
  DateTime? lastHeard;
  bool stopping = false;
  Timer? ticker;
  Timer? restart;
  Timer? safety;

  String get text => segments.where((s) => s.isNotEmpty).join(' ');
}

class DeviceSpeechService implements SpeechService {
  DeviceSpeechService({this.policy = const ListenPolicy()});

  final ListenPolicy policy;
  final SpeechToText _stt = SpeechToText();
  Future<bool>? _ready;
  String _locale = 'ko_KR';
  _Take? _take;

  /// Recognizer errors that only mean "no words this time" (a pause, or not started yet).
  static const _quietErrors = {'error_no_match', 'error_speech_timeout', 'error_busy', 'error_client'};

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
    if (status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) _sessionEnded();
  }

  void _error(SpeechRecognitionError error) {
    if (_quietErrors.contains(error.errorMsg)) {
      _sessionEnded();
    } else {
      _finish();
    }
  }

  @override
  Future<void> listen({required void Function(String text, bool isFinal) onResult, required void Function() onDone}) async {
    if (!await init()) {
      onDone();
      return;
    }
    _finish();
    final take = _Take(onResult, onDone, DateTime.now());
    _take = take;
    take.ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (policy.shouldStop(started: take.started, lastHeard: take.lastHeard, now: DateTime.now())) _wrapUp(take);
    });
    await _startSession(take);
  }

  Future<void> _startSession(_Take take) async {
    if (_take != take || take.stopping) return;
    final slot = take.segments.length;
    take.segments.add('');
    try {
      // No pauseFor: the plugin would time it from the start, before the learner speaks.
      await _stt.listen(
        onResult: (r) => _heard(take, slot, r.recognizedWords),
        listenOptions: SpeechListenOptions(
          localeId: _locale,
          partialResults: true,
          cancelOnError: true,
          listenFor: policy.maxTake,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (_) {
      // The recognizer wasn't ready; the next status or the policy's timer moves things on.
    }
  }

  void _heard(_Take take, int slot, String words) {
    if (_take != take || words == take.segments[slot]) return;
    take.segments[slot] = words;
    if (words.isNotEmpty) take.lastHeard = DateTime.now();
    take.onResult(take.text, false);
  }

  /// The recognizer stopped by itself. Keep listening unless the take is over.
  void _sessionEnded() {
    final take = _take;
    if (take == null || take.restart != null || _stt.isListening) return;
    if (take.stopping || policy.shouldStop(started: take.started, lastHeard: take.lastHeard, now: DateTime.now())) {
      _finish();
      return;
    }
    take.restart = Timer(const Duration(milliseconds: 150), () {
      take.restart = null;
      _startSession(take);
    });
  }

  /// Asks the recognizer for its last words, then finishes (or after a moment, if it doesn't answer).
  void _wrapUp(_Take take) {
    if (_take != take || take.stopping) return;
    take.stopping = true;
    take.ticker?.cancel();
    take.restart?.cancel();
    take.restart = null;
    if (!_stt.isListening) {
      _finish();
      return;
    }
    take.safety = Timer(const Duration(milliseconds: 800), _finish);
    _stt.stop();
  }

  void _finish() {
    final take = _take;
    if (take == null) return;
    _take = null;
    take.ticker?.cancel();
    take.restart?.cancel();
    take.safety?.cancel();
    if (_stt.isListening) _stt.cancel();
    take.onResult(take.text, true);
    take.onDone();
  }

  @override
  Future<void> stop() async {
    final take = _take;
    if (take != null) _wrapUp(take);
  }
}
