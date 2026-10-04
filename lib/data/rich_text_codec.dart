import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart' show Document;

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

  /// Just the words, with no formatting. Used for list previews.
  static String plainText(String stored) =>
      toDocument(stored).toPlainText().trim();
}