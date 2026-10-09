import 'package:flutter/material.dart';

import '../models/flashcard.dart';
import '../theme/app_theme.dart';
import '../widgets/card_face.dart';
import '../widgets/flip_card.dart';
import '../widgets/image_study_card.dart';

/// Shows one card at a time, big. Text cards flip when tapped; image cards
/// let you tap their boxes. Swipe left/right to move between cards.
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
  late final _pageController = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The hint under the card depends on which kind of card is showing.
    final hint = widget.cards[_index].isImage
        ? 'Tap a box to reveal it'
        : 'Tap the card to flip';

    return Scaffold(
      appBar: AppBar(title: Text('${_index + 1} / ${widget.cards.length}')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.cards.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final card = widget.cards[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: card.isImage
                        ? ImageStudyCard(key: ValueKey(card.id), card: card)
                        : FlipCard(
                            key: ValueKey(card.id),
                            front:
                                CardFace(label: 'QUESTION', text: card.front),
                            back: CardFace(
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
                hint,
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