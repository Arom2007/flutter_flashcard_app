import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/backup_service.dart';

/// A small popup with a spinner while something slow is happening.
/// Close it with: Navigator.of(context, rootNavigator: true).pop()
void _showProgress(BuildContext context, String message) {
  showDialog<void>(
    context: context,
    barrierDismissible: false, // can't be dismissed by tapping outside
    builder: (_) => PopScope(
      canPop: false, // ...or by the back button
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    ),
  );
}

String _describe(Object error) =>
    error is BackupException ? error.message : 'Something went wrong. Please try again.';

/// Makes a backup zip and opens the share sheet so the user can save it
/// somewhere safe (Drive, Files, email...).
Future<void> runBackup(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  _showProgress(context, 'Preparing your backup…');

  String? zipPath;
  Object? error;
  try {
    zipPath = await BackupService.instance.createBackup();
  } catch (e) {
    error = e;
  }

  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop(); // close the spinner

  if (error != null || zipPath == null) {
    messenger.showSnackBar(
      SnackBar(content: Text(_describe(error ?? 'unknown'))),
    );
    return;
  }

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(zipPath, mimeType: 'application/zip')],
      text: 'CrashCards backup',
    ),
  );
}

/// Asks for confirmation, lets the user pick a backup file, and restores
/// it. Returns true if the restore worked (so the caller can refresh).
Future<bool> runRestore(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Restore from backup?'),
      content: const Text(
        'This replaces everything currently in the app (folders, cards, '
        'images and fonts) with the contents of the backup. '
        'This can\'t be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Choose backup'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  // We accept any file type here and let the restore code check the
  // contents, because Android's picker doesn't know our backup type.
  final picked = await FilePicker.pickFiles(type: FileType.any);
  if (picked.isEmpty || !context.mounted) return false;
  final path = picked.first.path;
  if (path == null) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Couldn\'t read that file')),
    );
    return false;
  }

  _showProgress(context, 'Restoring your data…');
  Object? error;
  try {
    await BackupService.instance.restore(path);
  } catch (e) {
    error = e;
  }

  if (!context.mounted) return false;
  Navigator.of(context, rootNavigator: true).pop(); // close the spinner

  if (error != null) {
    messenger.showSnackBar(SnackBar(content: Text(_describe(error))));
    return false;
  }
  return true;
}