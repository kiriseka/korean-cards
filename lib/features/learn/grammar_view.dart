import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../grammar/grammar_content.dart';
import '../../learn/grammar_lesson.dart';
import '../../providers.dart';

/// Grammar units, each a short trail of lessons that unlock in order.
class GrammarView extends ConsumerWidget {
  const GrammarView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(grammarProvider).value;
    final progress = ref.watch(lessonProgressProvider).value ?? const {};
    if (units == null) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
      children: [for (final u in units) _GrammarUnitSection(unit: u, progress: progress)],
    );
  }
}

class _GrammarUnitSection extends ConsumerWidget {
  const _GrammarUnitSection({required this.unit, required this.progress});
  final GrammarUnit unit;
  final Map<String, LessonProgressData> progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final done = unit.lessons.where((l) => progress.containsKey(l.progressId)).length;
    final current = unit.lessons.indexWhere((l) => !progress.containsKey(l.progressId));
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(unit.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(unit.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text('${unit.titleKo} · $done/${unit.lessons.length}', style: theme.textTheme.bodySmall),
              ]),
            ),
            if (done == unit.lessons.length) const Text('🏅', style: TextStyle(fontSize: 26)),
          ]),
          const SizedBox(height: 8),
          for (final l in unit.lessons)
            _LessonRow(
              lesson: l,
              stars: progress[l.progressId]?.stars,
              locked: current != -1 && l.index > current,
              current: l.index == current,
              last: l.index == unit.lessons.length - 1,
            ),
        ],
      ),
    );
  }
}

class _LessonRow extends ConsumerWidget {
  const _LessonRow({required this.lesson, required this.stars, required this.locked, required this.current, required this.last});
  final GrammarLesson lesson;
  final int? stars;
  final bool locked;
  final bool current;
  final bool last;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final done = stars != null;
    final color = done ? Colors.amber.shade600 : locked ? scheme.surfaceContainerHighest : scheme.primary;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: current ? Border.all(color: scheme.primaryContainer, width: 4) : null),
                alignment: Alignment.center,
                child: locked
                    ? Icon(Icons.lock, size: 18, color: scheme.outline)
                    : done
                        ? const Icon(Icons.check, color: Colors.white)
                        : Text('${lesson.index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              if (!last) Expanded(child: Container(width: 3, color: scheme.outlineVariant)),
            ]),
          ),
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(left: 6, bottom: 10),
              color: current ? scheme.primaryContainer : null,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (locked) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(content: Text('Finish the lesson before this one first 🔒')));
                  } else {
                    openGrammarLesson(context, ref, lesson);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(lesson.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        Text(lesson.subtitle, style: Theme.of(context).textTheme.bodySmall),
                      ]),
                    ),
                    if (done)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        for (var i = 0; i < 3; i++)
                          Icon(Icons.star_rounded, size: 18, color: i < stars! ? Colors.amber : scheme.outlineVariant),
                      ])
                    else if (current)
                      Text('START', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
