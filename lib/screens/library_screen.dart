import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';

/// Home screen. Later it will list folders and decks; for now it's empty.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: const EmptyState(
        icon: Icons.folder_open_rounded,
        title: 'Nothing here yet',
        message: 'Create your first folder to start\norganizing your flashcards.',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Placeholder: real folder creation arrives in the next stage.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming in the next stage')),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New folder'),
      ),
    );
  }
}