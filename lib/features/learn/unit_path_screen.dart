import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../learn/curriculum.dart';
import '../../learn/topic_lesson.dart';
import '../../providers.dart';
import '../browse/add_word_screen.dart';
import 'path_widgets.dart';

class UnitPathScreen extends ConsumerWidget {
  const UnitPathScreen({super.key, required this.unit});
  final TopicUnit unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(topicLessonsProvider(unit.id));
    final progress = ref.watch(lessonProgressProvider).value ?? const {};
    return Scaffold(
      appBar: AppBar(title: Text('${unit.emoji}  ${unit.title}')),
      floatingActionButton: unit.id == customUnit
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Add word'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddWordScreen())),
            )
          : null,
      body: lessons.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (lessons) {
          if (lessons.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Add your own words and they become lessons here. ✏️', textAlign: TextAlign.center),
              ),
            );
          }
          final words = [for (final l in lessons) ...l.words];
          final allDone = lessons.every((l) => progress.containsKey(l.id));
          final currentIndex = lessons.indexWhere((l) => !progress.containsKey(l.id));
          final challenge = progress[TopicLesson.challengeId(unit.id)];
          return ZigzagPath(
            header: _UnitHeader(unit: unit, lessons: lessons, progress: progress),
            children: [
              for (final lesson in lessons)
                PathNode(
                  label: '${lesson.index + 1}',
                  stars: progress[lesson.id]?.stars ?? 0,
                  state: progress.containsKey(lesson.id)
                      ? NodeState.done
                      : lesson.index == currentIndex
                          ? NodeState.current
                          : NodeState.locked,
                  onTap: () => _openLesson(context, ref, lesson, locked: lesson.index > currentIndex && currentIndex != -1),
                ),
              PathNode(
                label: '🏆',
                big: true,
                color: Colors.deepPurple,
                stars: challenge?.stars ?? 0,
                state: challenge != null
                    ? NodeState.done
                    : allDone
                        ? NodeState.current
                        : NodeState.locked,
                onTap: () {
                  if (!allDone) {
                    _snack(context, 'Finish every lesson to unlock the challenge 🏆');
                  } else {
                    openUnitChallenge(context, ref, unit, words);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _snack(BuildContext context, String text) =>
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(text)));

  void _openLesson(BuildContext context, WidgetRef ref, TopicLesson lesson, {required bool locked}) {
    if (locked) {
      _snack(context, 'Finish the lessons before this one first 🔒');
      return;
    }
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Lesson ${lesson.index + 1}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final w in lesson.words) Chip(label: Text(w.word, style: const TextStyle(fontSize: 16)))],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start', style: TextStyle(fontSize: 18)),
              onPressed: () {
                Navigator.pop(sheetContext);
                openTopicLesson(context, ref, lesson, unit);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitHeader extends StatelessWidget {
  const _UnitHeader({required this.unit, required this.lessons, required this.progress});
  final TopicUnit unit;
  final List<TopicLesson> lessons;
  final Map<String, LessonProgressData> progress;

  @override
  Widget build(BuildContext context) {
    final done = lessons.where((l) => progress.containsKey(l.id)).length;
    final stars = lessons.fold(0, (s, l) => s + (progress[l.id]?.stars ?? 0));
    final words = lessons.fold(0, (s, l) => s + l.words.length);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card.filled(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ProgressEmoji(emoji: unit.emoji, progress: lessons.isEmpty ? 0 : done / lessons.length, size: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(unit.titleKo, style: Theme.of(context).textTheme.titleLarge),
                    Text('$words words · $done/${lessons.length} lessons · ⭐ $stars/${lessons.length * 3}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
