import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../game/game_service.dart';
import '../../grammar/grammar_content.dart';
import '../../learn/curriculum.dart';
import '../../learn/grammar_lesson.dart';
import '../../learn/topic_lesson.dart';
import '../../providers.dart';
import '../../settings.dart';
import '../../widgets/common.dart';
import '../browse/add_word_screen.dart';
import '../study/study_screen.dart';

/// The first unfinished topic lesson, following the curriculum order.
final nextTopicLessonProvider = Provider<(TopicUnit, TopicLesson)?>((ref) {
  final units = ref.watch(curriculumProvider).value;
  final progress = ref.watch(lessonProgressProvider).value;
  if (units == null || progress == null) return null;
  for (final u in units.where((u) => u.id != customUnit)) {
    final lessons = ref.watch(topicLessonsProvider(u.id)).value;
    if (lessons == null) return null;
    for (final l in lessons) {
      if (!progress.containsKey(l.id)) return (u, l);
    }
  }
  return null;
});

final nextGrammarLessonProvider = Provider<GrammarLesson?>((ref) {
  final units = ref.watch(grammarProvider).value;
  final progress = ref.watch(lessonProgressProvider).value;
  if (units == null || progress == null) return null;
  for (final l in units.expand((u) => u.lessons)) {
    if (!progress.containsKey(l.progressId)) return l;
  }
  return null;
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return '좋은 아침이에요!';
    if (h < 18) return '안녕하세요!';
    return '좋은 저녁이에요!';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final hasVoice = ref.watch(koreanVoiceProvider).value ?? true;
    final goal = ref.watch(settingsProvider.select((s) => s.dailyGoal));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('🐯 ${_greeting()}'),
        actions: [
          if (profile != null) ...[
            _Chip(text: '🔥 ${profile.streak.days}${profile.streak.freezes > 0 ? '  🧊${profile.streak.freezes}' : ''}', tooltip: 'Day streak · streak freezes'),
            _Chip(text: '${profile.level.title.emoji} ${profile.level.level}', tooltip: '${profile.level.title.english} · level ${profile.level.level}'),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (!hasVoice) const _NoVoiceBanner(),
          if (profile != null) _GoalCard(profile: profile, goal: goal),
          const SizedBox(height: 12),
          const _ContinueCard(),
          const SizedBox(height: 12),
          const _ReviewCard(),
          const SizedBox(height: 12),
          if (profile != null) _QuestsCard(quests: profile.quests),
          const SizedBox(height: 12),
          const _WordOfTheDay(),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: const Icon(Icons.add),
            label: Text('Add a word of my own', style: theme.textTheme.titleSmall),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddWordScreen())),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.tooltip});
  final String text;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Container(
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(20)),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.profile, required this.goal});
  final Profile profile;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = (profile.todayXp / goal).clamp(0.0, 1.0);
    final met = profile.todayXp >= goal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: fraction),
                  duration: const Duration(milliseconds: 800),
                  builder: (_, v, _) => CircularProgressIndicator(
                    value: v,
                    strokeWidth: 9,
                    strokeCap: StrokeCap.round,
                    color: met ? Colors.amber : Colors.orange,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              Text(met ? '🏅' : '⚡', style: const TextStyle(fontSize: 30)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(met ? 'Daily goal reached! 대박!' : 'Daily goal', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text('${profile.todayXp} / $goal XP today', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: profile.level.progress, minHeight: 6, borderRadius: BorderRadius.circular(3)),
              const SizedBox(height: 2),
              Text(
                'Lv ${profile.level.level} ${profile.level.title.korean} · ${profile.level.xpForLevel - profile.level.xpIntoLevel} XP to level ${profile.level.level + 1}',
                style: theme.textTheme.bodySmall,
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ContinueCard extends ConsumerWidget {
  const _ContinueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topic = ref.watch(nextTopicLessonProvider);
    final grammar = ref.watch(nextGrammarLessonProvider);
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Continue learning', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (topic != null)
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60), alignment: Alignment.centerLeft),
              icon: Text(topic.$1.emoji, style: const TextStyle(fontSize: 26)),
              label: Text('${topic.$1.title} · lesson ${topic.$2.index + 1}', style: const TextStyle(fontSize: 17)),
              onPressed: () => openTopicLesson(context, ref, topic.$2, topic.$1),
            ),
          if (grammar != null) ...[
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), alignment: Alignment.centerLeft),
              icon: const Text('📐', style: TextStyle(fontSize: 24)),
              label: Text('Grammar: ${grammar.title}', style: const TextStyle(fontSize: 16)),
              onPressed: () => openGrammarLesson(context, ref, grammar),
            ),
          ],
        ]),
      ),
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(todayCountsProvider).value;
    if (counts == null) return const SizedBox();
    final theme = Theme.of(context);
    final total = counts.newAvailable + counts.learning + counts.due;
    Widget count(String label, int value, Color color) => Expanded(
          child: Column(children: [
            Text('$value', style: theme.textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
            Text(label, style: theme.textTheme.labelMedium),
          ]),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text('🔁 Flashcard review', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${counts.reviewedToday} done today', style: theme.textTheme.bodySmall),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            count('New', counts.newAvailable, theme.colorScheme.primary),
            count('Learning', counts.learning, Colors.orange),
            count('Review', counts.due, Colors.green),
          ]),
          const SizedBox(height: 12),
          if (total > 0)
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('Review $total cards'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudyScreen(), fullscreenDialog: true)),
            )
          else
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('All caught up 🎉 · learn 5 more'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudyScreen(extraNew: 5), fullscreenDialog: true)),
            ),
        ]),
      ),
    );
  }
}

class _QuestsCard extends StatelessWidget {
  const _QuestsCard({required this.quests});
  final List<QuestStatus> quests;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allDone = quests.every((q) => q.done);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Daily quests', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(allDone ? '🎁 Chest opened!' : '🎁 Finish all 3 for a bonus', style: theme.textTheme.bodySmall),
          ]),
          const SizedBox(height: 8),
          for (final q in quests)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Text(q.quest.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(q.quest.title, style: TextStyle(decoration: q.done ? TextDecoration.lineThrough : null)),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: q.done ? 1 : q.fraction,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                      color: q.done ? Colors.green : Colors.amber,
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                q.done
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : Text('${q.progress.clamp(0, q.quest.target)}/${q.quest.target}', style: theme.textTheme.bodySmall),
              ]),
            ),
        ]),
      ),
    );
  }
}

/// One word a day from the words learned so far (or the most common ones), same all day.
class _WordOfTheDay extends ConsumerWidget {
  const _WordOfTheDay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final words = ref.watch(allWordsProvider).value;
    final learned = ref.watch(learnedWordIdsProvider).value ?? const {};
    if (words == null || words.isEmpty) return const SizedBox();
    var pool = words.where((w) => learned.contains(w.id)).toList();
    if (pool.length < 10) pool = (words.toList()..sort((a, b) => a.rank.compareTo(b.rank))).take(300).toList();
    final day = studyDayStart(DateTime.now());
    final w = pool[(day.year * 400 + day.month * 31 + day.day) % pool.length];
    final theme = Theme.of(context);
    final example = w.senseList.firstOrNull?.example;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('✨ Word of the day', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Row(children: [
            Text(w.word, style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
            SpeakButton(w.word),
            const Spacer(),
            TagChip(w.pos),
          ]),
          Text(w.gloss, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
          if (example != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: Text(example, style: const TextStyle(fontStyle: FontStyle.italic))),
              SpeakButton(example, size: 22),
            ]),
          ],
        ]),
      ),
    );
  }
}

class _NoVoiceBanner extends StatelessWidget {
  const _NoVoiceBanner();

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.errorContainer,
        margin: const EdgeInsets.only(bottom: 12),
        child: const ListTile(
          leading: Icon(Icons.volume_off),
          title: Text('No Korean voice installed'),
          subtitle: Text(
            'To hear words, open Android Settings → System → Languages → Text-to-speech output → '
            'Google → Install voice data → Korean, then restart the app.',
          ),
        ),
      );
}
