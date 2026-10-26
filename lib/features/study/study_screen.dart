import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../game/rules.dart';
import '../../game/sound_service.dart';
import '../../providers.dart';
import '../../services/tts_service.dart';
import '../../settings.dart';
import '../../srs/scheduler.dart';
import '../../srs/session_queue.dart';
import 'flashcard.dart';

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
  Map<Rating, ReviewOutcome> _outcomes = const {};
  bool _revealed = false;
  DateTime _shownAt = DateTime.now();
  final DateTime _startedAt = DateTime.now();
  int _done = 0;
  int _again = 0;
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
      _outcomes = next == null ? const {} : ref.read(schedulerProvider).preview(next.card, now);
    });
    if (next != null && next.card.direction == Direction.koToEn && ref.read(settingsProvider).autoPlay) {
      ref.speak(next.word.word);
    }
  }

  void _reveal() {
    if (_revealed || _current == null) return;
    setState(() => _revealed = true);
    if (_current!.card.direction == Direction.enToKo && ref.read(settingsProvider).autoPlay) {
      ref.speak(_current!.word.word);
    }
  }

  Future<void> _rate(Rating rating) async {
    final item = _current!;
    final outcome = _outcomes[rating]!;
    HapticFeedback.lightImpact();
    ref.read(soundProvider).play(rating == Rating.again ? Sfx.flip : Sfx.tap);
    final now = DateTime.now();
    await ref.read(dbProvider).saveReview(
          outcome.card,
          ReviewLogsCompanion.insert(
            cardId: item.card.id,
            rating: rating.fsrsRating.value,
            stateBefore: item.card.state,
            reviewedAt: now,
            elapsedMs: now.difference(_shownAt).inMilliseconds,
          ),
        );
    final game = ref.read(gameProvider);
    game.award([
      game.activity(ActivityKind.review, xp: rating == Rating.again ? Xp.reviewAgain : Xp.review, value: rating.fsrsRating.value),
    ]);
    _done++;
    if (rating == Rating.again) _again++;
    _queue!.requeueIfDueSoon(CardWithWord(outcome.card, item.word), now);
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
                ? _Summary(done: _done, again: _again, elapsed: DateTime.now().difference(_startedAt))
                : Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Flashcard(item: _current!, revealed: _revealed, onTap: _reveal),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _revealed
                            ? _RatingButtons(outcomes: _outcomes, onRate: _rate)
                            : FilledButton(
                                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
                                onPressed: _reveal,
                                child: const Text('Show answer', style: TextStyle(fontSize: 18)),
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _RatingButtons extends StatelessWidget {
  const _RatingButtons({required this.outcomes, required this.onRate});
  final Map<Rating, ReviewOutcome> outcomes;
  final void Function(Rating) onRate;

  static const _colors = {
    Rating.again: Color(0xFFD32F2F),
    Rating.hard: Color(0xFFF57C00),
    Rating.good: Color(0xFF388E3C),
    Rating.easy: Color(0xFF1976D2),
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final r in Rating.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _colors[r],
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(64),
                  padding: EdgeInsets.zero,
                ),
                onPressed: () => onRate(r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(r.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(formatInterval(outcomes[r]!.interval), style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.done, required this.again, required this.elapsed});
  final int done;
  final int again;
  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = done == 0 ? null : ((done - again) / done * 100).round();
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
              Text('$done cards · ${accuracy!}% correct · ${elapsed.inMinutes}m ${elapsed.inSeconds % 60}s',
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
