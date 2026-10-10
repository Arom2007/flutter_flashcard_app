import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show
        QuillController,
        QuillEditor,
        QuillEditorConfig,
        QuillSimpleToolbar,
        QuillSimpleToolbarButtonOptions,
        QuillSimpleToolbarConfig,
        QuillToolbarFontFamilyButtonOptions,
        QuillToolbarFontSizeButtonOptions;

import '../data/card_repository.dart';
import '../data/font_service.dart';
import '../data/rich_text_codec.dart';
import '../models/flashcard.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_discard.dart';

/// Used for both adding a card and editing one.
/// If [card] is given we are editing it; if it's null we're adding a new one.
class CardEditorScreen extends StatefulWidget {
  const CardEditorScreen({super.key, required this.folderId, this.card});

  final int folderId;
  final Flashcard? card;

  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<CardEditorScreen> {
  final _repo = CardRepository();

  // One controller per side. A controller holds the document being edited
  // (text + formatting) and the cursor/selection.
  late final QuillController _front = _newController(widget.card?.front ?? '');
  late final QuillController _back = _newController(widget.card?.back ?? '');

  // Which side is being edited right now.
  bool _showBack = false;

  // True while saving, so a second tap on Save does nothing.
  bool _saving = false;

  // What the card looked like when this screen opened. Comparing against
  // it tells us whether there are unsaved changes.
  late final String _initialSignature;

  bool get _isEditing => widget.card != null;
  QuillController get _active => _showBack ? _back : _front;

  @override
  void initState() {
    super.initState();
    _initialSignature = _signature();
  }

  /// Both sides, as the strings we would save. Changes if the user edits.
  String _signature() =>
      '${RichTextCodec.encode(_front.document)}|${RichTextCodec.encode(_back.document)}';

  bool get _hasChanges => _signature() != _initialSignature;

  /// Builds a controller that already contains the stored content.
  QuillController _newController(String stored) {
    final controller = QuillController.basic();
    controller.document = RichTextCodec.toDocument(stored);
    return controller;
  }

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  bool _isEmpty(QuillController c) => c.document.toPlainText().trim().isEmpty;

  Future<void> _save() async {
    if (_saving) return;

    // Don't allow a half-empty card.
    if (_isEmpty(_front) || _isEmpty(_back)) {
      _message('Please fill in both sides');
      return;
    }

    setState(() => _saving = true);
    try {
      final front = RichTextCodec.encode(_front.document);
      final back = RichTextCodec.encode(_back.document);
      if (_isEditing) {
        await _repo.update(widget.card!.id, front, back);
      } else {
        await _repo.create(widget.folderId, front, back);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _message('Couldn\'t save the card. Please try again.');
      }
      return;
    }

    if (!mounted) return;
    Navigator.pop(context, true); // tell the previous screen "saved"
  }

  Future<void> _importFont() async {
    try {
      final family = await FontService.instance.importFont();
      if (family == null || !mounted) return; // cancelled
      setState(() {}); // redraw so the toolbar's font list includes it
      _message('Added font "$family"');
    } on FormatException catch (e) {
      if (mounted) _message(e.message);
    } catch (_) {
      if (mounted) _message('Couldn\'t import that font');
    }
  }

  // The fonts shown in the toolbar dropdown: label -> font name.
  Map<String, String> get _fontItems => {
        for (final family in FontService.instance.families) family: family,
        'Serif': 'serif', // built into Android
        'Monospace': 'monospace', // built into Android
        'Clear': 'Clear', // removes the font from the selected text
      };

  static const _sizes = [12, 14, 16, 18, 20, 24, 28, 32, 40];

  Map<String, String> get _sizeItems => {
        for (final s in _sizes) '$s': '$s',
        'Clear': '0', // '0' means "go back to the normal size"
      };

  @override
  Widget build(BuildContext context) {
    // PopScope catches "going back" (arrow, back button, back gesture).
    // canPop: false = we decide. If there are unsaved changes we ask first.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!_hasChanges || await confirmDiscard(context)) {
          if (mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit card' : 'New card'),
          actions: [
            IconButton(
              tooltip: 'Import font',
              icon: const Icon(Icons.font_download_outlined),
              onPressed: _importFont,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                // null disables the button while saving.
                onPressed: _saving ? null : _save,
                child: Text(_isEditing ? 'Save' : 'Add'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Front | Back switch.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Front')),
                    ButtonSegment(value: true, label: Text('Back')),
                  ],
                  selected: {_showBack},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) =>
                      setState(() => _showBack = s.first),
                  style: SegmentedButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    selectedForegroundColor: AppColors.primary,
                    selectedBackgroundColor: AppColors.primarySoft,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),

              // The editor, inside a white rounded box.
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: QuillEditor.basic(
                    key: ValueKey('editor-$_showBack'),
                    controller: _active,
                    config: QuillEditorConfig(
                      placeholder: _showBack
                          ? 'The answer'
                          : 'What do you want to remember?',
                      padding: const EdgeInsets.all(16),
                      expands: true,
                      autoFocus: !_isEditing,
                    ),
                  ),
                ),
              ),

              // The formatting toolbar: one row you can scroll sideways.
              Container(
                margin: const EdgeInsets.only(top: 12),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: QuillSimpleToolbar(
                  key: ValueKey(
                    'toolbar-$_showBack-${FontService.instance.families.length}',
                  ),
                  controller: _active,
                  config: QuillSimpleToolbarConfig(
                    multiRowsDisplay: false,
                    showDividers: false,
                    // --- tools you asked for ---
                    showFontFamily: true,
                    showFontSize: true,
                    showBoldButton: true,
                    showItalicButton: true,
                    showUnderLineButton: true,
                    showColorButton: true,
                    showAlignmentButtons: true,
                    showListBullets: true,
                    showListNumbers: true,
                    // --- small extras: undo / redo / clear formatting ---
                    showUndo: true,
                    showRedo: true,
                    showClearFormat: true,
                    // --- everything else switched off ---
                    showStrikeThrough: false,
                    showInlineCode: false,
                    showBackgroundColorButton: false,
                    showHeaderStyle: false,
                    showListCheck: false,
                    showCodeBlock: false,
                    showQuote: false,
                    showIndent: false,
                    showLink: false,
                    showSearchButton: false,
                    showSubscript: false,
                    showSuperscript: false,
                    showClipboardCut: false,
                    showClipboardCopy: false,
                    showClipboardPaste: false,
                    buttonOptions: QuillSimpleToolbarButtonOptions(
                      fontFamily:
                          QuillToolbarFontFamilyButtonOptions(items: _fontItems),
                      fontSize:
                          QuillToolbarFontSizeButtonOptions(items: _sizeItems),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}