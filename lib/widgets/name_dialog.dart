import 'package:flutter/material.dart';

/// Shows a popup asking for a name. Returns the typed name,
/// or null if the user cancelled. Used for both "New" and "Rename".
Future<String?> showNameDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initialName = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NameDialog(
      title: title,
      confirmLabel: confirmLabel,
      initialName: initialName,
    ),
  );
}

// A StatefulWidget is a widget that can remember things that change.
// We need one here because the text box has a controller to clean up.
class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.confirmLabel,
    required this.initialName,
  });

  final String title;
  final String confirmLabel;
  final String initialName;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  // The controller reads (and sets) what's typed in the text box.
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName);

  // dispose() runs when the dialog closes; free the controller's memory.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim(); // trim() removes extra spaces
    if (name.isEmpty) return; // ignore empty names
    Navigator.pop(context, name); // close the dialog and hand back the name
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true, // keyboard opens straight away
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Folder name'),
        onSubmitted: (_) => _submit(), // the keyboard's "done" key
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // returns null
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}