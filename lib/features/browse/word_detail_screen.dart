import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/db.dart';
import '../../providers.dart';
import '../../widgets/common.dart';
import 'add_word_screen.dart';

class WordDetailScreen extends ConsumerWidget {
  const WordDetailScreen({super.key, required this.wordId});
  final int wordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    return StreamBuilder<Word>(
      stream: db.watchWord(wordId),
      builder: (context, snap) {
        final word = snap.data;
        if (word == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                tooltip: word.starred ? 'Unstar' : 'Star',
                icon: Icon(word.starred ? Icons.star : Icons.star_border, color: word.starred ? Colors.amber : null),
                onPressed: () => db.setStarred(word.id, !word.starred),
              ),
              _Menu(word: word),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Header(word: word),
              const Divider(height: 32),
              for (final (i, s) in word.senseList.indexed) _SenseView(index: i + 1, sense: s),
              if (word.category != null) ...[
                const SizedBox(height: 8),
                Text('Topic: ${word.category}', style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 16),
              _NoteCard(word: word),
              const SizedBox(height: 16),
              StreamBuilder<List<StudyCard>>(
                stream: db.watchCardsForWord(word.id),
                builder: (context, snap) => Column(
                  children: [for (final c in snap.data ?? const <StudyCard>[]) _CardProgress(card: c)],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.word});
  final Word word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text(word.word, style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600))),
            SpeakButton(word.word, size: 32),
          ],
        ),
        Wrap(
          spacing: 12,
          children: [
            if (word.pronunciation != null) Text('[${word.pronunciation}]', style: theme.textTheme.titleMedium),
            if (word.hanja != null) Text(word.hanja!, style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [TagChip(word.pos), TagChip(levelLabel(word.level))]),
      ],
    );
  }
}

class _SenseView extends StatelessWidget {
  const _SenseView({required this.index, required this.sense});
  final int index;
  final Sense sense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$index. ${sense.meanings.join(', ')}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          if (sense.definition.isNotEmpty) Text(sense.definition),
          if (sense.example != null)
            Row(
              children: [
                Expanded(child: Text(sense.example!, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16))),
                SpeakButton(sense.example!, size: 22),
              ],
            ),
        ],
      ),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.word});
  final Word word;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: word.note);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Memory hook, better translation, where you heard it…'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (result != null) await ref.read(dbProvider).setNote(word.id, result.isEmpty ? null : result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card.filled(
        child: ListTile(
          leading: const Icon(Icons.edit_note),
          title: Text(word.note ?? 'Add a note'),
          subtitle: word.note == null ? const Text('Shown on the back of the card') : null,
          onTap: () => _edit(context, ref),
        ),
      );
}

class _CardProgress extends StatelessWidget {
  const _CardProgress({required this.card});
  final StudyCard card;

  @override
  Widget build(BuildContext context) {
    final status = CardStatus.of(card);
    final direction = card.direction == Direction.koToEn ? 'Korean → English' : 'English → Korean';
    final details = card.state == CardState.newCard
        ? 'Not studied yet'
        : 'Next review ${DateFormat.yMMMd().add_jm().format(card.due)} · ${card.reps} reviews · ${card.lapses} lapses';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: StatusDot(status),
      title: Text('$direction · ${status.label}'),
      subtitle: Text(details),
    );
  }
}

enum _Action { edit, suspend, reset, delete }

class _Menu extends ConsumerWidget {
  const _Menu({required this.word});
  final Word word;

  Future<bool> _confirm(BuildContext context, String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK')),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    return StreamBuilder<List<StudyCard>>(
      stream: db.watchCardsForWord(word.id),
      builder: (context, snap) {
        final suspended = snap.data?.any((c) => c.suspended) ?? false;
        return PopupMenuButton<_Action>(
          onSelected: (action) async {
            switch (action) {
              case _Action.edit:
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddWordScreen(existing: word)));
              case _Action.suspend:
                await db.setSuspended(word.id, !suspended);
              case _Action.reset:
                if (await _confirm(context, 'Reset progress?', 'This word will be treated as new again.')) {
                  await db.resetProgress(word.id);
                }
              case _Action.delete:
                if (await _confirm(context, 'Delete ${word.word}?', 'Your word and its review history will be removed.')) {
                  await db.deleteWord(word.id);
                  if (context.mounted) Navigator.of(context).pop();
                }
            }
          },
          itemBuilder: (_) => [
            if (word.isCustom) const PopupMenuItem(value: _Action.edit, child: Text('Edit word')),
            PopupMenuItem(value: _Action.suspend, child: Text(suspended ? 'Unsuspend' : 'Suspend (stop showing)')),
            const PopupMenuItem(value: _Action.reset, child: Text('Reset progress')),
            if (word.isCustom) const PopupMenuItem(value: _Action.delete, child: Text('Delete word')),
          ],
        );
      },
    );
  }
}
