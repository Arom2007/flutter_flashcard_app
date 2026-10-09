import 'dart:convert';
import 'dart:ui' show Rect;

/// One piece of text placed on an image. Position and size are fractions
/// of the image, so they scale to any screen.
class TextOverlay {
  const TextOverlay({
    required this.text,
    this.x = 0.3, // left edge: 0 = far left, 1 = far right
    this.y = 0.4, // top edge: 0 = top, 1 = bottom
    this.size = 0.06, // font size as a fraction of the image WIDTH
    this.color = 0xFF000000, // an ARGB number, e.g. 0xFFD64545
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.fontFamily = '', // '' means the default font
  });

  final String text;
  final double x;
  final double y;
  final double size;
  final int color;
  final bool bold;
  final bool italic;
  final bool underline;
  final String fontFamily;

  /// A copy with some fields changed (the object itself never changes).
  TextOverlay copyWith({
    String? text,
    double? x,
    double? y,
    double? size,
    int? color,
    bool? bold,
    bool? italic,
    bool? underline,
    String? fontFamily,
  }) {
    return TextOverlay(
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
      size: size ?? this.size,
      color: color ?? this.color,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  Map<String, Object> toJson() => {
        't': text,
        'x': x,
        'y': y,
        's': size,
        'c': color,
        'b': bold,
        'i': italic,
        'u': underline,
        'f': fontFamily,
      };

  factory TextOverlay.fromJson(Map<String, dynamic> j) {
    return TextOverlay(
      text: j['t'] as String? ?? '',
      x: (j['x'] as num?)?.toDouble() ?? 0.3,
      y: (j['y'] as num?)?.toDouble() ?? 0.4,
      size: (j['s'] as num?)?.toDouble() ?? 0.06,
      color: (j['c'] as num?)?.toInt() ?? 0xFF000000,
      bold: j['b'] == true,
      italic: j['i'] == true,
      underline: j['u'] == true,
      fontFamily: j['f'] as String? ?? '',
    );
  }
}

/// Everything drawn on top of an image card's picture.
class ImageOverlay {
  const ImageOverlay({
    required this.aspect,
    this.boxes = const [],
    this.texts = const [],
  });

  final double aspect; // image width / height
  final List<Rect> boxes; // each Rect's numbers are fractions from 0 to 1
  final List<TextOverlay> texts;

  /// The string saved in the database's 'boxes' column.
  String toJsonString() => jsonEncode({
        'aspect': aspect,
        'boxes': [
          for (final r in boxes) [r.left, r.top, r.right, r.bottom],
        ],
        'texts': [for (final t in texts) t.toJson()],
      });

  /// Reads the saved string back. Returns null if there is none (text cards)
  /// or if it is damaged.
  static ImageOverlay? tryParse(String? source) {
    if (source == null || source.isEmpty) return null;
    try {
      final map = jsonDecode(source) as Map<String, dynamic>;
      final boxes = <Rect>[];
      for (final b in (map['boxes'] as List? ?? [])) {
        final n = (b as List).map((e) => (e as num).toDouble()).toList();
        boxes.add(Rect.fromLTRB(n[0], n[1], n[2], n[3]));
      }
      final texts = [
        for (final t in (map['texts'] as List? ?? []))
          TextOverlay.fromJson(t as Map<String, dynamic>),
      ];
      return ImageOverlay(
        aspect: (map['aspect'] as num?)?.toDouble() ?? 1,
        boxes: boxes,
        texts: texts,
      );
    } catch (_) {
      return null;
    }
  }
}