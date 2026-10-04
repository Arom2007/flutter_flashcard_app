import 'dart:math'; // gives us 'pi' (half a turn, in radians)

import 'package:flutter/material.dart';

/// Shows [front]. When tapped, it flips around like a real card
/// and shows [back]. Tap again to flip back.
class FlipCard extends StatefulWidget {
  const FlipCard({super.key, required this.front, required this.back});

  final Widget front;
  final Widget back;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

// 'with SingleTickerProviderStateMixin' lets this widget drive an animation
// (it provides the "ticks" that fire every frame).
class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  // The controller runs a number from 0 to 1 over 450 milliseconds.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  // Turns that 0..1 into 0..pi (a half turn) and eases the start/end
  // so the motion feels smooth instead of robotic.
  late final Animation<double> _angle = Tween<double>(begin: 0, end: pi)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  // Always free the controller when the widget goes away.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    // If we're showing (or heading to) the back, go back to the front.
    // Otherwise go to the back. Works even if tapped mid-flip.
    if (_controller.isForwardOrCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      behavior: HitTestBehavior.opaque,
      // AnimatedBuilder redraws only this part every frame of the animation.
      child: AnimatedBuilder(
        animation: _angle,
        builder: (context, _) {
          final angle = _angle.value;
          // Past the halfway point the card is edge-on, so swap to the back.
          final showBack = angle > pi / 2;

          return Transform(
            alignment: Alignment.center, // spin around the middle
            // setEntry(3, 2, 0.001) adds a little 3D perspective.
            // rotateY spins the card around its vertical axis.
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showBack
                // The back would appear mirrored after the half turn,
                // so we rotate it another half turn to read normally.
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