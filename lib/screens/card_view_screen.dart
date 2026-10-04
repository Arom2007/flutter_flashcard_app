import 'package:flutter/material.dart';

import '../models/flashcard.dart';
import '../theme/app_theme.dart';
import '../widgets/flip_card.dart';

/// Shows one card at a time, big. Tap to flip; swipe left/right to move
/// to the other cards in the folder.
class CardViewScreen extends StatefulWidget {
  const CardViewScreen({
    super.key,
    required this.cards,
    required this.initialIndex,
  });

  final List<Flashcard> cards;
  final int initialIndex; // which card to open on

  @override
  State<CardViewScreen> createState() => _CardViewScreenState();
}

class _CardViewScreenState extends State<CardViewScreen> {
  // A PageController lets us choose which page the PageView starts on.
  late final _pageController = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Shows e.g. "2 / 5".
      appBar: AppBar(title: Text('${_index + 1} / ${widget.cards.length}')),
      body: SafeArea(
        child: Column(
          children: [
            // Expanded = take all the leftover vertical space.
            Expanded(
              // PageView = swipeable pages, one per card.
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.cards.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final card = widget.cards[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: FlipCard(
                      // The key tells Flutter "this is card #id", so a flipped
                      // card never gets mixed up with a different one.
                      key: ValueKey(card.id),
                      front: _CardFace(label: 'QUESTION', text: card.front),
                      back: _CardFace(
                        label: 'ANSWER',
                        text: card.back,
                        tinted: true,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Tap the card to flip',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One side of the card: a small label at the top and the text centered.
class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.label,
    required this.text,
    this.tinted = false,
  });

  final String label;
  final String text;
  final bool tinted; // the answer side gets a soft blue background

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: tinted ? AppColors.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          Expanded(
            child: Center(
              // If the text is very long, the card scrolls instead of overflowing.
              child: SingleChildScrollView(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}