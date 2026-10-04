import 'package:flutter/material.dart';

import '../data/folder_repository.dart';
import '../models/folder.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/name_dialog.dart';

/// Shows the folders inside one place. With no [parent] it is the home
/// screen (top level). Tapping a folder opens another LibraryScreen for
/// it, so the same screen handles any depth of nesting.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, this.parent});

  final Folder? parent; // the folder we're inside; null = top level

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _repo = FolderRepository();
  List<Folder> _folders = [];
  bool _loading = true;

  // initState runs once when the screen first appears.
  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Reads the folders from the database and redraws the screen.
  Future<void> _load() async {
    final folders = await _repo.getChildren(widget.parent?.id);
    // If the user left the screen while we were loading, do nothing.
    if (!mounted) return;
    // setState tells Flutter "my data changed, redraw me".
    setState(() {
      _folders = folders;
      _loading = false;
    });
  }

  Future<void> _create() async {
    final name = await showNameDialog(
      context,
      title: 'New folder',
      confirmLabel: 'Create',
    );
    if (name == null) return; // cancelled
    await _repo.create(name, widget.parent?.id);
    _load();
  }

  Future<void> _rename(Folder folder) async {
    final name = await showNameDialog(
      context,
      title: 'Rename folder',
      confirmLabel: 'Save',
      initialName: folder.name,
    );
    if (name == null) return;
    await _repo.rename(folder.id, name);
    _load();
  }

  Future<void> _delete(Folder folder) async {
    // showDialog<bool> returns true/false depending on the button tapped.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete folder?'),
        content: Text(
          '"${folder.name}" and everything inside it will be deleted. '
          'This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.delete(folder.id);
    _load();
  }

  Future<void> _open(Folder folder) async {
    // Go to a new screen for this folder. 'await' waits until the user
    // comes back, then we reload so the subfolder counts are up to date.
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LibraryScreen(parent: folder)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isRoot = widget.parent == null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.parent?.name ?? 'Flashcards')),
      body: _buildBody(isRoot),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New folder'),
      ),
    );
  }

  Widget _buildBody(bool isRoot) {
    // Still reading from the database: show a small spinner.
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Nothing here yet: show the empty state from stage 0.
    if (_folders.isEmpty) {
      return EmptyState(
        icon: Icons.folder_open_rounded,
        title: isRoot ? 'Nothing here yet' : 'This folder is empty',
        message: isRoot
            ? 'Create your first folder to start\norganizing your flashcards.'
            : 'Add a subfolder to organize\nthis topic further.',
      );
    }

    // Otherwise show the list of folders.
    return ListView.separated(
      // Extra space at the bottom so the button never covers the last folder.
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      itemCount: _folders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      // itemBuilder is called once per folder to build its row.
      itemBuilder: (context, index) => _FolderTile(
        folder: _folders[index],
        onTap: () => _open(_folders[index]),
        onRename: () => _rename(_folders[index]),
        onDelete: () => _delete(_folders[index]),
      ),
    );
  }
}

/// One row in the list: icon, name, subfolder count, and a "..." menu.
class _FolderTile extends StatelessWidget {
  const _FolderTile({
    required this.folder,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final Folder folder;
  final VoidCallback onTap; // VoidCallback = a function with no inputs/outputs
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final n = folder.childCount;

    return Card(
      // Clips the tap ripple to the card's rounded corners.
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.folder_rounded, color: AppColors.primary),
        ),
        title: Text(folder.name, style: textTheme.titleMedium),
        subtitle: Text(
          n == 0 ? 'No subfolders' : (n == 1 ? '1 subfolder' : '$n subfolders'),
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        // The "..." button that opens a small menu.
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
          onSelected: (value) {
            if (value == 'rename') onRename();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'rename', child: Text('Rename')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}