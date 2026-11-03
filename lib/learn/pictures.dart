import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emoji per word id for words that are easy to picture (built by tools/build_pictures.py).
Map<int, String> parsePictures(String raw) => {
      for (final p in (jsonDecode(raw)['pictures'] as List).cast<Map<String, dynamic>>()) p['id'] as int: p['emoji'] as String,
    };

Future<Map<int, String>> loadPictures([AssetBundle? bundle]) async =>
    parsePictures(await (bundle ?? rootBundle).loadString('assets/data/pictures.json'));

final picturesProvider = FutureProvider<Map<int, String>>((ref) => loadPictures());
