import 'package:flutter/material.dart';

import '../data/card_repository.dart';
import '../data/folder_repository.dart';
import '../data/image_store.dart';
import '../data/rich_text_codec.dart';
import '../models/flashcard.dart';
import '../models/folder.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/name_dialog.dart';
import 'card_editor_screen.dart';
import 'card_view_screen.dart';
import 'image_card_editor_screen.dart';
import 'study_screen.dart';

/// Shows what's inside one place: subfolders and (inside a folder) cards.
/// With no [parent] it is the home screen (top level, folders only).
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, this.parent});

  final Folder? parent; // the folder we're inside; null = top level

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _folderRepo = FolderRepository();
  final _cardRepo = CardRepository();

  List<Folder> _folders = [];
  List<Flashcard> _cards = [];
  bool _loading = true;

  bool get _isRoot => widget.parent == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Reads folders (and cards, if we're inside a folder) and redraws.
  Future<void> _load() async {
    final folders = await _folderRepo.getChildren(widget.parent?.id);
    final cards = _isRoot
        ? <Flashcard>[]
        : await _cardRepo.getForFolder(widget.parent!.id);
    if (!mounted) return;
    setState(() {
      _folders = folders;
      _cards = cards;
      _loading = false;
    });
  }

  // ---------- folder actions ----------

  Future<void> _createFolder() async {
    final name = await showNameDialog(
      context,
      title: _isRoot ? 'New folder' : 'New subfolder',
      confirmLabel: 'Create',
    );
    if (name == null) return;
    await _folderRepo.create(name, widget.parent?.id);
    _load();
  }

  Future<void> _renameFolder(Folder folder) async {
    final name = await showNameDialog(
      context,
      title: 'Rename folder',
      confirmLabel: 'Save',
      initialName: folder.name,
    );
    if (name == null) return;
    await _folderRepo.rename(folder.id, name);
    _load();
  }

  Future<void> _deleteFolder(Folder folder) async {
    final confirmed = await _confirm(
      title: 'Delete folder?',
      message: '"${folder.name}" and everything inside it (subfolders and '
          'cards) will be deleted. This can\'t be undone.',
    );
    if (!confirmed) return;
    await _folderRepo.delete(folder.id);
    _load();
  }

  Future<void> _openFolder(Folder folder) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LibraryScreen(parent: folder)),
    );
    _load();
  }

  // ---------- card actions ----------

  Future<void> _addCard() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CardEditorScreen(folderId: widget.parent!.id),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _addImageCard() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ImageCardEditorScreen(folderId: widget.parent!.id),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _editCard(Flashcard card) async {
    // Image cards and text cards have different editors.
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => card.isImage
            ? ImageCardEditorScreen(folderId: card.folderId, card: card)
            : CardEditorScreen(folderId: card.folderId, card: card),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _deleteCard(Flashcard card) async {
    final confirmed = await _confirm(
      title: 'Delete card?',
      message: 'This card will be deleted. This can\'t be undone.',
    );
    if (!confirmed) return;
    await _cardRepo.delete(card.id);
    _load();
  }

  void _viewCard(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardViewScreen(cards: _cards, initialIndex: index),
      ),
    );
  }

  /// Opens study mode for the cards in this folder.
  void _study() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyScreen(title: widget.parent!.name, cards: _cards),
      ),
    );
  }

  // ---------- helpers ----------

  /// A reusable Cancel / Delete popup. Returns true if the user confirmed.
  Future<bool> _confirm({required String title, required String message}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
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
    return result == true;
  }

  /// Inside a folder the + button asks what to add.
  Future<void> _showAddMenu() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.style_rounded),
              title: const Text('New card'),
              onTap: () => Navigator.pop(context, 'card'),
            ),
            ListTile(
              leading: const Icon(Icons.image_rounded),
              title: const Text('New image card'),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_rounded),
              title: const Text('New subfolder'),
              onTap: () => Navigator.pop(context, 'folder'),
            ),
          ],
        ),
      ),
    );
    if (choice == 'card') _addCard();
    if (choice == 'image') _addImageCard();
    if (choice == 'folder') _createFolder();
  }

  // ---------- screen ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parent?.name ?? 'Flashcards'),
        actions: [
          if (!_isRoot && _cards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: _study,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Study'),
              ),
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _isRoot
          ? FloatingActionButton.extended(
              onPressed: _createFolder,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New folder'),
            )
          : FloatingActionButton.extended(
              onPressed: _showAddMenu,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_folders.isEmpty && _cards.isEmpty) {
      return EmptyState(
        icon: Icons.folder_open_rounded,
        title: _isRoot ? 'Nothing here yet' : 'This folder is empty',
        message: _isRoot
            ? 'Create your first folder to start\norganizing your flashcards.'
            : 'Tap Add to create a card\nor a subfolder.',
      );
    }

    final items = <Widget>[];

    if (_folders.isNotEmpty) {
      if (!_isRoot) items.add(const _SectionLabel('FOLDERS'));
      for (final folder in _folders) {
        items.add(_FolderTile(
          folder: folder,
          onTap: () => _openFolder(folder),
          onRename: () => _renameFolder(folder),
          onDelete: () => _deleteFolder(folder),
        ));
        items.add(const SizedBox(height: 12));
      }
    }

    if (_cards.isNotEmpty) {
      items.add(const _SectionLabel('CARDS'));
      for (var i = 0; i < _cards.length; i++) {
        final card = _cards[i];
        items.add(_CardTile(
          card: card,
          onTap: () => _viewCard(i),
          onEdit: () => _editCard(card),
          onDelete: () => _deleteCard(card),
        ));
        items.add(const SizedBox(height: 12));
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      children: items,
    );
  }
}

/// A small grey heading like "FOLDERS" or "CARDS".
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 1.5,
            ),
      ),
    );
  }
}

/// One folder row: icon, name, subfolder count, and a "..." menu.
class _FolderTile extends StatelessWidget {
  const _FolderTile({
    required this.folder,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final Folder folder;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final n = folder.childCount;

    return Card(
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

/// One card row: just the card's name (no answer shown) and a menu.
/// Text cards are named by their question; image cards by their title.
class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Flashcard card;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// The name shown for this card.
  String get _name {
    if (!card.isImage) return RichTextCodec.plainText(card.front);
    // Image cards store their title (plain text) in 'front'. Older image
    // cards have none, so they fall back to "Image card".
    final title = card.front.trim();
    return title.isEmpty ? 'Image card' : title;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        leading: card.isImage
            ? _Thumbnail(name: card.imagePath!)
            : Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.style_rounded, color: AppColors.primary),
              ),
        title: Text(
          _name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium,
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

/// A small rounded picture for image cards in the list.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Image.file(
          ImageStore.instance.fileFor(name),
          fit: BoxFit.cover,
          cacheWidth: 132, // decode a small version: saves memory
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.primarySoft,
            child: const Icon(Icons.image_rounded, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}