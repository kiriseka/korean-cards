import 'dart:math';

import 'package:flutter/material.dart';

enum NodeState { locked, open, current, done }

/// One stop on a lesson path: a round button with stars underneath.
class PathNode extends StatefulWidget {
  const PathNode({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
    this.stars = 0,
    this.color,
    this.big = false,
  });

  final String label;
  final NodeState state;
  final VoidCallback onTap;
  final int stars;
  final Color? color;
  final bool big;

  @override
  State<PathNode> createState() => _PathNodeState();
}

class _PathNodeState extends State<PathNode> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    if (widget.state == NodeState.current) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PathNode old) {
    super.didUpdateWidget(old);
    if (widget.state == NodeState.current && !_pulse.isAnimating) _pulse.repeat(reverse: true);
    if (widget.state != NodeState.current) _pulse.stop();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = widget.color ?? scheme.primary;
    final (bg, fg) = switch (widget.state) {
      NodeState.locked => (scheme.surfaceContainerHighest, scheme.outline),
      NodeState.done => (Colors.amber.shade600, Colors.white),
      _ => (base, Colors.white),
    };
    final size = widget.big ? 88.0 : 72.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) => Transform.scale(scale: 1 + 0.06 * _pulse.value, child: child),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color.lerp(bg, Colors.black, 0.3)!, offset: const Offset(0, 5))],
                border: widget.state == NodeState.current ? Border.all(color: Colors.white, width: 4) : null,
              ),
              alignment: Alignment.center,
              child: widget.state == NodeState.locked
                  ? Icon(Icons.lock, color: fg, size: 28)
                  : Text(widget.label, style: TextStyle(fontSize: widget.big ? 36 : 26, color: fg, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 20,
          child: widget.state == NodeState.done
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Icon(Icons.star_rounded, size: 18, color: i < widget.stars ? Colors.amber : scheme.outlineVariant),
                  ],
                )
              : widget.state == NodeState.current
                  ? Text('START', style: TextStyle(color: base, fontWeight: FontWeight.bold, fontSize: 12))
                  : null,
        ),
      ],
    );
  }
}

/// Lays nodes out on a gentle zigzag, like a trail.
class ZigzagPath extends StatelessWidget {
  const ZigzagPath({super.key, required this.children, this.header});
  final List<Widget> children;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 48),
      itemCount: children.length + (header == null ? 0 : 1),
      itemBuilder: (context, i) {
        if (header != null) {
          if (i == 0) return header!;
          i--;
        }
        final offset = sin(i * pi / 3) * 90;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Transform.translate(offset: Offset(offset, 0), child: Center(child: children[i])),
        );
      },
    );
  }
}

/// A circular progress ring around an emoji.
class ProgressEmoji extends StatelessWidget {
  const ProgressEmoji({super.key, required this.emoji, required this.progress, this.size = 64});
  final String emoji;
  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 5,
                color: progress >= 1 ? Colors.amber : Colors.green,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            Text(emoji, style: TextStyle(fontSize: size * 0.45)),
          ],
        ),
      );
}
