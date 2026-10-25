import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:korean_cards/data/db.dart';
import 'package:korean_cards/data/word_importer.dart';

AppDatabase memoryDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true; // the backup test opens two
  return AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
}

Map<String, dynamic> wordJson(int id, String word, {int rank = 1, String meaning = 'thing'}) => {
      'id': id,
      'word': word,
      'homonym': 0,
      'pos': 'noun',
      'level': '초급',
      'hanja': null,
      'pronunciation': word,
      'category': null,
      'senses': [
        {'meanings': [meaning], 'definition': 'A $meaning.', 'example': '$word 예문.'},
      ],
      'rank': rank,
    };

/// A small deck: 사과 (rank 1), 학교 (rank 2), 물 (rank 3), ...
Future<AppDatabase> seededDb([int count = 5]) async {
  final db = memoryDb();
  const words = ['사과', '학교', '물', '책', '친구', '가게', '사람', '시간'];
  await importWords(db, [for (var i = 0; i < count; i++) wordJson(100 + i, words[i], rank: i + 1)]);
  return db;
}
