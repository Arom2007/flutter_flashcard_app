import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:path/path.dart' as p; // 'as p' = we write p.join(...), p.extension(...)
import 'package:path_provider/path_provider.dart';

/// Keeps track of fonts the user imported. Font files are copied into the
/// app's private folder, and registered with Flutter so text can use them.
/// One shared instance, like DatabaseHelper.
class FontService {
  FontService._();

  static final FontService instance = FontService._();

  // Names of the fonts that are loaded and ready to use.
  final List<String> _families = [];

  /// The imported font names (read-only copy).
  List<String> get families => List.unmodifiable(_families);

  /// Only .ttf and .otf files are accepted.
  static bool _isFontName(String name) {
    final ext = p.extension(name).toLowerCase();
    return ext == '.ttf' || ext == '.otf';
  }

  /// The private "fonts" folder inside the app's storage (created if missing).
  Future<Directory> _fontsDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'fonts'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Called once when the app starts: loads every font saved earlier.
  Future<void> init() async {
    try {
      final dir = await _fontsDirectory();
      final files = dir
          .listSync()
          .whereType<File>() // keep only files (not sub-folders)
          .where((f) => _isFontName(f.path))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      for (final file in files) {
        await _register(file);
      }
    } catch (_) {
      // A problem with fonts should never stop the app from opening.
    }
  }

  /// Teaches Flutter about one font file. Returns its name, or null if the
  /// file couldn't be loaded.
  Future<String?> _register(File file) async {
    // The font's name is the file name without ".ttf", e.g. "Lobster-Regular".
    final family = p.basenameWithoutExtension(file.path);
    try {
      final bytes = await file.readAsBytes();
      // FontLoader registers font data under a name. After load(), any
      // TextStyle(fontFamily: family) in the whole app can use it.
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
      if (!_families.contains(family)) _families.add(family);
      return family;
    } catch (_) {
      return null;
    }
  }

  /// Lets the user pick a font file, copies it into the app, and loads it.
  /// Returns the font's name, or null if the user cancelled.
  /// Throws a FormatException (with a readable message) if the file is bad.
  Future<String?> importFont() async {
    // We accept any file type here and check the extension ourselves,
    // because Android's picker doesn't recognise font types reliably.
    final picked = await FilePicker.pickFiles(type: FileType.any);
    if (picked.isEmpty) return null; // user backed out

    final file = picked.first;
    if (!_isFontName(file.name)) {
      throw const FormatException('Please choose a .ttf or .otf font file.');
    }
    final sourcePath = file.path;
    if (sourcePath == null) {
      throw const FormatException('Couldn\'t read that file.');
    }

    final family = p.basenameWithoutExtension(file.name);
    if (_families.contains(family)) return family; // already imported

    final dir = await _fontsDirectory();
    final copy = await File(sourcePath).copy(p.join(dir.path, file.name));
    final registered = await _register(copy);
    if (registered == null) {
      await copy.delete(); // don't keep a broken font
      throw const FormatException('That font file couldn\'t be loaded.');
    }
    return registered;
  }
}