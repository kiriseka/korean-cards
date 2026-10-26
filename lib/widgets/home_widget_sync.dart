import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../data/db.dart';
import '../features/daily/daily_session_screen.dart';
import '../learn/daily_plan.dart';
import '../learn/grammar_lesson.dart';
import '../learn/word_of_day.dart';
import '../providers.dart';
import 'celebrations.dart';

/// Keeps the home-screen widget current (streak, due cards, today's steps, word of the day)
/// and opens Today's session when the widget is tapped.
class HomeWidgetSync extends ConsumerStatefulWidget {
  const HomeWidgetSync({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<HomeWidgetSync> createState() => _HomeWidgetSyncState();
}

class _HomeWidgetSyncState extends ConsumerState<HomeWidgetSync> {
  Map<String, String>? _last;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (await HomeWidget.initiallyLaunchedFromHomeWidget() != null) _openToday();
        HomeWidget.widgetClicked.listen((uri) {
          if (uri != null) _openToday();
        });
      } catch (_) {
        // No widget support (tests, other platforms).
      }
    });
  }

  void _openToday() => navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const DailySessionScreen()));

  Future<void> _push(Map<String, String> data) async {
    if (_last != null && _last.toString() == data.toString()) return;
    _last = data;
    try {
      for (final e in data.entries) {
        await HomeWidget.saveWidgetData<String>(e.key, e.value);
      }
      await HomeWidget.updateWidget(qualifiedAndroidName: 'com.pongo.korean_cards.KoreanWidgetProvider');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;
    final counts = ref.watch(todayCountsProvider).value;
    final done = ref.watch(dailyProgressProvider).value ?? const <int>{};
    final words = ref.watch(allWordsProvider).value;
    final learned = ref.watch(learnedWordIdsProvider).value ?? const <int>{};
    if (profile != null && counts != null && words != null && words.isNotEmpty) {
      final w = wordOfTheDay(words, learned, DateTime.now());
      final due = counts.due + counts.learning;
      _push({
        'streak': '${profile.streak.days}',
        'due': due > 0 ? '$due cards due' : 'All caught up',
        'steps': [for (final s in DailyStep.values) done.contains(s.code) ? '●' : '○'].join(),
        'word': w.word,
        'gloss': w.gloss,
      });
    }
    return widget.child;
  }
}
