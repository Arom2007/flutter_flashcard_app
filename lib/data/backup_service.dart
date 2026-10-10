import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart'
    show Archive, InputFileStream, ZipDecoder, ZipFileEncoder, extractArchiveToDisk;
import 'package:flutter/painting.dart' show imageCache;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database_helper.dart';
import 'font_service.dart';
import 'image_store.dart';

/// A problem we can explain to the user in plain words.
class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Makes a backup of everything (database, pictures, fonts) as one .zip
/// file, and restores from one.
class BackupService {
  BackupService._();

  static final BackupService instance = BackupService._();

  static const _manifestName = 'manifest.json';
  static const _dbName = DatabaseHelper.fileName;
  static const _notABackup = 'That file isn\'t a CrashCards backup.';

  // ---------------------------------------------------------------------
  // BACKUP
  // ---------------------------------------------------------------------

  /// Builds the backup zip and returns its path. The caller shares it.
  Future<String> createBackup() async {
    final docs = await getApplicationDocumentsDirectory();
    final temp = await getTemporaryDirectory();

    // Clear leftovers from earlier backups.
    final staging = Directory(p.join(temp.path, 'backup_staging'));
    await _deleteDir(staging);
    await for (final entity in temp.list()) {
      if (entity is File &&
          p.basename(entity.path).startsWith('CrashCards-backup-')) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
    await staging.create(recursive: true);

    try {
      // 1. The database. Closing it first makes sure every change has
      //    been written into the file. It reopens by itself afterwards.
      final dbPath = await DatabaseHelper.instance.path;
      await DatabaseHelper.instance.close();
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        throw const BackupException('There is nothing to back up yet.');
      }
      await dbFile.copy(p.join(staging.path, _dbName));

      // 2. Pictures and fonts.
      await _copyFlatDir(
        Directory(p.join(docs.path, 'images')),
        Directory(p.join(staging.path, 'images')),
      );
      await _copyFlatDir(
        Directory(p.join(docs.path, 'fonts')),
        Directory(p.join(staging.path, 'fonts')),
      );

      // 3. A small note describing the backup, checked again on restore.
      await File(p.join(staging.path, _manifestName)).writeAsString(
        jsonEncode({
          'app': 'CrashCards',
          'format': 1,
          'dbVersion': DatabaseHelper.schemaVersion,
          'created': DateTime.now().toIso8601String(),
        }),
      );

      // 4. Zip it all up.
      String two(int n) => n.toString().padLeft(2, '0');
      final now = DateTime.now();
      final zipPath = p.join(
        temp.path,
        'CrashCards-backup-${now.year}-${two(now.month)}-${two(now.day)}.zip',
      );
      await ZipFileEncoder().zipDirectory(staging, filename: zipPath);
      return zipPath;
    } finally {
      await _deleteDir(staging);
    }
  }

  Future<void> _copyFlatDir(Directory from, Directory to) async {
    if (!await from.exists()) return;
    await to.create(recursive: true);
    await for (final entity in from.list()) {
      if (entity is File) {
        await entity.copy(p.join(to.path, p.basename(entity.path)));
      }
    }
  }

  // ---------------------------------------------------------------------
  // RESTORE
  // ---------------------------------------------------------------------

  /// Replaces everything in the app with the contents of the backup at
  /// [zipPath]. If anything goes wrong, the old data is put back.
  Future<void> restore(String zipPath) async {
    final docs = await getApplicationDocumentsDirectory();
    final work = Directory(p.join(docs.path, 'restore_tmp'));
    final aside = Directory(p.join(docs.path, 'restore_old'));
    await _deleteDir(work);
    await _deleteDir(aside);
    await work.create(recursive: true);

    try {
      final root = await _unpack(zipPath, work); // 1. unzip + safety checks
      await _validate(root); // 2. is it really a CrashCards backup?
      await _install(root, docs, aside); // 3. swap it in (with undo)
    } finally {
      await _deleteDir(work);
    }

    // Tell the rest of the app that files changed.
    await ImageStore.instance.init();
    await FontService.instance.reload();
    imageCache.clear(); // forget pictures remembered from before
  }

  /// Unzips into [work] and returns the folder that holds manifest.json.
  Future<Directory> _unpack(String zipPath, Directory work) async {
    final input = InputFileStream(zipPath);
    try {
      final Archive archive;
      try {
        archive = ZipDecoder().decodeStream(input);
      } catch (_) {
        throw const BackupException(_notABackup);
      }

      // Look at every name BEFORE extracting anything: refuse names that
      // try to escape the work folder, and find where manifest.json is.
      String? prefix;
      for (final entry in archive) {
        final name = entry.name.replaceAll('\\', '/');
        if (name.startsWith('/') || name.split('/').contains('..')) {
          throw const BackupException(
            'This backup file looks unsafe, so it was not opened.',
          );
        }
        if (entry.isFile &&
            (name == _manifestName || name.endsWith('/$_manifestName'))) {
          prefix = name.substring(0, name.length - _manifestName.length);
        }
      }
      if (prefix == null) throw const BackupException(_notABackup);

      extractArchiveToDisk(archive, work.path);
      return Directory(p.join(work.path, prefix));
    } finally {
      await input.close();
    }
  }

  Future<void> _validate(Directory root) async {
    final manifestFile = File(p.join(root.path, _manifestName));
    final dbFile = File(p.join(root.path, _dbName));
    if (!await manifestFile.exists() || !await dbFile.exists()) {
      throw const BackupException(_notABackup);
    }

    try {
      final manifest = jsonDecode(await manifestFile.readAsString());
      if (manifest is! Map || manifest['app'] != 'CrashCards') {
        throw const BackupException(_notABackup);
      }
      final version = manifest['dbVersion'];
      if (version is! int || version > DatabaseHelper.schemaVersion) {
        throw const BackupException(
          'This backup was made by a newer version of CrashCards. '
          'Please update the app first.',
        );
      }
    } on FormatException {
      throw const BackupException(_notABackup);
    }

    // Every SQLite file starts with these 16 bytes.
    final raf = await dbFile.open();
    final head = await raf.read(16);
    await raf.close();
    if (String.fromCharCodes(head) != 'SQLite format 3\u0000') {
      throw const BackupException(_notABackup);
    }
  }

  /// Moves today's data aside, puts the backup in its place, and checks
  /// that the database opens. On any failure everything is put back.
  Future<void> _install(Directory root, Directory docs, Directory aside) async {
    final dbPath = await DatabaseHelper.instance.path;
    final imagesPath = p.join(docs.path, 'images');
    final fontsPath = p.join(docs.path, 'fonts');
    const sidecars = ['-wal', '-shm', '-journal'];

    await DatabaseHelper.instance.close();
    await aside.create(recursive: true);

    var installStarted = false;
    try {
      // Step 1: move the current data out of the way.
      await _moveIfExists(dbPath, p.join(aside.path, _dbName));
      await _moveIfExists(imagesPath, p.join(aside.path, 'images'));
      await _moveIfExists(fontsPath, p.join(aside.path, 'fonts'));
      for (final s in sidecars) {
        await _deleteFile('$dbPath$s');
      }

      // Step 2: put the backup's data in place.
      installStarted = true;
      await _moveIfExists(p.join(root.path, _dbName), dbPath);
      await _moveOrCreateDir(p.join(root.path, 'images'), imagesPath);
      await _moveOrCreateDir(p.join(root.path, 'fonts'), fontsPath);

      // Step 3: prove the restored database really opens and reads.
      final db = await DatabaseHelper.instance.database;
      await db.rawQuery('SELECT COUNT(*) FROM folders');
      await db.rawQuery('SELECT COUNT(*) FROM cards');
    } catch (_) {
      // Something failed: undo everything.
      var rolledBack = false;
      try {
        await DatabaseHelper.instance.close();
        if (installStarted) {
          // Throw away the half-installed backup data...
          await _deleteFile(dbPath);
          for (final s in sidecars) {
            await _deleteFile('$dbPath$s');
          }
          await _deleteDir(Directory(imagesPath));
          await _deleteDir(Directory(fontsPath));
        }
        // ...and bring back the original data.
        await _moveIfExists(p.join(aside.path, _dbName), dbPath);
        await _moveIfExists(p.join(aside.path, 'images'), imagesPath);
        await _moveIfExists(p.join(aside.path, 'fonts'), fontsPath);
        await _deleteDir(aside);
        rolledBack = true;
      } catch (_) {}
      throw BackupException(
        rolledBack
            ? 'Restore failed. Your previous data was kept.'
            : 'Restore failed, and your previous data may be incomplete.',
      );
    }

    // All good: the old data isn't needed any more.
    await _deleteDir(aside);
  }

  // ---------------------------------------------------------------------
  // small file helpers
  // ---------------------------------------------------------------------

  Future<void> _moveIfExists(String from, String to) async {
    final type = FileSystemEntity.typeSync(from);
    if (type == FileSystemEntityType.notFound) return;
    final FileSystemEntity entity =
        type == FileSystemEntityType.directory ? Directory(from) : File(from);
    try {
      await entity.rename(to);
    } on FileSystemException {
      // Renaming can fail across storage areas. For a single file we can
      // copy it and delete the original instead.
      if (entity is File) {
        await entity.copy(to);
        await entity.delete();
      } else {
        rethrow;
      }
    }
  }

  /// Moves a folder into place, or makes an empty one if the backup had none.
  Future<void> _moveOrCreateDir(String from, String to) async {
    if (FileSystemEntity.typeSync(from) == FileSystemEntityType.notFound) {
      await Directory(to).create(recursive: true);
    } else {
      await _moveIfExists(from, to);
    }
  }

  Future<void> _deleteDir(Directory dir) async {
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  Future<void> _deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}