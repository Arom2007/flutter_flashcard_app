import '../models/flashcard.dart';
import 'database_helper.dart';

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

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }
}