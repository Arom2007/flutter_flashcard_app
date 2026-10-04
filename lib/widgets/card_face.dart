import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'rich_content.dart';

/// One side of a card: a small label at the top and the content centered.
class CardFace extends StatelessWidget {
  const CardFace({
    super.key,
    required this.label,
    required this.text,
    this.tinted = false,
  });

  final String label;

  /// The card's stored content: rich text (JSON) or plain text from older
  /// cards. RichContent understands both. (The name 'text' is kept so the
  /// study and viewer screens don't need to change.)
  final String text;
  final bool tinted; // the answer side gets a soft blue background

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: tinted ? AppColors.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          Expanded(
            child: Center(
              // If the content is very long, the card scrolls.
              child: SingleChildScrollView(
                // Full width, so the alignment buttons (left / center /
                // right) have room to show their effect.
                child: SizedBox(
                  width: double.infinity,
                  child: RichContent(content: text),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}