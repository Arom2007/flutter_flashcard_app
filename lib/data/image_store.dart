import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Picks images from the gallery and keeps card images in the app's
/// private folder. The database only remembers each file's NAME.
class ImageStore {
  ImageStore._();

  static final ImageStore instance = ImageStore._();

  // 'late' = "I promise to set this before it's used" (init() does that).
  late Directory _dir;

  /// Called once when the app starts.
  Future<void> init() async {
    final docs = await getApplicationDocumentsDirectory();
    _dir = Directory(p.join(docs.path, 'images'));
    if (!await _dir.exists()) await _dir.create(recursive: true);
  }

  /// The file for a saved image name.
  File fileFor(String name) => File(p.join(_dir.path, name));

  /// Opens the gallery. Returns the picked image's temporary path, or null
  /// if the user cancelled. The picker shrinks big photos to 1600px.
  Future<String?> pickFromGallery() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 88,
    );
    return picked?.path;
  }

  /// Copies a picked image into the app folder. Returns the new file name.
  Future<String> save(String sourcePath) async {
    var ext = p.extension(sourcePath).toLowerCase();
    if (ext.isEmpty) ext = '.jpg';
    final name = '${DateTime.now().microsecondsSinceEpoch}$ext';
    await File(sourcePath).copy(p.join(_dir.path, name));
    return name;
  }

  /// Deletes a saved image (ignores errors, e.g. if it's already gone).
  Future<void> delete(String name) async {
    try {
      final file = fileFor(name);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}