import 'package:flutter/material.dart';

import '../data/card_repository.dart';
import '../models/flashcard.dart';

/// Used for both adding a card and editing one.
/// If [card] is given we are editing it; if it's null we're adding a new one.
class CardEditorScreen extends StatefulWidget {
  const CardEditorScreen({super.key, required this.folderId, this.card});

  final int folderId;
  final Flashcard? card;

  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<CardEditorScreen> {
  final _repo = CardRepository();

  // Controllers hold what's typed in each box. When editing, they start
  // with the card's existing text.
  late final _front = TextEditingController(text: widget.card?.front ?? '');
  late final _back = TextEditingController(text: widget.card?.back ?? '');

  bool get _isEditing => widget.card != null;

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final front = _front.text.trim();
    final back = _back.text.trim();

    // Don't allow a half-empty card.
    if (front.isEmpty || back.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both sides')),
      );
      return;
    }

    if (_isEditing) {
      await _repo.update(widget.card!.id, front, back);
    } else {
      await _repo.create(widget.folderId, front, back);
    }

    if (!mounted) return;
    // Close this screen and tell the previous one "something was saved".
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.titleMedium;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit card' : 'New card')),
      // SingleChildScrollView lets the screen scroll when the keyboard
      // takes up half the display.
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Front (question)', style: labelStyle),
            const SizedBox(height: 8),
            TextField(
              controller: _front,
              autofocus: !_isEditing,
              minLines: 3,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'What do you want to remember?'),
            ),
            const SizedBox(height: 20),
            Text('Back (answer)', style: labelStyle),
            const SizedBox(height: 8),
            TextField(
              controller: _back,
              minLines: 3,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'The answer'),
            ),
            const SizedBox(height: 28),
            // SizedBox with infinite width makes the button full width.
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(_isEditing ? 'Save changes' : 'Add card'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}