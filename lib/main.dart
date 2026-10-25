import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/db.dart';
import 'data/word_importer.dart';
import 'providers.dart';
import 'services/notification_service.dart';
import 'settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase();
  await importBundledWords(db, prefs);

  final notifications = NotificationService();
  await notifications.init();
  final settings = Settings.load(prefs);
  if (settings.reminderEnabled) await notifications.scheduleDaily(settings.reminderTime);

  runApp(ProviderScope(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      dbProvider.overrideWithValue(db),
      notificationsProvider.overrideWithValue(notifications),
    ],
    child: const KoreanCardsApp(),
  ));
}
