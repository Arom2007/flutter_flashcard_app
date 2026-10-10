import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;

import 'data/font_service.dart';
import 'data/image_store.dart';
import 'screens/library_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep the app upright. The editors and study card are designed for
  // portrait. Delete this line to allow rotation again.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Re-load imported fonts and prepare the folder that holds card images.
  await FontService.instance.init();
  await ImageStore.instance.init();
  runApp(const FlashcardsApp());
}

class FlashcardsApp extends StatelessWidget {
  const FlashcardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrashCards',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
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