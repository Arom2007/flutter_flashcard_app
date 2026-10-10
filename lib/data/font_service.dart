import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Keeps track of fonts the user imported. Font files are copied into the
/// app's private folder, and registered with Flutter so text can use them.
class FontService {
  FontService._();

  static final FontService instance = FontService._();

  final List<String> _families = [];

  /// The imported font names (read-only copy).
  List<String> get families => List.unmodifiable(_families);

  /// Only .ttf and .otf files are accepted.
  static bool _isFontName(String name) {
    final ext = p.extension(name).toLowerCase();
    return ext == '.ttf' || ext == '.otf';
  }

  Future<Directory> _fontsDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'fonts'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Called when the app starts: loads every font saved earlier.
  Future<void> init() async {
    try {
      final dir = await _fontsDirectory();
      final files = dir
          .listSync()
          .whereType<File>()
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

  /// Forgets the list and loads the fonts again (used after a restore,
  /// when the fonts folder has been replaced).
  Future<void> reload() async {
    _families.clear();
    await init();
  }

  Future<String?> _register(File file) async {
    final family = p.basenameWithoutExtension(file.path);
    try {
      final bytes = await file.readAsBytes();
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
    final picked = await FilePicker.pickFiles(type: FileType.any);
    if (picked.isEmpty) return null;

    final file = picked.first;
    if (!_isFontName(file.name)) {
      throw const FormatException('Please choose a .ttf or .otf font file.');
    }
    final sourcePath = file.path;
    if (sourcePath == null) {
      throw const FormatException('Couldn\'t read that file.');
    }

    final family = p.basenameWithoutExtension(file.name);
    if (_families.contains(family)) return family;

    final dir = await _fontsDirectory();
    final copy = await File(sourcePath).copy(p.join(dir.path, file.name));
    final registered = await _register(copy);
    if (registered == null) {
      await copy.delete();
      throw const FormatException('That font file couldn\'t be loaded.');
    }
    return registered;
  }
}