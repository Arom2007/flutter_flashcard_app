import 'package:flutter/material.dart';

import 'screens/library_screen.dart';
import 'theme/app_theme.dart';

void main() {
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
      home: const LibraryScreen(),
    );
  }
}