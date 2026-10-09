import 'package:flutter/material.dart';

import '../data/image_store.dart';
import '../models/flashcard.dart';
import '../models/image_overlay.dart';
import 'occlusion_image_view.dart';

/// An image card in study mode / the card viewer: the picture with its
/// boxes, plus a "Reveal all / Hide all" button. There is no flipping.
/// It remembers which boxes are uncovered; every new card starts covered.
class ImageStudyCard extends StatefulWidget {
  const ImageStudyCard({super.key, required this.card});

  final Flashcard card;

  @override
  State<ImageStudyCard> createState() => _ImageStudyCardState();
}

class _ImageStudyCardState extends State<ImageStudyCard> {
  // Indexes of the boxes that are currently uncovered.
  final Set<int> _revealed = {};

  ImageOverlay get _overlay =>
      widget.card.overlay ?? const ImageOverlay(aspect: 1);

  bool get _allRevealed =>
      _overlay.boxes.isNotEmpty && _revealed.length == _overlay.boxes.length;

  void _toggle(int index) {
    setState(() {
      // add() returns false if it was already there: then remove it instead.
      if (!_revealed.add(index)) _revealed.remove(index);
    });
  }

  void _toggleAll() {
    setState(() {
      if (_allRevealed) {
        _revealed.clear(); // cover everything again
      } else {
        _revealed
          ..clear()
          ..addAll(List.generate(_overlay.boxes.length, (i) => i));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final file = ImageStore.instance.fileFor(widget.card.imagePath!);

    return Column(
      children: [
        Expanded(
          child: OcclusionImageView(
            file: file,
            overlay: _overlay,
            revealed: _revealed,
            onToggle: _toggle,
          ),
        ),
        // Only show the button if there is at least one box to reveal.
        if (_overlay.boxes.isNotEmpty) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _toggleAll,
            icon: Icon(
              _allRevealed
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
            ),
            label: Text(_allRevealed ? 'Hide all' : 'Reveal all'),
          ),
        ],
      ],
    );
  }
}