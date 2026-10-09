import 'dart:io';

import 'package:flutter/material.dart';

import '../models/image_overlay.dart';
import '../theme/app_theme.dart';
import 'overlay_text.dart';

/// Shows an image with its text labels and black boxes (study / viewing).
/// Tapping a box calls [onToggle]. A box in [revealed] is see-through.
class OcclusionImageView extends StatelessWidget {
  const OcclusionImageView({
    super.key,
    required this.file,
    required this.overlay,
    required this.revealed,
    required this.onToggle,
  });

  final File file;
  final ImageOverlay overlay;
  final Set<int> revealed; // indexes of the boxes that are uncovered
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Center(
      // AspectRatio makes the area exactly the image's shape, so the
      // fractions we saved line up with the picture.
      child: AspectRatio(
        aspectRatio: overlay.aspect,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final h = c.maxHeight;

              // A Stack draws its children on top of each other:
              // image first, then text, then the boxes on top.
              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.file(
                      file,
                      fit: BoxFit.fill,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primarySoft,
                        child: const Icon(
                          Icons.broken_image_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  for (final t in overlay.texts)
                    Positioned(
                      left: t.x * w,
                      top: t.y * h,
                      child: OverlayText(item: t, canvasWidth: w),
                    ),
                  for (var i = 0; i < overlay.boxes.length; i++)
                    Positioned(
                      left: overlay.boxes[i].left * w,
                      top: overlay.boxes[i].top * h,
                      width: overlay.boxes[i].width * w,
                      height: overlay.boxes[i].height * h,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque, // see-through boxes still get taps
                        onTap: () => onToggle(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: revealed.contains(i)
                                ? Colors.transparent
                                : Colors.black,
                            // A revealed box keeps a faint outline so you can
                            // find it again and tap to cover it.
                            border: Border.all(
                              color: revealed.contains(i)
                                  ? AppColors.primary.withValues(alpha: 0.5)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}