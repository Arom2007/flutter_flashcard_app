import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Opens the SQLite database and creates its tables the first time.
/// There is only ever one of these (a "singleton"), shared by the whole app.
class DatabaseHelper {
  // Private constructor: nobody else can create a DatabaseHelper.
  DatabaseHelper._();

  // The one shared instance. Use it as DatabaseHelper.instance.
  static final DatabaseHelper instance = DatabaseHelper._();

  // Remembers the "opening the database" job so it only happens once,
  // even if two screens ask for the database at the same moment.
  Future<Database>? _opening;

  /// Anyone who needs the database does: await DatabaseHelper.instance.database
  /// '??=' means "if _opening is empty, start opening it now".
  Future<Database> get database => _opening ??= _open();

  Future<Database> _open() async {
    // The phone's private folder for databases, then our file name.
    final folder = await getDatabasesPath();
    final path = join(folder, 'flashcards.db');

    return openDatabase(
      path,
      version: 1, // bump this number later when the tables change
      // Runs every time the database opens. Foreign keys are OFF by default
      // in SQLite; turning them on is what makes "delete a folder" also
      // delete everything inside it.
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      // Runs only the very first time, when the file doesn't exist yet.
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Folders. parent_id points at another folder (or is NULL at top level).
    // ON DELETE CASCADE = deleting a folder deletes its subfolders too.
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parent_id INTEGER REFERENCES folders(id) ON DELETE CASCADE,
        name TEXT NOT NULL
      )
    ''');

    // Decks live inside a folder. Not used by the screens yet.
    await db.execute('''
      CREATE TABLE decks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_id INTEGER NOT NULL REFERENCES folders(id) ON DELETE CASCADE,
        name TEXT NOT NULL
      )
    ''');

    // Flashcards live inside a deck. Not used by the screens yet.
    // image_path and boxes are for the image-occlusion stage.
    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deck_id INTEGER NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
        front TEXT NOT NULL DEFAULT '',
        back TEXT NOT NULL DEFAULT '',
        image_path TEXT,
        boxes TEXT
      )
    ''');
  }
}