import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show QuillController, QuillEditor, QuillEditorConfig;

import '../data/rich_text_codec.dart';

/// Shows formatted card text, read-only (no cursor, no typing).
/// Pass the string stored in the database as [content].
class RichContent extends StatefulWidget {
  const RichContent({super.key, required this.content});

  final String content;

  @override
  State<RichContent> createState() => _RichContentState();
}

class _RichContentState extends State<RichContent> {
  // The controller holds the document being shown.
  late final QuillController _controller = _build();

  QuillController _build() {
    final controller = QuillController.basic();
    controller.document = RichTextCodec.toDocument(widget.content);
    controller.readOnly = true; // viewing only
    return controller;
  }

  // If a different content string is passed in later, show that instead.
  @override
  void didUpdateWidget(RichContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _controller.document = RichTextCodec.toDocument(widget.content);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // IgnorePointer makes the editor ignore all touches. That's important:
    // otherwise it would swallow the tap that is supposed to flip the card.
    return IgnorePointer(
      child: QuillEditor.basic(
        controller: _controller,
        // scrollable: false = the editor is as tall as its text, so the
        // card's own scroll view handles very long text.
        config: const QuillEditorConfig(scrollable: false, showCursor: false),
      ),
    );
  }
}