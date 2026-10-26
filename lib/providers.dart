import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/db.dart';
import 'dictionary/dictionary_service.dart';
import 'game/game_service.dart';
import 'game/sound_service.dart';
import 'grammar/sentence_gen.dart';
import 'learn/curriculum.dart';
import 'learn/mistakes.dart';
import 'learn/skill_service.dart';
import 'services/notification_service.dart';
import 'services/tts_service.dart';
import 'speech/speech_service.dart';
import 'settings.dart';
import 'srs/scheduler.dart';

final dbProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('overridden in main'));
final notificationsProvider = Provider<NotificationService>((ref) => throw UnimplementedError('overridden in main'));

final ttsProvider = Provider<TtsService>((ref) => TtsService());
final speechProvider = Provider<SpeechService>((ref) => DeviceSpeechService());
final schedulerProvider = Provider<Scheduler>((ref) => Scheduler());

final koreanVoiceProvider = FutureProvider<bool>((ref) => ref.watch(ttsProvider).koreanAvailable);

final learnedBeginnerProvider = StreamProvider<int>((ref) => ref.watch(dbProvider).watchLearnedBeginnerCount());

/// Whether new flashcards include 중급 words: switched on, or 1,500 beginner words learned.
final intermediateOnProvider = Provider<bool>((ref) =>
    ref.watch(settingsProvider.select((s) => s.intermediate)) ||
    (ref.watch(learnedBeginnerProvider).value ?? 0) >= intermediateUnlockAt);

final todayCountsProvider = StreamProvider<TodayCounts>((ref) {
  final s = ref.watch(settingsProvider);
  return ref.watch(dbProvider).watchTodayCounts(newPerDay: s.newPerDay, reverse: s.reverseCards, intermediate: ref.watch(intermediateOnProvider));
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

final skillServiceProvider = Provider<SkillService>((ref) => SkillService(ref.watch(dbProvider), ref.watch(schedulerProvider)));
final skillRowsProvider = StreamProvider<Map<String, SkillRow>>((ref) => ref.watch(skillServiceProvider).watch());

final mistakeServiceProvider = Provider<MistakeService>((ref) => MistakeService(ref.watch(dbProvider)));
final openMistakesProvider = StreamProvider<List<Mistake>>((ref) => ref.watch(mistakeServiceProvider).watchOpen());

final dictionaryProvider = Provider<DictionaryService>((ref) => DictionaryService(ref.watch(dbProvider), ref.watch(prefsProvider)));

final framesProvider = FutureProvider<Frames>((ref) => Frames.load());

/// Builds particle and tense practice from the sentence frames and the word list.
final sentenceGenProvider = FutureProvider<SentenceGenerator>(
  (ref) async => SentenceGenerator(await ref.watch(framesProvider.future), await ref.watch(allWordsProvider.future)),
);

/// Speaks Korean text at the user's chosen speed.
extension SpeakWidgetRef on WidgetRef {
  Future<void> speak(String text) => read(ttsProvider).speak(text, rate: read(settingsProvider).speechRate);
}
