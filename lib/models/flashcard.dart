/// One flashcard: a question on the front and an answer on the back.
class Flashcard {
  const Flashcard({
    required this.id,
    required this.folderId,
    required this.front,
    required this.back,
  });

  final int id;
  final int folderId; // the folder this card lives in
  final String front; // the question
  final String back; // the answer

  /// Builds a Flashcard from one row returned by the database.
  factory Flashcard.fromMap(Map<String, Object?> map) {
    return Flashcard(
      id: map['id'] as int,
      folderId: map['folder_id'] as int,
      front: map['front'] as String,
      back: map['back'] as String,
    );
  }
}