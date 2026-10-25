import 'package:flutter_tts/flutter_tts.dart';

/// Korean speech through the phone's text-to-speech engine (Google TTS on most Androids).
class TtsService {
  final FlutterTts _tts = FlutterTts();
  Future<bool>? _ready;

  Future<bool> _init() async {
    final available = await _tts.isLanguageAvailable('ko-KR') == true;
    if (available) await _tts.setLanguage('ko-KR');
    await _tts.setQueueMode(0); // flush: a new word interrupts the previous one
    return available;
  }

  /// Whether a Korean voice is installed. If not, the user must add it in Android's TTS settings.
  Future<bool> get koreanAvailable => _ready ??= _init();

  Future<void> speak(String text, {required double rate}) async {
    if (!await koreanAvailable) return;
    await _tts.setSpeechRate(rate);
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}
