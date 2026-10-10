import 'package:flutter/material.dart';

import '../data/card_repository.dart';
import '../data/folder_repository.dart';
import '../data/rich_text_codec.dart';
import '../models/flashcard.dart';
import '../models/folder.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import 'card_view_screen.dart';
import 'library_screen.dart';

/// One folder in the search index. [haystack] is the lowercase text we
/// search inside; [path] is where the folder lives, e.g. "Science › Chapter 1".
class _FolderHit {
  const _FolderHit({
    required this.folder,
    required this.path,
    required this.haystack,
  });

  final Folder folder;
  final String path;
  final String haystack;
}

class _CardHit {
  const _CardHit({
    required this.card,
    required this.path,
    required this.title,
    required this.haystack,
  });

  final Flashcard card;
  final String path; // the folder the card is in
  final String title;
  final String haystack;
}

/// Searches every folder and card, at any depth.
/// Text cards match on question and answer; image cards match on their
/// title and the text written on the image.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _maxResults = 100; // per section, so the list stays light

  final _controller = TextEditingController();

  List<_FolderHit> _folders = [];
  List<_CardHit> _cards = [];
  bool _loading = true;
  bool _failed = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadIndex();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Reads everything once. After that, typing only filters this list in
  /// memory, so results appear instantly.
  Future<void> _loadIndex() async {
    try {
      final folders = await FolderRepository().getAll();
      final cards = await CardRepository().getAll();
      final byId = {for (final f in folders) f.id: f};

      // "Science › Chapter 1" for a folder id (walks up to the top).
      String pathOf(int? id) {
        final names = <String>[];
        var current = id;
        var guard = 0; // a safety limit, so a bad loop can never hang us
        while (current != null && guard < 50) {
          final folder = byId[current];
          if (folder == null) break;
          names.add(folder.name);
          current = folder.parentId;
          guard++;
        }
        return names.reversed.join(' › ');
      }

      final folderHits = [
        for (final f in folders)
          _FolderHit(
            folder: f,
            path: pathOf(f.parentId),
            haystack: f.name.toLowerCase(),
          ),
      ];
      final cardHits = [
        for (final c in cards)
          _CardHit(
            card: c,
            path: pathOf(c.folderId),
            title: RichTextCodec.cardTitle(c),
            haystack: _haystack(c),
          ),
      ];

      if (!mounted) return;
      setState(() {
        _folders = folderHits;
        _cards = cardHits;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  /// All the searchable words of a card, lowercase.
  String _haystack(Flashcard card) {
    if (card.isImage) {
      final labels = (card.overlay?.texts ?? []).map((t) => t.text).join(' ');
      return '${card.front} $labels'.toLowerCase();
    }
    final front = RichTextCodec.plainText(card.front);
    final back = RichTextCodec.plainText(card.back);
    return '$front $back'.toLowerCase();
  }

  /// The typed words. "cell wall" finds anything containing BOTH words.
  List<String> get _words => _query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();

  bool _matches(String haystack, List<String> words) =>
      words.every((w) => haystack.contains(w));

  Future<void> _openFolder(Folder folder) async {
    FocusScope.of(context).unfocus(); // hide the keyboard
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LibraryScreen(parent: folder)),
    );
    _loadIndex(); // things may have been changed in there
  }

  Future<void> _openCard(Flashcard card) async {
    FocusScope.of(context).unfocus();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardViewScreen(cards: [card], initialIndex: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // The search box lives in the app bar. We switch off the theme's
        // box styling so it looks like plain text.
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => _query = value),
          style: Theme.of(context).textTheme.titleMedium,
          decoration: const InputDecoration(
            hintText: 'Search folders and cards',
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_failed) {
      return const EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Couldn\'t search',
        message: 'Something went wrong while reading\nyour cards.',
      );
    }

    final words = _words;
    if (words.isEmpty) {
      return const EmptyState(
        icon: Icons.search_rounded,
        title: 'Search everything',
        message: 'Find folders and cards by name, question,\n'
            'answer or text on an image.',
      );
    }

    final folderMatches =
        _folders.where((f) => _matches(f.haystack, words)).toList();
    final cardMatches =
        _cards.where((c) => _matches(c.haystack, words)).toList();

    if (folderMatches.isEmpty && cardMatches.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        message: 'Try different words.',
      );
    }

    // One flat list: a String is a section heading, the rest are results.
    final items = <Object>[];
    if (folderMatches.isNotEmpty) {
      items.add('FOLDERS');
      items.addAll(folderMatches.take(_maxResults));
    }
    if (cardMatches.isNotEmpty) {
      items.add('CARDS');
      items.addAll(cardMatches.take(_maxResults));
    }
    final capped =
        folderMatches.length > _maxResults || cardMatches.length > _maxResults;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      itemCount: items.length + (capped ? 1 : 0),
      itemBuilder: (context, i) {
        // The last row, when results were cut off.
        if (i == items.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Showing the first $_maxResults results. '
              'Type more to narrow it down.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textMuted),
            ),
          );
        }

        final item = items[i];
        if (item is String) return _SectionLabel(item);

        if (item is _FolderHit) {
          return _ResultTile(
            icon: Icons.folder_rounded,
            title: item.folder.name,
            subtitle: item.path.isEmpty ? 'Top level' : item.path,
            onTap: () => _openFolder(item.folder),
          );
        }

        final hit = item as _CardHit;
        return _ResultTile(
          icon: hit.card.isImage ? Icons.image_rounded : Icons.style_rounded,
          title: hit.title,
          subtitle: hit.path,
          onTap: () => _openCard(hit.card),
        );
      },
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

/// One search result: icon, name, and where it lives.
class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          title: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium,
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}