import 'package:flutter/material.dart';

import '../models/flashcard.dart';
import '../providers/study_session.dart';
import '../theme/app_theme.dart';
import '../widgets/card_face.dart';
import '../widgets/empty_state.dart';
import '../widgets/flip_card.dart';
import '../widgets/rating_buttons.dart';
import '../widgets/study_timer.dart';
import 'session_summary_screen.dart';

/// Study mode: shows one card at a time. Flip it, then rate how hard it was.
class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key, required this.title, required this.cards});

  final String title; // the folder name
  final List<Flashcard> cards;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  // The session holds the queue. The screen only displays it.
  late final StudySession _session = StudySession(widget.cards);

  // The stopwatch for the whole study session. '..start()' creates it and
  // starts it in one go. This line runs when the screen opens, which is
  // the moment the user taps Study.
  final Stopwatch _stopwatch = Stopwatch()..start();

  // Becomes true once the user has flipped to the answer. Only then do
  // the rating buttons appear.
  bool _answerSeen = false;

  // Each action changes the session, then setState redraws the screen.
  void _rate(Rating rating) {
    setState(() {
      _session.rate(rating);
      _answerSeen = false;
    });
  }

  void _shuffle() {
    setState(() {
      _session.shuffle();
      _answerSeen = false;
    });
  }

  void _setLoop(bool loop) {
    setState(() {
      _session.setLoop(loop);
      _answerSeen = false;
    });
  }

  /// Ends the study session: stops the stopwatch and shows the summary.
  void _finish() {
    _stopwatch.stop();
    // pushReplacement swaps THIS screen for the summary screen, so when the
    // user taps Done they land back on the folder (not on a finished session).
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SessionSummaryScreen(duration: _stopwatch.elapsed),
      ),
    );
  }

  /// The small grey line under the toggle.
  String get _status {
    if (_session.isFinished) return 'All done';
    if (_session.loop) return '${_session.total} cards · looping';
    return 'Card ${_session.doneCount + 1} of ${_session.total}';
  }

  @override
  Widget build(BuildContext context) {
    // PopScope intercepts "going back": both the arrow in the top bar and
    // the phone's own back button/gesture. canPop: false stops the normal
    // back; instead Flutter calls onPopInvokedWithResult, where we show the
    // summary. 'didPop' is false because we blocked it.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _finish();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            // The running timer pill.
            StudyTimer(stopwatch: _stopwatch),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Shuffle',
              icon: const Icon(Icons.shuffle_rounded),
              // null disables the button (nothing left to shuffle).
              onPressed: _session.isFinished ? null : _shuffle,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 4),
              _buildModeToggle(),
              const SizedBox(height: 10),
              Text(
                _status,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textMuted),
              ),
              Expanded(
                child: _session.isFinished ? _buildFinished() : _buildCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The "Play once | Loop" switch.
  Widget _buildModeToggle() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: false, label: Text('Play once')),
        ButtonSegment(value: true, label: Text('Loop')),
      ],
      selected: {_session.loop}, // a Set with the one selected value
      showSelectedIcon: false, // no tick mark, cleaner look
      onSelectionChanged: (selection) => _setLoop(selection.first),
      style: SegmentedButton.styleFrom(
        foregroundColor: AppColors.textMuted,
        selectedForegroundColor: AppColors.primary,
        selectedBackgroundColor: AppColors.primarySoft,
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }

  /// The flippable card, with the rating buttons (or a hint) underneath.
  Widget _buildCard() {
    final card = _session.current!; // '!' because we know it isn't finished

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: FlipCard(
              // A new key each turn makes Flutter build a fresh FlipCard,
              // so every new card starts on its front side.
              key: ValueKey(_session.turn),
              front: CardFace(label: 'QUESTION', text: card.front),
              back: CardFace(label: 'ANSWER', text: card.back, tinted: true),
              onFlip: (showingBack) {
                if (showingBack && !_answerSeen) {
                  setState(() => _answerSeen = true);
                }
              },
            ),
          ),
        ),
        // A fixed height so the card doesn't jump when the buttons appear.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            height: 56,
            child: _answerSeen
                ? RatingButtons(onRate: _rate)
                : Center(
                    child: Text(
                      'Tap the card to flip',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// Shown in Play once mode after the last card.
  Widget _buildFinished() {
    final summary = _session.summary;

    return Column(
      children: [
        Expanded(
          child: EmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'Session complete',
            message: 'You went through all ${_session.total} cards.'
                '${summary.isEmpty ? '' : '\n$summary'}',
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              // Calling _setLoop with the current mode = start over.
              // (The stopwatch keeps running: the session ends when you leave.)
              onPressed: () => _setLoop(_session.loop),
              child: const Text('Study again'),
            ),
          ),
        ),
      ],
    );
  }
}