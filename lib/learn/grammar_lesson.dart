import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db.dart';
import '../game/rules.dart';
import '../grammar/grammar_content.dart';
import '../providers.dart';
import '../settings.dart';
import 'lesson_screen.dart';
import 'topic_lesson.dart';

final grammarProvider = FutureProvider<List<GrammarUnit>>((ref) => loadGrammar());

final learnedWordIdsProvider = StreamProvider<Set<int>>((ref) => ref.watch(dbProvider).watchLearnedWordIds());

Future<bool?> openGrammarLesson(BuildContext context, WidgetRef ref, GrammarLesson lesson) async {
  final words = await ref.read(allWordsProvider.future);
  final learned = await ref.read(learnedWordIdsProvider.future);
  if (!context.mounted) return null;
  final exercises = GrammarExerciseBuilder(words: words, learned: learned)
      .lessonPractice(lesson,
          typingOn: ref.read(settingsProvider).typingExercises, speakingOn: ref.read(settingsProvider).speakingExercises);
  return Navigator.of(context).push<bool>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => LessonScreen(
      title: lesson.title,
      exercises: exercises,
      intro: (context, start) => LearnCardsView(lesson: lesson, onStart: start),
      onComplete: (s) async {
        final game = ref.read(gameProvider);
        await game.recordLesson(lesson.progressId, stars: s.stars, accuracy: s.accuracy);
        return game.award([
          ...sessionActivities(game, s),
          game.activity(ActivityKind.lesson,
              xp: s.perfect ? Xp.perfectLesson : Xp.lesson, value: (s.accuracy * 100).round(), ref: lesson.progressId),
        ]);
      },
    ),
  ));
}

class LearnCardsView extends StatefulWidget {
  const LearnCardsView({super.key, required this.lesson, required this.onStart});
  final GrammarLesson lesson;
  final VoidCallback onStart;

  @override
  State<LearnCardsView> createState() => _LearnCardsViewState();
}

class _LearnCardsViewState extends State<LearnCardsView> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.lesson.cards;
    final last = _page == cards.length - 1;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
          child: Row(children: [
            const CloseButton(),
            Expanded(child: Text(widget.lesson.title, style: Theme.of(context).textTheme.titleMedium)),
            Text('${_page + 1}/${cards.length}'),
          ]),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pages,
            itemCount: cards.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: LearnCardView(card: cards[i]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: last
                ? widget.onStart
                : () => _pages.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
            child: Text(last ? 'Practise! 💪' : 'Next', style: const TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }
}

/// **bold** and *italic* inside lesson text.
List<InlineSpan> richSpans(String text, TextStyle base, Color accent) {
  final spans = <InlineSpan>[];
  final pattern = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');
  var last = 0;
  for (final m in pattern.allMatches(text)) {
    if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
    if (m.group(1) != null) {
      spans.add(TextSpan(text: m.group(1), style: TextStyle(fontWeight: FontWeight.bold, color: accent)));
    } else {
      spans.add(TextSpan(text: m.group(2), style: const TextStyle(fontStyle: FontStyle.italic)));
    }
    last = m.end;
  }
  if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
  return spans;
}

class LearnCardView extends ConsumerWidget {
  const LearnCardView({super.key, required this.card});
  final LearnCard card;

  static const _chipColors = [Color(0xFF1E88E5), Color(0xFFE53935), Color(0xFF43A047), Color(0xFF8E24AA), Color(0xFFFB8C00)];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = theme.textTheme.bodyLarge!.copyWith(fontSize: 17, height: 1.45);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(card.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (card.body != null) Text.rich(TextSpan(style: base, children: richSpans(card.body!, base, scheme.primary))),
        if (card.formula.isNotEmpty) ...[
          const SizedBox(height: 20),
          Wrap(
            spacing: 6,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final (i, chip) in card.formula.indexed) ...[
                if (i > 0) const Text('+', style: TextStyle(fontSize: 20)),
                _FormulaChip(
                  text: chip.split('|').first,
                  caption: chip.contains('|') ? chip.split('|').last : null,
                  color: _chipColors[i % _chipColors.length],
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.volume_up),
              label: const Text('Hear it'),
              onPressed: () => ref.speak(card.formula.map((c) => c.split('|').first).join(' ')),
            ),
          ),
        ],
        if (card.table.isNotEmpty) ...[
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(color: scheme.outlineVariant, borderRadius: BorderRadius.circular(8)),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              for (final (r, row) in card.table.indexed)
                TableRow(
                  decoration: BoxDecoration(color: r == 0 && card.table.length > 2 ? scheme.secondaryContainer : null),
                  children: [
                    for (final cell in row)
                      InkWell(
                        onTap: () => ref.speak(cell),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(cell, style: TextStyle(fontSize: 15, fontWeight: r == 0 && card.table.length > 2 ? FontWeight.bold : null)),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
        if (card.examples.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Examples', style: theme.textTheme.titleSmall?.copyWith(color: scheme.primary)),
          for (final e in card.examples)
            Card.outlined(
              margin: const EdgeInsets.only(top: 8),
              child: ListTile(
                title: Text(e.ko, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                subtitle: Text(e.en),
                trailing: const Icon(Icons.volume_up_rounded),
                onTap: () => ref.speak(e.ko),
              ),
            ),
        ],
      ],
    );
  }
}

class _FormulaChip extends StatelessWidget {
  const _FormulaChip({required this.text, required this.color, this.caption});
  final String text;
  final String? caption;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), border: Border.all(color: color, width: 2), borderRadius: BorderRadius.circular(12)),
            child: Text(text, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ),
          if (caption != null) Text(caption!, style: TextStyle(fontSize: 12, color: color)),
        ],
      );
}
