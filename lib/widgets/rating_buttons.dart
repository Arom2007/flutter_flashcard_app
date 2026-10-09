import 'package:flutter/material.dart';

import '../providers/study_session.dart';
import '../theme/app_theme.dart';

/// The four buttons shown after a card is flipped:
/// Very Hard, Hard, Medium, Easy.
class RatingButtons extends StatelessWidget {
  const RatingButtons({super.key, required this.onRate});

  final ValueChanged<Rating> onRate; // called with the rating that was tapped

  // A color for each rating (terracotta -> amber -> blue -> green).
  // Medium uses the app's main blue, so it always matches the theme.
  static const _colors = {
    Rating.veryHard: Color(0xFFB4492F),
    Rating.hard: Color(0xFFB7791F),
    Rating.medium: AppColors.primary,
    Rating.easy: Color(0xFF3F7D5A),
  };

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    // Rating.values lists the ratings in the order they were declared.
    for (final rating in Rating.values) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 8));
      children.add(
        // Expanded makes the four buttons share the width equally.
        Expanded(
          child: _RatingButton(
            label: rating.label,
            color: _colors[rating]!, // '!' = "I know this isn't null"
            onTap: () => onRate(rating),
          ),
        ),
      );
    }

    return Row(children: children);
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      // A very pale version of the color as the background.
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      // InkWell adds the ripple effect when tapped.
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}