import '../models/flashcard.dart';
import 'database_helper.dart';
import 'image_store.dart';

/// All the database questions about cards live here.
class CardRepository {
  /// Gets every card in a folder, oldest first.
  Future<List<Flashcard>> getForFolder(int folderId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'cards',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'id',
    );
    return rows.map(Flashcard.fromMap).toList();
  }

  /// Every card in the app (used by search).
  Future<List<Flashcard>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('cards', orderBy: 'id');
    return rows.map(Flashcard.fromMap).toList();
  }

  Future<void> create(int folderId, String front, String back) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('cards', {
      'folder_id': folderId,
      'front': front,
      'back': back,
    });
  }

  Future<void> update(int id, String front, String back) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'cards',
      {'front': front, 'back': back},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Adds an image card. [imageName] is the file name from ImageStore.save,
  /// [overlayJson] is ImageOverlay.toJsonString(). The card's [title] is
  /// stored in the 'front' column, which image cards don't otherwise use.
  Future<void> createImageCard(
    int folderId,
    String title,
    String imageName,
    String overlayJson,
  ) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('cards', {
      'folder_id': folderId,
      'front': title,
      'image_path': imageName,
      'boxes': overlayJson,
    });
  }

  /// Saves a new title and new boxes/text for an existing image card.
  Future<void> updateImageCard(int id, String title, String overlayJson) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'cards',
      {'front': title, 'boxes': overlayJson},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    // Remember the image name first, so the picture file can be removed too.
    final rows = await db.query(
      'cards',
      columns: ['image_path'],
      where: 'id = ?',
      whereArgs: [id],
    );
    await db.delete('cards', where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      final name = rows.first['image_path'] as String?;
      if (name != null) await ImageStore.instance.delete(name);
    }
  }
}