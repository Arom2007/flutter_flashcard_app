import 'dart:math';

import '../models/flashcard.dart';

/// How hard the user found a card. Each rating knows how many OTHER cards
/// should be shown before it comes back (a random number from minGap to
/// maxGap, inclusive).
enum Rating {
  veryHard('Very Hard', 2, 3),
  hard('Hard', 5, 6),
  medium('Medium', 10, 10),
  easy('Easy', 15, 20);

  const Rating(this.label, this.minGap, this.maxGap);

  final String label;
  final int minGap;
  final int maxGap;

  /// Picks a random gap in the range, e.g. 15, 16, ... or 20 for Easy.
  int pickGap(Random random) => minGap + random.nextInt(maxGap - minGap + 1);
}

/// The brain of study mode. It holds the queue of cards still to show;
/// the card at the front of the queue is the one on screen.
/// It has no UI code, so the screen just asks it questions and tells it
/// what happened.
class StudySession {
  StudySession(List<Flashcard> cards) : _all = List.of(cards) {
    restart();
  }

  final List<Flashcard> _all; // every card, never changes
  final _random = Random();
  late List<Flashcard> _queue; // cards still to show; first = current

  /// true = Loop, false = Play once.
  bool loop = true;

  /// Goes up by one every time the card on screen changes. The screen uses
  /// it to reset the flip, even if the same card appears twice in a row.
  int turn = 0;

  /// How many times each rating was pressed (shown in the summary).
  final Map<Rating, int> counts = {};

  Flashcard? get current => _queue.isEmpty ? null : _queue.first;
  bool get isFinished => _queue.isEmpty;
  int get total => _all.length;

  /// In Play once mode: how many cards are already done.
  int get doneCount => total - _queue.length;

  /// Starts again from the first card, in the original order.
  void restart() {
    _queue = List.of(_all);
    counts.clear();
    turn++;
  }

  /// Switching between Loop and Play once starts a fresh session.
  void setLoop(bool value) {
    loop = value;
    restart();
  }

  /// Randomly reorders the cards that are still in the queue.
  void shuffle() {
    _queue.shuffle(_random);
    turn++;
  }

  /// Called when the user presses Easy / Medium / Hard / Very Hard.
  void rate(Rating rating) {
    // Take the current card off the front of the queue.
    final card = _queue.removeAt(0);
    counts[rating] = (counts[rating] ?? 0) + 1;

    if (loop) {
      // Put it back after [gap] other cards. If the queue is shorter than
      // the gap, min() makes it go to the very end instead.
      final gap = rating.pickGap(_random);
      _queue.insert(min(gap, _queue.length), card);
    }
    // In Play once mode we simply don't put it back.

    turn++;
  }

  /// e.g. "Very Hard 1  ·  Medium 2" (only ratings that were used).
  String get summary {
    final parts = [
      for (final r in Rating.values)
        if ((counts[r] ?? 0) > 0) '${r.label} ${counts[r]}',
    ];
    return parts.join('  ·  ');
  }
}