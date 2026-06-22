/// Reusable warning confirmation dialog for deleting a capsule.
///
/// Returns true if the user confirmed the deletion. The caller performs the
/// actual deletion + navigation. Used from both the home grid (long-press a
/// card) and the capsule detail screen.
library;

import 'package:flutter/material.dart';

import '../models/capsule.dart';

Future<bool> showDeleteCapsuleDialog(BuildContext context, Capsule capsule) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded,
          color: Colors.red, size: 40),
      title: const Text('Delete this capsule?'),
      content: Text(
        '“${capsule.title}” and all ${capsule.frames.length} photo(s) it holds '
        'will be permanently erased from this device.\n\n'
        'This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return ok == true;
}