import 'dart:math'; // gives us 'pi' (half a turn, in radians)

import 'package:flutter/material.dart';

/// Shows [front]. When tapped, it flips around like a real card
/// and shows [back]. Tap again to flip back.
class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.onFlip,
  });

  final Widget front;
  final Widget back;

  /// Optional. Called every time the card is tapped: true if it is now
  /// turning to the back, false if it is turning back to the front.
  final ValueChanged<bool>? onFlip;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

// 'with SingleTickerProviderStateMixin' lets this widget drive an animation.
class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  late final Animation<double> _angle = Tween<double>(begin: 0, end: pi)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_controller.isForwardOrCompleted) {
      _controller.reverse();
      widget.onFlip?.call(false); // '?.call' = only if a callback was given
    } else {
      _controller.forward();
      widget.onFlip?.call(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _angle,
        builder: (context, _) {
          final angle = _angle.value;
          final showBack = angle > pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(pi),
                    child: widget.back,
                  )
                : widget.front,
          );
        },
      ),
    );
  }
}