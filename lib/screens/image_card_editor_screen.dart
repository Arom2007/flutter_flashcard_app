import 'dart:io';

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';

import '../data/card_repository.dart';
import '../data/font_service.dart';
import '../data/image_store.dart';
import '../models/flashcard.dart';
import '../models/image_overlay.dart';
import '../theme/app_theme.dart';
import '../widgets/overlay_text.dart';

enum _Tool { boxes, text }

// What the finger is doing during a drag on the image (Boxes tool).
enum _Drag { none, create, move, resize }

/// Create or edit an image card: pick a picture, draw boxes, add text.
/// If [card] is given we are editing it; otherwise we're making a new one.
class ImageCardEditorScreen extends StatefulWidget {
  const ImageCardEditorScreen({super.key, required this.folderId, this.card});

  final int folderId;
  final Flashcard? card;

  @override
  State<ImageCardEditorScreen> createState() => _ImageCardEditorScreenState();
}

class _ImageCardEditorScreenState extends State<ImageCardEditorScreen> {
  final _repo = CardRepository();

  File? _imageFile; // the picture being shown
  String? _pickedPath; // temporary path of a newly picked picture
  double _aspect = 1; // picture width / height

  final List<Rect> _boxes = []; // fractions of the picture (0..1)
  final List<TextOverlay> _texts = [];

  _Tool _tool = _Tool.boxes;
  int? _selBox; // index of the selected box
  int? _selText; // index of the selected text

  // Drag bookkeeping for the Boxes tool.
  _Drag _drag = _Drag.none;
  Offset _dragStart = Offset.zero; // where the finger went down (fractions)
  Rect _origRect = Rect.zero; // the box as it was when a move began
  Offset _anchor = Offset.zero; // the fixed corner while resizing

  // How close (in pixels) a finger must be to a corner dot to grab it,
  // and the smallest box we keep.
  static const _grabRadius = 28.0;
  static const _minBoxPx = 20.0;

  bool get _isEditing => widget.card != null;

  static const _palette = [
    0xFF000000, // black
    0xFFFFFFFF, // white
    0xFFD64545, // red
    0xFFE08A1E, // orange
    0xFFE8C531, // yellow
    0xFF3F9B5E, // green
    0xFF3D6FB6, // blue
    0xFF7B52AB, // purple
  ];

  @override
  void initState() {
    super.initState();
    final card = widget.card;
    if (card != null) {
      // Editing: load the saved picture, boxes and text.
      _imageFile = ImageStore.instance.fileFor(card.imagePath!);
      final overlay = card.overlay;
      if (overlay != null) {
        _aspect = overlay.aspect;
        _boxes.addAll(overlay.boxes);
        _texts.addAll(overlay.texts);
      }
    } else {
      // New card: open the gallery straight away (after the first frame).
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage());
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ---------- picking and saving ----------

  Future<void> _pickImage() async {
    final path = await ImageStore.instance.pickFromGallery();
    if (path == null) return; // cancelled
    try {
      // Read the picture's size so we know its shape (width / height).
      final bytes = await File(path).readAsBytes();
      final image = await decodeImageFromList(bytes);
      final aspect = image.width / image.height;
      image.dispose();
      if (!mounted) return;
      setState(() {
        _pickedPath = path;
        _imageFile = File(path);
        _aspect = aspect;
      });
    } catch (_) {
      if (mounted) _message('Couldn\'t open that image');
    }
  }

  Future<void> _save() async {
    if (_imageFile == null) {
      _message('Please choose an image first');
      return;
    }

    final json = ImageOverlay(
      aspect: _aspect,
      boxes: List.of(_boxes),
      texts: List.of(_texts),
    ).toJsonString();

    if (_isEditing) {
      await _repo.updateImageCard(widget.card!.id, json);
    } else {
      // Only now is the picture copied into the app's own folder.
      final name = await ImageStore.instance.save(_pickedPath!);
      await _repo.createImageCard(widget.folderId, name, json);
    }

    if (!mounted) return;
    Navigator.pop(context, true); // tell the previous screen "saved"
  }

  // ---------- Boxes tool: gestures ----------

  Offset _toFraction(Offset px, Size size) => Offset(
        (px.dx / size.width).clamp(0.0, 1.0),
        (px.dy / size.height).clamp(0.0, 1.0),
      );

  void _onPanStart(Offset pos, Size size) {
    final frac = _toFraction(pos, size);
    _dragStart = frac;

    // 1. Did the finger land on a corner dot of the selected box? -> resize.
    final sel = _selBox;
    if (sel != null) {
      final b = _boxes[sel];
      final corners = [b.topLeft, b.topRight, b.bottomRight, b.bottomLeft];
      for (var i = 0; i < 4; i++) {
        final px = Offset(corners[i].dx * size.width, corners[i].dy * size.height);
        if ((px - pos).distance <= _grabRadius) {
          _drag = _Drag.resize;
          // The opposite corner (i + 2) stays still while we drag this one.
          _anchor = corners[(i + 2) % 4];
          return;
        }
      }
    }

    // 2. Inside a box? -> select it and move it. (Last in the list = on top.)
    for (var i = _boxes.length - 1; i >= 0; i--) {
      if (_boxes[i].contains(frac)) {
        setState(() {
          _selBox = i;
          _drag = _Drag.move;
          _origRect = _boxes[i];
        });
        return;
      }
    }

    // 3. Empty space -> start drawing a new box.
    setState(() {
      _boxes.add(Rect.fromLTWH(frac.dx, frac.dy, 0, 0));
      _selBox = _boxes.length - 1;
      _drag = _Drag.create;
    });
  }

  void _onPanUpdate(Offset pos, Size size) {
    final sel = _selBox;
    if (sel == null || _drag == _Drag.none) return;
    final cur = _toFraction(pos, size);

    setState(() {
      switch (_drag) {
        case _Drag.create:
          _boxes[sel] = Rect.fromPoints(_dragStart, cur);
        case _Drag.resize:
          // Rect.fromPoints sorts out which corner is which, so dragging
          // past the opposite corner simply flips the box.
          _boxes[sel] = Rect.fromPoints(_anchor, cur);
        case _Drag.move:
          // Keep the box inside the picture.
          final dx = (cur.dx - _dragStart.dx)
              .clamp(-_origRect.left, 1 - _origRect.right);
          final dy = (cur.dy - _dragStart.dy)
              .clamp(-_origRect.top, 1 - _origRect.bottom);
          _boxes[sel] = _origRect.shift(Offset(dx, dy));
        case _Drag.none:
          break;
      }
    });
  }

  void _onPanEnd(Size size) {
    setState(() {
      final sel = _selBox;
      // A tiny new box was probably an accident: throw it away.
      if (_drag == _Drag.create && sel != null) {
        final r = _boxes[sel];
        if (r.width * size.width < _minBoxPx ||
            r.height * size.height < _minBoxPx) {
          _boxes.removeAt(sel);
          _selBox = null;
        }
      }
      _drag = _Drag.none;
    });
  }

  void _onTapUp(Offset pos, Size size) {
    if (_tool == _Tool.text) {
      setState(() => _selText = null); // tap on empty space = deselect
      return;
    }
    final frac = _toFraction(pos, size);
    int? hit;
    for (var i = _boxes.length - 1; i >= 0; i--) {
      if (_boxes[i].contains(frac)) {
        hit = i;
        break;
      }
    }
    setState(() => _selBox = hit);
  }

  void _deleteBox() {
    final sel = _selBox;
    if (sel == null) return;
    setState(() {
      _boxes.removeAt(sel);
      _selBox = null;
    });
  }

  // ---------- Text tool ----------

  Future<String?> _askText({required String title, String initial = ''}) {
    return showDialog<String>(
      context: context,
      builder: (_) => _TextDialog(title: title, initial: initial),
    );
  }

  Future<void> _addText() async {
    final text = await _askText(title: 'Add text');
    if (text == null) return;
    setState(() {
      _texts.add(TextOverlay(text: text));
      _selText = _texts.length - 1;
    });
  }

  Future<void> _editText() async {
    final i = _selText;
    if (i == null) return;
    final text = await _askText(title: 'Edit text', initial: _texts[i].text);
    if (text == null) return;
    setState(() => _texts[i] = _texts[i].copyWith(text: text));
  }

  void _deleteText() {
    final i = _selText;
    if (i == null) return;
    setState(() {
      _texts.removeAt(i);
      _selText = null;
    });
  }

  /// Changes the selected text label. 'change' receives the current label
  /// and returns the new version.
  void _patchText(TextOverlay Function(TextOverlay t) change) {
    final i = _selText;
    if (i == null) return;
    setState(() => _texts[i] = change(_texts[i]));
  }

  void _moveText(int i, Offset delta, Size size) {
    final t = _texts[i];
    setState(() {
      _texts[i] = t.copyWith(
        x: (t.x + delta.dx / size.width).clamp(0.0, 0.9),
        y: (t.y + delta.dy / size.height).clamp(0.0, 0.95),
      );
    });
  }

  // ---------- screen ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit image card' : 'New image card'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Save' : 'Add'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _imageFile == null ? _buildPicker() : _buildEditor(),
      ),
    );
  }

  /// Shown until a picture has been chosen.
  Widget _buildPicker() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.add_photo_alternate_rounded,
              size: 44,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('Choose image'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Column(
      children: [
        // Boxes | Text switch.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: SegmentedButton<_Tool>(
            segments: const [
              ButtonSegment(
                value: _Tool.boxes,
                icon: Icon(Icons.crop_square_rounded),
                label: Text('Boxes'),
              ),
              ButtonSegment(
                value: _Tool.text,
                icon: Icon(Icons.text_fields_rounded),
                label: Text('Text'),
              ),
            ],
            selected: {_tool},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _tool = s.first),
            style: SegmentedButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              selectedForegroundColor: AppColors.primary,
              selectedBackgroundColor: AppColors.primarySoft,
              side: const BorderSide(color: AppColors.border),
            ),
          ),
        ),

        // The picture, fitted to its own shape.
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Center(
              child: AspectRatio(
                aspectRatio: _aspect,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildCanvas(),
                ),
              ),
            ),
          ),
        ),

        // Controls for the current tool.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: SingleChildScrollView(
              child: _tool == _Tool.boxes
                  ? _buildBoxControls()
                  : _buildTextControls(),
            ),
          ),
        ),
      ],
    );
  }

  /// The picture with text and boxes on top, plus the gesture handling.
  Widget _buildCanvas() {
    final boxMode = _tool == _Tool.boxes;

    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // 'down' = report the exact spot where the finger touched, not
          // where it had moved to after the drag was recognised.
          dragStartBehavior: DragStartBehavior.down,
          onTapUp: (d) => _onTapUp(d.localPosition, size),
          // Drag handlers only exist in Boxes mode (null = switched off).
          onPanStart: boxMode ? (d) => _onPanStart(d.localPosition, size) : null,
          onPanUpdate:
              boxMode ? (d) => _onPanUpdate(d.localPosition, size) : null,
          onPanEnd: boxMode ? (_) => _onPanEnd(size) : null,
          onPanCancel: boxMode ? () => _onPanEnd(size) : null,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.file(
                  _imageFile!,
                  fit: BoxFit.fill,
                  gaplessPlayback: true,
                ),
              ),

              // Text labels. In Boxes mode they ignore touches.
              for (var i = 0; i < _texts.length; i++)
                Positioned(
                  left: _texts[i].x * size.width,
                  top: _texts[i].y * size.height,
                  child: IgnorePointer(
                    ignoring: boxMode,
                    child: GestureDetector(
                      dragStartBehavior: DragStartBehavior.down,
                      onTap: () => setState(() => _selText = i),
                      onPanStart: (_) => setState(() => _selText = i),
                      onPanUpdate: (d) => _moveText(i, d.delta, size),
                      child: OverlayText(
                        item: _texts[i],
                        canvasWidth: size.width,
                        selected: !boxMode && _selText == i,
                      ),
                    ),
                  ),
                ),

              // The boxes, painted on top. They never take touches
              // themselves: the gesture code above does the work.
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _BoxPainter(
                      boxes: _boxes,
                      selected: _selBox,
                      // See-through while editing, so you can see what's
                      // underneath. Even fainter in Text mode.
                      opacity: boxMode ? 0.72 : 0.3,
                      showHandles: boxMode,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBoxControls() {
    final hint = _selBox == null
        ? 'Drag on the image to draw a box'
        : 'Drag to move it, drag a corner dot to resize';

    return Row(
      children: [
        Expanded(
          child: Text(
            hint,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textMuted),
          ),
        ),
        TextButton.icon(
          onPressed: _selBox == null ? null : _deleteBox,
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Delete box'),
        ),
      ],
    );
  }

  Widget _buildTextControls() {
    final i = _selText;
    final t = i == null ? null : _texts[i];

    // The fonts shown in the dropdown: font name -> label.
    final fonts = <String, String>{
      '': 'Default',
      'serif': 'Serif',
      'monospace': 'Monospace',
      for (final f in FontService.instance.families) f: f,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: add / edit / delete.
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _addText,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add text'),
            ),
            const Spacer(),
            if (t != null) ...[
              IconButton(
                tooltip: 'Edit text',
                icon: const Icon(Icons.edit_outlined),
                onPressed: _editText,
              ),
              IconButton(
                tooltip: 'Delete text',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: _deleteText,
              ),
            ],
          ],
        ),
        if (t == null)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              _texts.isEmpty
                  ? 'Add text, then drag it where you want it'
                  : 'Tap a text on the image to format it',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textMuted),
            ),
          )
        else ...[
          // Row 2: font + bold / italic / underline.
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  // If the saved font no longer exists, show 'Default'.
                  value: fonts.containsKey(t.fontFamily) ? t.fontFamily : '',
                  items: [
                    for (final e in fonts.entries)
                      DropdownMenuItem(
                        value: e.key,
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontFamily: e.key.isEmpty ? null : e.key,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (v) =>
                      _patchText((x) => x.copyWith(fontFamily: v ?? '')),
                ),
              ),
              _StyleToggle(
                icon: Icons.format_bold_rounded,
                on: t.bold,
                onTap: () => _patchText((x) => x.copyWith(bold: !x.bold)),
              ),
              _StyleToggle(
                icon: Icons.format_italic_rounded,
                on: t.italic,
                onTap: () => _patchText((x) => x.copyWith(italic: !x.italic)),
              ),
              _StyleToggle(
                icon: Icons.format_underlined_rounded,
                on: t.underline,
                onTap: () =>
                    _patchText((x) => x.copyWith(underline: !x.underline)),
              ),
            ],
          ),
          // Row 3: size.
          Row(
            children: [
              const Icon(Icons.text_fields_rounded,
                  size: 16, color: AppColors.textMuted),
              Expanded(
                child: Slider(
                  value: t.size.clamp(0.02, 0.16),
                  min: 0.02,
                  max: 0.16,
                  onChanged: (v) => _patchText((x) => x.copyWith(size: v)),
                ),
              ),
              const Icon(Icons.text_fields_rounded,
                  size: 26, color: AppColors.textMuted),
            ],
          ),
          // Row 4: color swatches.
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final c in _palette)
                  GestureDetector(
                    onTap: () => _patchText((x) => x.copyWith(color: c)),
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 10, top: 3),
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: t.color == c
                              ? AppColors.primary
                              : AppColors.border,
                          width: t.color == c ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Draws the boxes (and, for the selected one, an outline and corner dots).
class _BoxPainter extends CustomPainter {
  _BoxPainter({
    required this.boxes,
    required this.selected,
    required this.opacity,
    required this.showHandles,
  });

  final List<Rect> boxes;
  final int? selected;
  final double opacity;
  final bool showHandles;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = Colors.black.withValues(alpha: opacity);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white;
    final dotFill = Paint()..color = Colors.white;
    final dotLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.primary;

    for (var i = 0; i < boxes.length; i++) {
      final b = boxes[i];
      // Convert fractions (0..1) into real pixels.
      final r = Rect.fromLTRB(
        b.left * size.width,
        b.top * size.height,
        b.right * size.width,
        b.bottom * size.height,
      );
      canvas.drawRect(r, fill);

      if (showHandles && i == selected) {
        canvas.drawRect(r, outline);
        for (final corner in [r.topLeft, r.topRight, r.bottomRight, r.bottomLeft]) {
          canvas.drawCircle(corner, 8, dotFill);
          canvas.drawCircle(corner, 8, dotLine);
        }
      }
    }
  }

  // The boxes change while dragging, so just repaint every time.
  @override
  bool shouldRepaint(_BoxPainter oldDelegate) => true;
}

/// A small on/off button for bold / italic / underline.
class _StyleToggle extends StatelessWidget {
  const _StyleToggle({
    required this.icon,
    required this.on,
    required this.onTap,
  });

  final IconData icon;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: on ? AppColors.primarySoft : null,
        foregroundColor: on ? AppColors.primary : AppColors.textMuted,
      ),
    );
  }
}

/// A popup asking for the label's text (can be several lines).
class _TextDialog extends StatefulWidget {
  const _TextDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 1,
        maxLines: 4,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Text on the image'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('OK')),
      ],
    );
  }
}