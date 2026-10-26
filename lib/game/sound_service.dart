import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

enum Sfx { correct, wrong, combo, complete, levelup, tap, flip }

/// Short sound effects and haptics. Sounds mix with other audio so they never cut off TTS.
class SoundService {
  final Map<Sfx, AudioPlayer> _players = {};
  bool soundOn = true;
  bool hapticsOn = true;
  bool _configured = false;

  Future<void> _configure() async {
    if (_configured) return;
    _configured = true;
    await AudioPlayer.global.setAudioContext(AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build());
  }

  Future<void> play(Sfx sfx) async {
    if (hapticsOn) {
      switch (sfx) {
        case Sfx.correct || Sfx.tap:
          HapticFeedback.selectionClick();
        case Sfx.wrong:
          HapticFeedback.heavyImpact();
        case Sfx.combo || Sfx.complete || Sfx.levelup:
          HapticFeedback.mediumImpact();
        case Sfx.flip:
          break;
      }
    }
    if (!soundOn) return;
    try {
      await _configure();
      final player = _players[sfx] ??= AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
      await player.stop();
      await player.play(AssetSource('sounds/${sfx.name}.wav'));
    } catch (_) {
      // A missing audio device must never break a lesson.
    }
  }
}
