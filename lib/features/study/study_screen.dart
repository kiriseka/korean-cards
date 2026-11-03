import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../learn/swipe_review.dart';
import '../../providers.dart';
import '../../services/tts_service.dart';
import '../../settings.dart';
import '../../srs/session_queue.dart';
import 'swipe_card.dart';

class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({super.key, this.extraNew = 0, this.maxCards});

  /// New words beyond today's limit, for "Learn 5 more words".
  final int extraNew;

  /// Caps the session (Today's session keeps flashcards to its time budget).
  final int? maxCards;

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  SessionQueue? _queue;
  CardWithWord? _current;
  bool _revealed = false;
  DateTime _shownAt = DateTime.now();
  final DateTime _startedAt = DateTime.now();
  int _done = 0;
  int _hard = 0;
  late final TtsService _tts;

  @override
  void initState() {
    super.initState();
    _tts = ref.read(ttsProvider);
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(dbProvider);
    final s = ref.read(settingsProvider);
    final now = DateTime.now();
    final cap = widget.maxCards;
    final due = await db.dueCards(now, reverse: s.reverseCards, limit: cap == null ? s.reviewCap : min(s.reviewCap, cap));
    final newToday = await db.newIntroducedSince(studyDayStart(now));
    var newLimit = (s.newPerDay - newToday).clamp(0, 9999) + widget.extraNew;
    if (cap != null) newLimit = min(newLimit, max(0, cap - due.length));
    final intermediate = s.intermediate || await db.learnedBeginnerCount() >= intermediateUnlockAt;
    final fresh = await db.newCards(reverse: s.reverseCards, limit: newLimit, intermediate: intermediate);
    if (!mounted) return;
    _queue = SessionQueue(due: due, newCards: fresh);
    _showNext();
  }

  void _showNext() {
    final now = DateTime.now();
    final next = _queue!.next(now);
    setState(() {
      _current = next;
      _revealed = false;
      _shownAt = now;
    });
    if (next != null && next.card.direction == Direction.koToEn && ref.read(settingsProvider).autoPlay) {
      ref.speak(next.word.word);
    }
  }

  void _flip() {
    if (_current == null) return;
    setState(() => _revealed = !_revealed);
    if (_revealed && _current!.card.direction == Direction.enToKo && ref.read(settingsProvider).autoPlay) {
      ref.speak(_current!.word.word);
    }
  }

  /// Right is Good, left is Again. Only a hard card comes back later in this session; a learned
  /// one waits for its next review, even if that is a short learning step away.
  Future<void> _swiped(bool learned) async {
    final item = _current!;
    final saved = await recordSwipe(ref, item, learned: learned, shownAt: _shownAt);
    if (!mounted) return;
    _done++;
    if (!learned) {
      _hard++;
      _queue!.requeueIfDueSoon(CardWithWord(saved, item.word), DateTime.now());
    }
    _showNext();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queue = _queue;
    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: queue == null || _current == null ? null : Text('${queue.remaining + 1} left'),
      ),
      body: SafeArea(
        child: queue == null
            ? const Center(child: CircularProgressIndicator())
            : _current == null
                ? _Summary(done: _done, hard: _hard, elapsed: DateTime.now().difference(_startedAt))
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: SwipeCard(
                      key: ValueKey(_done),
                      item: _current!,
                      revealed: _revealed,
                      onTap: _flip,
                      onSwipe: _swiped,
                    ),
                  ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.done, required this.hard, required this.elapsed});
  final int done;
  final int hard;
  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(done == 0 ? '🎉' : '수고했어요!', style: theme.textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(done == 0 ? 'Nothing to study right now.' : 'Session complete', style: theme.textTheme.titleMedium),
            const SizedBox(height: 32),
            if (done > 0) ...[
              Text('${done - hard} learned · $hard hard · ${elapsed.inMinutes}m ${elapsed.inSeconds % 60}s',
                  style: theme.textTheme.bodyLarge),
              const SizedBox(height: 32),
            ],
            FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
          ],
        ),
      ),
    );
  }
}
