import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/db.dart';
import 'game/game_service.dart';
import 'game/sound_service.dart';
import 'learn/curriculum.dart';
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

final gameProvider = Provider<GameService>((ref) => throw UnimplementedError('overridden in main'));

final soundProvider = Provider<SoundService>((ref) {
  final sound = SoundService();
  ref.listen(settingsProvider, (_, s) {
    sound.soundOn = s.soundEffects;
    sound.hapticsOn = s.haptics;
  }, fireImmediately: true);
  return sound;
});

final profileProvider = StreamProvider<Profile>((ref) => ref.watch(gameProvider).watchProfile());

final lessonProgressProvider =
    StreamProvider<Map<String, LessonProgressData>>((ref) => ref.watch(gameProvider).watchLessonProgress());

final curriculumProvider = FutureProvider<List<TopicUnit>>((ref) => loadCurriculum());

/// A topic's words in lesson order (the user's own words go last so lessons never shift).
final unitWordsProvider = StreamProvider.family<List<Word>, String>((ref, unitId) => ref.watch(dbProvider).watchUnitWords(unitId));

final topicLessonsProvider = Provider.family<AsyncValue<List<TopicLesson>>, String>(
  (ref, unitId) => ref.watch(unitWordsProvider(unitId)).whenData((words) => buildTopicLessons(unitId, words)),
);

/// Every word, for wrong answer options and arcade pools.
final allWordsProvider = StreamProvider<List<Word>>((ref) => ref.watch(dbProvider).select(ref.watch(dbProvider).words).watch());

/// Speaks Korean text at the user's chosen speed.
extension SpeakWidgetRef on WidgetRef {
  Future<void> speak(String text) => read(ttsProvider).speak(text, rate: read(settingsProvider).speechRate);
}
