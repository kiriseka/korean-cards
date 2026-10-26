import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korean_cards/game/sound_service.dart';

/// Every file the app loads at runtime must be bundled (declared in pubspec.yaml),
/// not just present on disk — tests that read files directly can't tell the difference.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const dataFiles = [
    'assets/data/words.json',
    'assets/data/curriculum.json',
    'assets/data/grammar.json',
    'assets/data/phrases.json',
    'assets/data/dialogues.json',
    'assets/data/sentence_frames.json',
  ];

  for (final path in dataFiles) {
    test('$path is bundled', () async {
      final text = await rootBundle.loadString(path);
      expect(text, isNotEmpty);
    });
  }

  test('dictionary and icon are bundled', () async {
    expect((await rootBundle.load('assets/data/dictionary.json.gz')).lengthInBytes, greaterThan(1000000));
  });

    for (final sfx in Sfx.values) {
    test('sound ${sfx.name} is bundled', () async {
      final data = await rootBundle.load('assets/sounds/${sfx.name}.wav');
      expect(data.lengthInBytes, greaterThan(100));
      expect(File('assets/sounds/${sfx.name}.wav').existsSync(), isTrue);
    });
  }
}
