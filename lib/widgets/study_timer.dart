import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/time_format.dart';

/// A small pill showing how long the Stopwatch has been running.
/// It owns its own Timer, so only this tiny widget redraws every tick,
/// not the whole study screen.
class StudyTimer extends StatefulWidget {
  const StudyTimer({super.key, required this.stopwatch});

  final Stopwatch stopwatch; // started and stopped by the study screen

  @override
  State<StudyTimer> createState() => _StudyTimerState();
}

class _StudyTimerState extends State<StudyTimer> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    // Every half second, tell Flutter to redraw this widget so the
    // displayed time updates. (Checking twice a second keeps the seconds
    // from visibly skipping.)
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  // Always stop the timer when the widget goes away.
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // only as wide as its contents
        children: [
          const Icon(Icons.timer_outlined, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            formatClock(widget.stopwatch.elapsed),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              // Makes every digit the same width so the pill doesn't wobble
              // as the numbers change.
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}