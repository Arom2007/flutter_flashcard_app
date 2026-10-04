import 'package:flutter/material.dart';
// Flutter's built-in text translations. flutter_quill's toolbar needs them.
import 'package:flutter_localizations/flutter_localizations.dart';
// 'show' imports ONLY the names we list. That avoids name clashes between
// flutter_quill and Flutter's own widgets.
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;

import 'data/font_service.dart';
import 'screens/library_screen.dart';
import 'theme/app_theme.dart';

// main() is now 'async' because we must wait for the imported fonts to be
// loaded before the first screen is drawn. 'Future<void>' = "finishes later".
Future<void> main() async {
  // Needed before using plugins (like path_provider) ahead of runApp().
  WidgetsFlutterBinding.ensureInitialized();
  // Re-load every font the user imported in the past.
  await FontService.instance.init();
  runApp(const FlashcardsApp());
}

class FlashcardsApp extends StatelessWidget {
  const FlashcardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flashcards',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // These "delegates" supply the built-in words (tooltips, button
      // labels...) that Flutter and the Quill toolbar need.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      home: const LibraryScreen(),
    );
  }
}   