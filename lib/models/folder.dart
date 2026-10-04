/// A folder in the library. Folders can contain other folders,
/// which is how "Science > Chapter 1" works.
class Folder {
  const Folder({
    required this.id,
    required this.parentId,
    required this.name,
    this.childCount = 0,
  });

  final int id; // unique number the database gives each folder
  final int? parentId; // id of the folder this one sits inside; null = top level
  final String name;
  final int childCount; // how many subfolders it has (shown on the list)

  /// Builds a Folder from one row returned by the database.
  /// A row comes back as a Map, like {'id': 1, 'name': 'Science'}.
  factory Folder.fromMap(Map<String, Object?> map) {
    return Folder(
      id: map['id'] as int,
      parentId: map['parent_id'] as int?, // '?' because it can be null
      name: map['name'] as String,
      childCount: (map['child_count'] as int?) ?? 0, // '??' = "or 0 if null"
    );
  }
}