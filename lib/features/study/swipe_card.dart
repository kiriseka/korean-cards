import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/db.dart';
import 'flashcard.dart';

const _learnedColor = Color(0xFF388E3C);
const _hardColor = Color(0xFFD32F2F);

/// A flashcard to swipe: right for "learned", left for "hard". Tapping flips it; the buttons
/// below do the same as a swipe. Give each card shown a new key so it starts centred.
class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.item,
    required this.revealed,
    required this.onTap,
    required this.onSwipe,
  });

  final CardWithWord item;
  final bool revealed;
  final VoidCallback onTap;

  /// Called once the card has flown off screen; true for right (learned).
  final void Function(bool learned) onSwipe;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with SingleTickerProviderStateMixin {
  /// Share of the card's width a drag must pass to count as a swipe.
  static const _threshold = 0.3;

  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  double _dx = 0;
  double _width = 1;
  bool _leaving = false;
  bool _pastThreshold = false;

  // The running slide: from, to, and the swipe to report when it ends (null for a spring back).
  double _from = 0;
  double _to = 0;
  bool? _pending;

  @override
  void initState() {
    super.initState();
    _anim.addListener(() => setState(() => _dx = _from + (_to - _from) * Curves.easeOut.transform(_anim.value)));
    _anim.addStatusListener((status) {
      if (status == AnimationStatus.completed && _pending != null) widget.onSwipe(_pending!);
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _animateTo(double target, {bool? learned}) {
    _from = _dx;
    _to = target;
    _pending = learned;
    _anim.forward(from: 0);
  }

  void _swipe(bool learned) {
    if (_leaving) return;
    _leaving = true;
    _animateTo((learned ? 1 : -1) * _width * 1.5, learned: learned);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_leaving) return;
    if (_anim.isAnimating) _anim.stop();
    setState(() => _dx += d.delta.dx);
    final past = _dx.abs() > _width * _threshold;
    if (past && !_pastThreshold) HapticFeedback.selectionClick();
    _pastThreshold = past;
  }

  void _onDragEnd(DragEndDetails d) {
    if (_leaving) return;
    final velocity = d.primaryVelocity ?? 0;
    if (_dx.abs() > _width * _threshold) {
      _swipe(_dx > 0);
    } else if (velocity.abs() > 900 && velocity.sign == _dx.sign) {
      _swipe(velocity > 0);
    } else {
      _pastThreshold = false;
      _animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (_dx.abs() / (_width * _threshold)).clamp(0.0, 1.0);
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            _width = box.maxWidth;
            return GestureDetector(
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: Transform.translate(
                offset: Offset(_dx, 0),
                child: Transform.rotate(
                  angle: _dx / _width * pi / 12,
                  child: Stack(
                    children: [
                      Flashcard(item: widget.item, revealed: widget.revealed, onTap: widget.onTap),
                      if (_dx != 0)
                        Positioned(
                          top: 24,
                          left: _dx > 0 ? 24 : null,
                          right: _dx < 0 ? 24 : null,
                          child: Opacity(
                            opacity: progress,
                            child: _Stamp(learned: _dx > 0),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to flip  ·  swipe → learned  ·  ← hard',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _hardColor,
                  side: const BorderSide(color: _hardColor, width: 2),
                  minimumSize: const Size.fromHeight(56),
                ),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Hard', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                onPressed: () => _swipe(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _learnedColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                ),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Learned', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                onPressed: () => _swipe(true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.learned});
  final bool learned;

  @override
  Widget build(BuildContext context) {
    final color = learned ? _learnedColor : _hardColor;
    return Transform.rotate(
      angle: learned ? -0.2 : 0.2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        ),
        child: Text(
          learned ? 'LEARNED ✓' : 'HARD ✗',
          style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
      ),
    );
  }
}
