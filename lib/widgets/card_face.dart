import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// One side of a card: a small label at the top and the text centered.
class CardFace extends StatelessWidget {
  const CardFace({
    super.key,
    required this.label,
    required this.text,
    this.tinted = false,
  });

  final String label;
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
              // If the text is very long, the card scrolls instead of overflowing.
              child: SingleChildScrollView(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 