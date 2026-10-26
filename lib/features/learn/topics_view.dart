import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../learn/curriculum.dart';
import '../../providers.dart';
import 'path_widgets.dart';
import 'unit_path_screen.dart';

/// Lesson completion of one topic: (done, total, challenge passed).
(int, int, bool) unitProgress(String unitId, List<TopicLesson> lessons, Map<String, LessonProgressData> progress) {
  final done = lessons.where((l) => progress.containsKey(l.id)).length;
  return (done, lessons.length, progress.containsKey(TopicLesson.challengeId(unitId)));
}

class TopicsView extends ConsumerWidget {
  const TopicsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(curriculumProvider).value;
    final progress = ref.watch(lessonProgressProvider).value ?? const {};
    if (units == null) return const Center(child: CircularProgressIndicator());

    // The first unit with unfinished lessons is the suggested next one.
    String? suggested;
    for (final u in units) {
      final lessons = ref.watch(topicLessonsProvider(u.id)).value;
      if (lessons == null || lessons.isEmpty) continue;
      final (done, total, _) = unitProgress(u.id, lessons, progress);
      if (done < total) {
        suggested = u.id;
        break;
      }
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: units.length,
      itemBuilder: (context, i) {
        final unit = units[i];
        final lessons = ref.watch(topicLessonsProvider(unit.id)).value ?? const [];
        final (done, total, trophy) = unitProgress(unit.id, lessons, progress);
        return _UnitCard(
          unit: unit,
          done: done,
          total: total,
          trophy: trophy,
          suggested: unit.id == suggested,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => UnitPathScreen(unit: unit))),
        );
      },
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.done,
    required this.total,
    required this.trophy,
    required this.suggested,
    required this.onTap,
  });

  final TopicUnit unit;
  final int done;
  final int total;
  final bool trophy;
  final bool suggested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: suggested ? BorderSide(color: theme.colorScheme.primary, width: 3) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ProgressEmoji(emoji: unit.emoji, progress: total == 0 ? 0 : done / total),
                  const SizedBox(height: 10),
                  Text(unit.title, textAlign: TextAlign.center, maxLines: 2, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text(unit.titleKo, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(total == 0 ? 'No words yet' : '$done / $total lessons', style: theme.textTheme.labelSmall),
                ],
              ),
            ),
            if (trophy) const Positioned(top: 8, right: 10, child: Text('🏆', style: TextStyle(fontSize: 22))),
            if (suggested)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(8)),
                  child: Text('NEXT', style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
