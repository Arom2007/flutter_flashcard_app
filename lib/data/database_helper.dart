import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Opens the SQLite database and creates/updates its tables.
/// There is only ever one of these (a "singleton"), shared by the whole app.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  /// Raise this when the tables change. Backups remember it too.
  static const int schemaVersion = 2;
  static const String fileName = 'flashcards.db';

  Future<Database>? _opening;

  /// Where the database file lives on the phone.
  Future<String> get path async => join(await getDatabasesPath(), fileName);

  /// Anyone who needs the database does: await DatabaseHelper.instance.database
  Future<Database> get database => _opening ??= _openGuarded();

  // If opening fails, forget the failure so the next call can try again
  // (otherwise the same error would be returned forever).
  Future<Database> _openGuarded() async {
    try {
      return await _open();
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  /// Closes the database. Backup does this so every change is written to
  /// the file before it's copied. The next 'database' call reopens it.
  Future<void> close() async {
    final opening = _opening;
    _opening = null;
    if (opening == null) return;
    try {
      final db = await opening;
      await db.close();
    } catch (_) {
      // Nothing to close, or it failed to open in the first place.
    }
  }

  Future<Database> _open() async {
    return openDatabase(
      await path,
      version: schemaVersion,
      onConfigure: (db) async {
        // Makes "delete a folder" also delete its subfolders and cards.
        await db.execute('PRAGMA foreign_keys = ON');
      },
      // Runs only on a brand-new install (no database file yet).
      onCreate: (db, version) async {
        await _createFoldersTable(db);
        await _createCardsTable(db);
      },
      // Runs when the phone has an older version of the database.
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS cards');
          await db.execute('DROP TABLE IF EXISTS decks');
          await _createCardsTable(db);
        }
      },
    );
  }

  Future<void> _createFoldersTable(Database db) async {
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parent_id INTEGER REFERENCES folders(id) ON DELETE CASCADE,
        name TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createCardsTable(Database db) async {
    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_id INTEGER NOT NULL REFERENCES folders(id) ON DELETE CASCADE,
        front TEXT NOT NULL DEFAULT '',
        back TEXT NOT NULL DEFAULT '',
        image_path TEXT,
        boxes TEXT
      )
    ''');
  }
}