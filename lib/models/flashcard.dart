import 'image_overlay.dart';

/// One flashcard. A text card has a front and a back. An image card has
/// an [imagePath] and an [overlay] (boxes and text on the picture).
class Flashcard {
  const Flashcard({
    required this.id,
    required this.folderId,
    required this.front,
    required this.back,
    this.imagePath,
    this.overlay,
  });

  final int id;
  final int folderId; // the folder this card lives in
  final String front; // the question (empty for image cards)
  final String back; // the answer (empty for image cards)
  final String? imagePath; // image file name; null for text cards
  final ImageOverlay? overlay; // boxes + text on the image

  /// true for image cards.
  bool get isImage => imagePath != null;

  /// Builds a Flashcard from one row returned by the database.
  factory Flashcard.fromMap(Map<String, Object?> map) {
    return Flashcard(
      id: map['id'] as int,
      folderId: map['folder_id'] as int,
      front: map['front'] as String,
      back: map['back'] as String,
      imagePath: map['image_path'] as String?,
      overlay: ImageOverlay.tryParse(map['boxes'] as String?),
    );
  }
}