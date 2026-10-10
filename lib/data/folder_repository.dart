import '../models/folder.dart';
import 'database_helper.dart';
import 'image_store.dart';

/// All the database questions about folders live here, so screens
/// never have to write SQL themselves.
class FolderRepository {
  /// Gets the folders directly inside [parentId].
  /// Pass null to get the top-level folders.
  Future<List<Folder>> getChildren(int? parentId) async {
    final db = await DatabaseHelper.instance.database;

    // In SQL, "= NULL" never matches; you must write "IS NULL".
    final rows = await db.rawQuery(
      '''
      SELECT f.id, f.parent_id, f.name,
        (SELECT COUNT(*) FROM folders c WHERE c.parent_id = f.id) AS child_count
      FROM folders f
      WHERE f.parent_id ${parentId == null ? 'IS NULL' : '= ?'}
      ORDER BY f.name COLLATE NOCASE
      ''',
      parentId == null ? [] : [parentId],
    );

    return rows.map(Folder.fromMap).toList();
  }

  /// Every folder in the app, at any depth (used by search).
  Future<List<Folder>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('folders', orderBy: 'name COLLATE NOCASE');
    return rows.map(Folder.fromMap).toList();
  }

  /// Adds a new folder inside [parentId] (null = top level).
  Future<void> create(String name, int? parentId) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('folders', {'name': name, 'parent_id': parentId});
  }

  /// Changes a folder's name.
  Future<void> rename(int id, String name) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('folders', {'name': name}, where: 'id = ?', whereArgs: [id]);
  }

  /// Deletes a folder AND everything inside it (thanks to CASCADE),
  /// including the picture files of its image cards.
  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;

    // First find every picture inside this folder and all its subfolders.
    // 'WITH RECURSIVE' walks down the tree: the folder itself, then its
    // children, then their children, and so on.
    final rows = await db.rawQuery(
      '''
      WITH RECURSIVE tree(id) AS (
        SELECT id FROM folders WHERE id = ?
        UNION ALL
        SELECT f.id FROM folders f JOIN tree t ON f.parent_id = t.id
      )
      SELECT image_path FROM cards
      WHERE image_path IS NOT NULL AND folder_id IN (SELECT id FROM tree)
      ''',
      [id],
    );

    await db.delete('folders', where: 'id = ?', whereArgs: [id]);

    // Only after the rows are gone, remove the picture files.
    for (final row in rows) {
      final name = row['image_path'] as String?;
      if (name != null) await ImageStore.instance.delete(name);
    }
  }
}