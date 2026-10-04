import 'package:flutter/material.dart';

/// All colors live here so the whole app can be re-themed in one place.
/// Change a color below and it changes everywhere it's used.
class AppColors {
  // 'static' means you can use AppColors.background without creating an
  // AppColors object. 'const' means the value is fixed.
  //
  // Color(0xFFF7F6F3) is a hex color. '0x' says "this is hex", the first
  // 'FF' means fully opaque, and the last six characters (F7F6F3) are the
  // usual red-green-blue hex code you'd see on a website.
  static const background = Color(0xFFF7F6F3); // warm off-white
  static const surface = Colors.white; // cards and input fields
  static const primary = Color(0xFF3D5A80); // muted blue, our main accent
  static const onPrimary = Colors.white; // text/icons placed ON the primary color
  static const text = Color(0xFF1F2430); // near-black for main text
  static const textMuted = Color(0xFF8A8F9C); // grey for secondary text
  static const border = Color(0xFFE8E6E1); // thin outlines around cards
  static const primarySoft = Color(0xFFE6ECF4); // pale tint of the primary blue
}

class AppTheme {
  // How round the corners of cards are. Higher number = rounder.
  static const double radius = 20;

  // A 'getter': you use it like AppTheme.light (no brackets), and it
  // builds and returns a complete ThemeData each time.
  static ThemeData get light {
    // A ColorScheme is a set of matching colors that Material widgets
    // use automatically. fromSeed() generates a whole palette from one
    // color, so every widget gets sensible default colors.
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      // copyWith() takes the generated palette and overrides just the
      // colors we care about with our exact choices.
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      outlineVariant: AppColors.border,
    );

    // A plain default theme, used only so we can grab Flutter's standard
    // text styles from it and then tweak them below.
    final base = ThemeData(brightness: Brightness.light, useMaterial3: true);

    // ThemeData is the big settings object. Each entry below styles one
    // kind of widget for the entire app.
    return ThemeData(
      useMaterial3: true, // use Google's current Material 3 design
      colorScheme: scheme, // the palette we built above
      scaffoldBackgroundColor: AppColors.background, // background of every screen
      textTheme: _textTheme(base.textTheme), // our tweaked fonts (see bottom)

      // Style of the bar at the top of each screen.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background, // blends in with the screen
        foregroundColor: AppColors.text, // color of icons in the bar
        elevation: 0, // no shadow
        scrolledUnderElevation: 0, // no color change when content scrolls under it
        centerTitle: false, // title on the left, not centered
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 24,
          fontWeight: FontWeight.w600, // 600 = semi-bold
          letterSpacing: -0.4, // slightly tighter letters looks cleaner
        ),
      ),

      // Style of every Card widget: white, flat, rounded, thin border.
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0, // flat, no drop shadow
        margin: EdgeInsets.zero, // no built-in space around the card
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius), // the rounded corners
          side: const BorderSide(color: AppColors.border), // the thin outline
        ),
      ),

      // Style of the round "+" style floating button.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 1, // a very subtle shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Style of FilledButton (the solid-colored buttons we'll use later).
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(0, 48), // at least 48 tall, any width
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // Style of text boxes (we'll use these for naming folders, etc.).
      inputDecorationTheme: InputDecorationTheme(
        filled: true, // fill the box with a color
        fillColor: AppColors.surface,
        // 'border' is the default outline; 'enabledBorder' is the outline
        // when the box isn't selected; 'focusedBorder' is the outline when
        // the user taps into it (a bit thicker and blue).
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),

      // Style of thin divider lines between list items.
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
    );
  }

  // A private helper (the leading underscore means "only usable inside
  // this file"). It takes Flutter's default text styles and adjusts a few.
  static TextTheme _textTheme(TextTheme base) {
    return base
        .copyWith(
          // The '?.' means "if this style exists, then copy it with changes".
          // Headings get bolder and slightly tighter letter spacing.
          headlineSmall: base.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          // 'height: 1.4' = line spacing, so paragraphs breathe a little.
          bodyMedium: base.bodyMedium?.copyWith(height: 1.4),
        )
        // apply() then sets the text color for ALL styles at once.
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text);
  }
}