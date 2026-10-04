import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Opens the SQLite database and creates/updates its tables.
/// There is only ever one of these (a "singleton"), shared by the whole app.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Future<Database>? _opening;

  /// Anyone who needs the database does: await DatabaseHelper.instance.database
  Future<Database> get database => _opening ??= _open();

  Future<Database> _open() async {
    final folder = await getDatabasesPath();
    final path = join(folder, 'flashcards.db');

    return openDatabase(
      path,
      version: 2, // was 1. Raising it triggers onUpgrade on existing phones.
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
          // Version 1 had 'decks' and 'cards' tables that were never used.
          // Drop them and create the new 'cards' table. Folders are untouched.
          // (cards first, because it pointed at decks)
          await db.execute('DROP TABLE IF EXISTS cards');
          await db.execute('DROP TABLE IF EXISTS decks');
          await _createCardsTable(db);
        }
      },
    );
  }

  Future<void> _createFoldersTable(Database db) async {
    // parent_id points at another folder (or is NULL at top level).
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parent_id INTEGER REFERENCES folders(id) ON DELETE CASCADE,
        name TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createCardsTable(Database db) async {
    // Each card belongs to one folder. image_path and boxes stay empty
    // until the image stage, but creating them now avoids another upgrade.
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