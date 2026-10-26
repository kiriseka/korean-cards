import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../talk/dialogue.dart';
import 'dialogue_screen.dart';

/// Conversation scenes, unlocking one after another.
class TalkView extends ConsumerWidget {
  const TalkView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenes = ref.watch(scenesProvider).value;
    final progress = ref.watch(lessonProgressProvider).value ?? const {};
    if (scenes == null) return const Center(child: CircularProgressIndicator());
    final current = scenes.indexWhere((s) => !progress.containsKey(s.progressId));
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
      children: [
        Card.filled(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '🗣️ Real conversations. Listen, understand, repeat your lines, then play your part — '
              'the app speaks the other person and checks what you say.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final s in scenes)
          () {
            final p = progress[s.progressId];
            final locked = current != -1 && s.index > current;
            final isCurrent = s.index == current;
            return Card(
              color: isCurrent ? theme.colorScheme.primaryContainer : null,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Text(locked ? '🔒' : s.emoji, style: const TextStyle(fontSize: 32)),
                title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${s.titleKo} · ${s.lines.length} lines · with ${s.partner}'),
                trailing: p != null
                    ? Row(mainAxisSize: MainAxisSize.min, children: [
                        for (var i = 0; i < 3; i++)
                          Icon(Icons.star_rounded, size: 18, color: i < p.stars ? Colors.amber : theme.colorScheme.outlineVariant),
                      ])
                    : isCurrent
                        ? Text('START', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold))
                        : null,
                onTap: () {
                  if (locked) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(content: Text('Finish the scene before this one first 🔒')));
                    return;
                  }
                  Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => DialogueScreen(scene: s)));
                },
              ),
            );
          }(),
      ],
    );
  }
}
