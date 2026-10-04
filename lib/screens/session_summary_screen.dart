import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/time_format.dart';

/// Shown when a study session ends: a cheerful headline and how long the
/// user studied.
class SessionSummaryScreen extends StatelessWidget {
  const SessionSummaryScreen({super.key, required this.duration});

  final Duration duration;

  // The headline and the small message below change with how long the
  // session lasted. inMinutes is the whole minutes (90 seconds = 1).
  String get _headline {
    final minutes = duration.inMinutes;
    if (minutes < 1) return 'NICE START!';
    if (minutes < 10) return 'GOOD JOB!';
    if (minutes < 30) return 'GREAT WORK!';
    return 'AMAZING!';
  }

  String get _message {
    final minutes = duration.inMinutes;
    if (minutes < 1) return 'Even a quick review helps.';
    if (minutes < 10) return 'Keep it up. Little and often beats cramming.';
    if (minutes < 30) return 'That was real focus. Be proud of that.';
    return 'Your future self says thank you.';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
          child: Column(
            children: [
              // Expanded + Center puts the message in the middle of the screen
              // and leaves the button at the bottom.
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        _headline,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'You studied for',
                        style: textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatSpoken(duration),
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _message,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  // Closes this screen. The study screen was replaced by this
                  // one, so this lands back on the folder.
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}