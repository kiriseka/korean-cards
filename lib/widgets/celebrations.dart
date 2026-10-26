import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_service.dart';
import '../game/sound_service.dart';
import '../providers.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final messengerKey = GlobalKey<ScaffoldMessengerState>();

/// Pops up level-ups, new badges and finished quests wherever the user is.
class CelebrationHost extends ConsumerStatefulWidget {
  const CelebrationHost({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<CelebrationHost> createState() => _CelebrationHostState();
}

class _CelebrationHostState extends ConsumerState<CelebrationHost> {
  StreamSubscription<Celebration>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(gameProvider).celebrations.listen(_show);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _toast(String emoji, String text) {
    messengerKey.currentState?.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      content: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
      ]),
    ));
  }

  void _show(Celebration c) {
    switch (c) {
      case QuestDone(:final quest, :final xp):
        _toast(quest?.emoji ?? '🎁', quest == null ? 'All quests done! +$xp XP bonus' : 'Quest complete: ${quest.title} +$xp XP');
      case BadgeEarned(:final badge):
        _toast(badge.emoji, 'New badge: ${badge.title}!');
      case LevelUp(:final level):
        final context = navigatorKey.currentContext;
        if (context == null) return;
        ref.read(soundProvider).play(Sfx.levelup);
        showDialog(context: context, builder: (_) => _LevelUpDialog(level: level.level, emoji: level.title.emoji, title: level.title.korean, english: level.title.english));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _LevelUpDialog extends StatefulWidget {
  const _LevelUpDialog({required this.level, required this.emoji, required this.title, required this.english});
  final int level;
  final String emoji;
  final String title;
  final String english;

  @override
  State<_LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<_LevelUpDialog> {
  final _confetti = ConfettiController(duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(alignment: Alignment.topCenter, children: [
      AlertDialog(
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Text(widget.emoji, style: const TextStyle(fontSize: 72)),
          ),
          Text('레벨 업!', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text('Level ${widget.level}', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('${widget.title} · ${widget.english}', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
        ]),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('최고! Awesome'))],
      ),
      ConfettiWidget(confettiController: _confetti, blastDirectionality: BlastDirectionality.explosive, numberOfParticles: 50),
    ]);
  }
}
