import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/open_db.dart';
import 'data/word_importer.dart';
import 'game/game_service.dart';
import 'grammar/grammar_content.dart';
import 'providers.dart';
import 'services/notification_service.dart';
import 'settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final db = openAppDatabase();
  await importBundledWords(db, prefs);
  final grammar = await loadGrammar();
  final game = GameService(db, grammarUnits: {
    for (final u in grammar) u.id: [for (final l in u.lessons) l.progressId],
  });

  final notifications = NotificationService();
  await notifications.init();
  final settings = Settings.load(prefs);
  if (settings.reminderEnabled) await notifications.scheduleDaily(settings.reminderTime);

  runApp(ProviderScope(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      dbProvider.overrideWithValue(db),
      notificationsProvider.overrideWithValue(notifications),
      gameProvider.overrideWithValue(game),
    ],
    child: const KoreanCardsApp(),
  ));
}
