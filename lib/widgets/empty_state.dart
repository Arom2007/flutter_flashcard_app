import 'package:flutter/material.dart';

import '../theme/app_theme.dart'; // '../' means "go up one folder, then into theme"

/// A calm, centered message shown when a list has nothing in it yet.
/// We made it a separate widget so we can reuse it on other screens
/// (for example an empty deck) just by passing different text.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    // 'required' means whoever uses EmptyState MUST provide these three
    // values. 'this.icon' automatically stores the value in the field below.
    required this.icon,
    required this.title,
    required this.message,
  });

  // 'final' means the value is set once and never changes.
  final IconData icon; // which icon to show
  final String title; // big heading text
  final String message; // smaller explanation text

  @override
  Widget build(BuildContext context) {
    // Grab the app's text styles from the theme we made in app_theme.dart.
    final textTheme = Theme.of(context).textTheme;

    // Center puts its child in the middle of the available space.
    return Center(
      // Padding adds empty space around its child.
      child: Padding(
        // Space on the left and right only (40 pixels each side).
        padding: const EdgeInsets.symmetric(horizontal: 40),
        // A Column stacks its children vertically.
        child: Column(
          // 'min' makes the column only as tall as its contents, so Center
          // can actually center it. Without this it would stretch full height.
          mainAxisSize: MainAxisSize.min,
          children: [
            // The soft blue rounded square behind the icon.
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(icon, size: 44, color: AppColors.primary),
            ),
            // SizedBox is an invisible box, used here as a spacer.
            const SizedBox(height: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              // Use the normal body style, but override the color to grey.
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}