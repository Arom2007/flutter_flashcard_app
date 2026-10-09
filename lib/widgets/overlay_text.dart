import 'dart:math';

import 'package:flutter/material.dart';

import '../models/image_overlay.dart';
import '../theme/app_theme.dart';

/// Draws one text label on an image. Used by both the editor and study mode
/// so the label looks exactly the same in both.
class OverlayText extends StatelessWidget {
  const OverlayText({
    super.key,
    required this.item,
    required this.canvasWidth,
    this.selected = false,
  });

  final TextOverlay item;
  final double canvasWidth; // width of the image on screen, in pixels
  final bool selected; // the editor shows an outline on the selected label

  @override
  Widget build(BuildContext context) {
    // Don't let the text run off the right edge: it wraps instead.
    final maxWidth = max(canvasWidth * (1 - item.x), canvasWidth * 0.1);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.all(4),
        // The border is always there (just see-through when not selected)
        // so selecting a label never shifts it by a pixel.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          item.text,
          style: TextStyle(
            // The size is a fraction of the image width, so it scales.
            fontSize: item.size * canvasWidth,
            color: Color(item.color),
            fontWeight: item.bold ? FontWeight.w700 : FontWeight.w400,
            fontStyle: item.italic ? FontStyle.italic : FontStyle.normal,
            decoration:
                item.underline ? TextDecoration.underline : TextDecoration.none,
            fontFamily: item.fontFamily.isEmpty ? null : item.fontFamily,
            height: 1.15,
          ),
        ),
      ),
    );
  }
}