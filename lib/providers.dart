import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/db.dart';
import 'services/notification_service.dart';
import 'services/tts_service.dart';
import 'settings.dart';
import 'srs/scheduler.dart';

final dbProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('overridden in main'));
final notificationsProvider = Provider<NotificationService>((ref) => throw UnimplementedError('overridden in main'));

final ttsProvider = Provider<TtsService>((ref) => TtsService());
final schedulerProvider = Provider<Scheduler>((ref) => Scheduler());

final koreanVoiceProvider = FutureProvider<bool>((ref) => ref.watch(ttsProvider).koreanAvailable);

final todayCountsProvider = StreamProvider<TodayCounts>((ref) {
  final s = ref.watch(settingsProvider);
  return ref.watch(dbProvider).watchTodayCounts(newPerDay: s.newPerDay, reverse: s.reverseCards);
});

final overviewProvider = StreamProvider<Overview>((ref) => ref.watch(dbProvider).watchOverview());

/// Speaks Korean text at the user's chosen speed.
extension SpeakWidgetRef on WidgetRef {
  Future<void> speak(String text) => read(ttsProvider).speak(text, rate: read(settingsProvider).speechRate);
}
