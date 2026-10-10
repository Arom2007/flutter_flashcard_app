import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart' show Document;

import '../models/flashcard.dart';

/// Converts between what's stored in the database (a text string) and the
/// Quill "Document" the editor works with.
///
/// New cards are stored as Quill's "Delta" format written as JSON, e.g.
/// [{"insert":"Hello","attributes":{"bold":true}},{"insert":"\n"}].
/// Cards made in earlier stages hold plain text, so we handle both.
class RichTextCodec {
  /// Stored string -> Document.
  static Document toDocument(String stored) {
    try {
      final decoded = jsonDecode(stored); // throws if it's not JSON
      if (decoded is List && decoded.isNotEmpty) {
        return Document.fromJson(decoded);
      }
    } catch (_) {
      // Not valid rich text: fall through and treat it as plain text.
    }
    final doc = Document(); // an empty document
    if (stored.isNotEmpty) doc.insert(0, stored); // put the plain text in
    return doc;
  }

  /// Document -> string to save in the database.
  static String encode(Document doc) => jsonEncode(doc.toDelta().toJson());

  /// Just the words, with no formatting. Used for list names and search.
  /// This reads the JSON directly instead of building a Document, which
  /// makes it much faster for long cards.
  static String plainText(String stored) {
    try {
      final decoded = jsonDecode(stored);
      if (decoded is List &&
          decoded.isNotEmpty &&
          decoded.every((op) => op is Map && op.containsKey('insert'))) {
        final buffer = StringBuffer();
        for (final op in decoded) {
          final insert = (op as Map)['insert'];
          if (insert is String) buffer.write(insert); // skip embeds
        }
        return buffer.toString().trim();
      }
    } catch (_) {
      // Not JSON: it's an old plain-text card.
    }
    return stored.trim();
  }

  /// The name shown for a card in lists: the question for text cards,
  /// the title for image cards.
  static String cardTitle(Flashcard card) {
    if (card.isImage) {
      final title = card.front.trim();
      return title.isEmpty ? 'Image card' : title;
    }
    final text = plainText(card.front);
    return text.isEmpty ? 'Untitled card' : text;
  }
}