import '../models/folder.dart';
import 'database_helper.dart';

/// All the database questions about folders live here, so screens
/// never have to write SQL themselves.
class FolderRepository {
  /// Gets the folders directly inside [parentId].
  /// Pass null to get the top-level folders.
  Future<List<Folder>> getChildren(int? parentId) async {
    final db = await DatabaseHelper.instance.database;

    // In SQL, "= NULL" never matches; you must write "IS NULL".
    // So we pick the right wording depending on whether parentId is null.
    final rows = await db.rawQuery(
      '''
      SELECT f.id, f.parent_id, f.name,
        (SELECT COUNT(*) FROM folders c WHERE c.parent_id = f.id) AS child_count
      FROM folders f
      WHERE f.parent_id ${parentId == null ? 'IS NULL' : '= ?'}
      ORDER BY f.name COLLATE NOCASE
      ''',
      // The '?' above is filled in by this list (nothing when IS NULL).
      parentId == null ? [] : [parentId],
    );

    // Turn each database row into a Folder object.
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

  /// Deletes a folder AND everything inside it (thanks to CASCADE).
  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }
}