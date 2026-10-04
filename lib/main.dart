// 'import' pulls in code from other files so we can use it here.
// 'package:flutter/material.dart' is Flutter's built-in toolkit of widgets
// (buttons, text, app bars, etc.).
import 'package:flutter/material.dart';

// These two are our own files. The '../' or 'screens/' parts are paths
// relative to this file, which is inside the lib folder.
import 'screens/library_screen.dart';
import 'theme/app_theme.dart';

// main() is where every Dart program starts running.
void main() {
  // runApp() takes a widget and makes it the root of the whole app.
  runApp(const FlashcardsApp());
}

// A StatelessWidget is a widget that doesn't hold changing data.
// It just describes what to draw. FlashcardsApp is the top-level
// widget of the app.
class FlashcardsApp extends StatelessWidget {
  // The constructor. 'super.key' passes an optional identifier up to
  // Flutter (it uses keys to track widgets). You can mostly ignore it.
  const FlashcardsApp({super.key});

  // build() is called by Flutter whenever it needs to draw this widget.
  // It must return the widget (or tree of widgets) to show.
  // 'context' tells the widget where it lives in the tree.
  @override
  Widget build(BuildContext context) {
    // MaterialApp sets up the basics of an app: navigation, theme,
    // and which screen to show first.
    return MaterialApp(
      // The name of the app (shown in the phone's app switcher).
      title: 'Flashcards',
      // Hides the red "DEBUG" ribbon in the corner while testing.
      debugShowCheckedModeBanner: false,
      // Our custom look, defined in app_theme.dart.
      theme: AppTheme.light,
      // The first screen the user sees.
      home: const LibraryScreen(),
    );
  }
}