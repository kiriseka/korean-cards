import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../learn/curriculum.dart';
import '../../learn/drill.dart';
import '../../learn/swipe_review.dart';
import '../../providers.dart';
import '../../services/tts_service.dart';
import '../../settings.dart';
import '../study/swipe_card.dart';

/// Asks how to drill [drill] (level, skip learned words, deck size), then starts it.
Future<void> openDrill(BuildContext context, WidgetRef ref, Drill drill) => showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _DrillSheet(drill: drill),
    );

class _DrillSheet extends ConsumerStatefulWidget {
  const _DrillSheet({required this.drill});
  final Drill drill;

  @override
  ConsumerState<_DrillSheet> createState() => _DrillSheetState();
}

class _DrillSheetState extends ConsumerState<_DrillSheet> {
  String? _level;
  bool _skipLearned = true;
  int? _size = 20;

  Drill get drill => widget.drill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = ref.watch(drillCountsProvider).value ?? const [];
    final tally = drill.tally(rows, onlyLevel: _level);
    final skip = _skipLearned && drill.canSkipLearned;
    final available = tally.total - (skip ? tally.learned : 0);
    final cards = _size == null ? available : min(_size!, available);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${drill.emoji}  ${drill.title}', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('${tally.total} words · ${tally.learned} learned · ${tally.hard} hard', style: theme.textTheme.bodyMedium),
            if (drill.levelChoice) ...[
              const SizedBox(height: 20),
              Text('Level', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<String?>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: null, label: Text('All')),
                  ButtonSegment(value: '초급', label: Text('Beginner')),
                  ButtonSegment(value: intermediateLevel, label: Text('Level 2')),
                ],
                selected: {_level},
                onSelectionChanged: (s) => setState(() => _level = s.first),
              ),
            ],
            const SizedBox(height: 20),
            Text('Cards per round', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<int?>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 10, label: Text('10')),
                ButtonSegment(value: 20, label: Text('20')),
                ButtonSegment(value: 50, label: Text('50')),
                ButtonSegment(value: null, label: Text('All')),
              ],
              selected: {_size},
              onSelectionChanged: (s) => setState(() => _size = s.first),
            ),
            if (drill.canSkipLearned)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Skip words I've learned"),
                value: _skipLearned,
                onChanged: (v) => setState(() => _skipLearned = v),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(cards == 0 ? 'No cards to drill' : 'Start · $cards cards', style: const TextStyle(fontSize: 18)),
              onPressed: cards == 0
                  ? null
                  : () {
                      final options = DrillOptions(level: _level, skipLearned: _skipLearned, size: _size);
                      Navigator.of(context)
                        ..pop()
                        ..push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => DrillScreen(drill: drill, options: options)));
                    },
            ),
          ],
        ),
      ),
    );
  }
}

/// Swipe through a category's cards. A round ends in a summary that can re-drill the hard
/// ones, the whole round, or move on to the next batch.
class DrillScreen extends ConsumerStatefulWidget {
  const DrillScreen({super.key, required this.drill, this.options = const DrillOptions(), this.random});
  final Drill drill;
  final DrillOptions options;

  /// Shuffles each round; tests pass a seeded one.
  final Random? random;

  @override
  ConsumerState<DrillScreen> createState() => _DrillScreenState();
}

class _DrillScreenState extends ConsumerState<DrillScreen> {
  late final Random _random = widget.random ?? Random();
  late final TtsService _tts;

  /// This round's cards, and the round's starting deck for "Drill all again".
  List<CardWithWord>? _deck;
  List<CardWithWord> _roundStart = const [];
  int _index = 0;
  bool _revealed = false;
  DateTime _shownAt = DateTime.now();
  int _swipes = 0;

  int _learned = 0;
  final List<CardWithWord> _hard = [];

  /// Words drilled in this sitting (so "Next" brings new ones) and cards already rated today.
  final Set<int> _seenWords = {};
  final Set<int> _scheduled = {};

  /// The batch after this one, looked up when a round ends.
  List<CardWithWord> _next = const [];

  @override
  void initState() {
    super.initState();
    _tts = ref.read(ttsProvider);
    _loadBatch();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadBatch() async {
    final cards = await widget.drill.load(ref.read(dbProvider), widget.options, except: _seenWords);
    if (!mounted) return;
    _startRound(cards, shuffle: false);
  }

  void _startRound(List<CardWithWord> cards, {bool shuffle = true}) {
    final deck = [...cards];
    if (shuffle) deck.shuffle(_random);
    _seenWords.addAll(deck.map((c) => c.word.id));
    setState(() {
      _deck = deck;
      _roundStart = deck;
      _index = 0;
      _learned = 0;
      _hard.clear();
      _next = const [];
    });
    _show();
  }

  void _show() {
    setState(() {
      _revealed = false;
      _shownAt = DateTime.now();
    });
    final deck = _deck!;
    if (_index < deck.length && ref.read(settingsProvider).autoPlay) ref.speak(deck[_index].word.word);
  }

  void _flip() => setState(() => _revealed = !_revealed);

  Future<void> _swiped(bool learned) async {
    final deck = _deck!;
    final item = deck[_index];
    // Only the first swipe of a card in this sitting goes to spaced repetition.
    final first = _scheduled.add(item.card.id);
    final saved = CardWithWord(
      await recordSwipe(ref, item, learned: learned, shownAt: _shownAt, schedule: first),
      item.word,
    );
    if (!mounted) return;
    deck[_index] = saved;
    _roundStart = [for (final c in _roundStart) c.card.id == saved.card.id ? saved : c];
    if (learned) {
      _learned++;
    } else {
      _hard.add(saved);
    }
    _swipes++;
    _index++;
    if (_index >= deck.length && widget.options.size != null) {
      _next = await widget.drill.load(ref.read(dbProvider), widget.options, except: _seenWords);
    }
    if (!mounted) return;
    _show();
  }

  @override
  Widget build(BuildContext context) {
    final deck = _deck;
    final drilling = deck != null && _index < deck.length;
    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: Text('${widget.drill.emoji} ${widget.drill.title}'),
        actions: [
          if (drilling)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('${_index + 1} / ${deck.length}', style: Theme.of(context).textTheme.titleMedium)),
            ),
        ],
        bottom: drilling
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(value: _index / deck.length),
              )
            : null,
      ),
      body: SafeArea(
        child: deck == null
            ? const Center(child: CircularProgressIndicator())
            : deck.isEmpty
                ? const _Empty()
                : drilling
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: SwipeCard(
                          key: ValueKey(_swipes),
                          item: deck[_index],
                          revealed: _revealed,
                          onTap: _flip,
                          onSwipe: _swiped,
                        ),
                      )
                    : _RoundSummary(
                        learned: _learned,
                        hard: _hard.length,
                        next: _next.length,
                        onDrillHard: () => _startRound(_hard),
                        onDrillAll: () => _startRound(_roundStart),
                        onNext: () => _startRound(_next, shuffle: false),
                      ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🃏', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text('No cards here yet.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
            ],
          ),
        ),
      );
}

class _RoundSummary extends StatelessWidget {
  const _RoundSummary({
    required this.learned,
    required this.hard,
    required this.next,
    required this.onDrillHard,
    required this.onDrillAll,
    required this.onNext,
  });

  final int learned;
  final int hard;
  final int next;
  final VoidCallback onDrillHard;
  final VoidCallback onDrillAll;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget stat(String value, String label, Color color) => Expanded(
          child: Column(children: [
            Text(value, style: theme.textTheme.displaySmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
            Text(label, style: theme.textTheme.titleSmall),
          ]),
        );
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(hard == 0 ? '완벽해요! 🎉' : '수고했어요!', textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 24),
            Row(children: [
              stat('$learned', 'learned', const Color(0xFF388E3C)),
              stat('$hard', 'hard', const Color(0xFFD32F2F)),
            ]),
            const SizedBox(height: 32),
            if (hard > 0) ...[
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                icon: const Icon(Icons.local_fire_department_rounded),
                label: Text('Drill the $hard hard ${hard == 1 ? 'one' : 'ones'}'),
                onPressed: onDrillHard,
              ),
              const SizedBox(height: 8),
            ],
            if (next > 0) ...[
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                icon: const Icon(Icons.skip_next_rounded),
                label: Text('Next $next ${next == 1 ? 'word' : 'words'}'),
                onPressed: onNext,
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Drill all again'),
              onPressed: onDrillAll,
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
          ],
        ),
      ),
    );
  }
}
