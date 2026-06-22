import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../capture/capture_screen.dart';
import '../models/capsule.dart';
import '../state/capsule_provider.dart';

/// Two-step creation: capture the "before" photo, then name it + pick a preset.
class NewCapsuleScreen extends StatefulWidget {
  const NewCapsuleScreen({super.key});

  @override
  State<NewCapsuleScreen> createState() => _NewCapsuleScreenState();
}

class _NewCapsuleScreenState extends State<NewCapsuleScreen> {
  Uint8List? _beforeBytes;
  final _titleCtrl = TextEditingController();
  Preset? _preset;
  bool _saving = false;

  Future<void> _captureBefore() async {
    final bytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => const CaptureScreen(title: 'Before photo'),
      ),
    );
    if (bytes != null) setState(() => _beforeBytes = bytes);
  }

  Future<void> _save() async {
    if (_beforeBytes == null || _titleCtrl.text.trim().isEmpty ||
        _preset == null) {
      return;
    }
    setState(() => _saving = true);
    await context.read<CapsuleProvider>().create(
          title: _titleCtrl.text.trim(),
          beforeBytes: _beforeBytes!,
          preset: _preset!,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New capsule')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('1. Capture the "before" photo',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _captureBefore,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: _beforeBytes == null
                    ? Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_a_photo, size: 48),
                              SizedBox(height: 8),
                              Text('Tap to capture'),
                            ],
                          ),
                        ),
                      )
                    : Image.memory(_beforeBytes!, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('2. Name it', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'e.g. My beard, the front yard, the kitchen Reno',
            ),
          ),
          const SizedBox(height: 28),
          Text('3. Lock for…',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: [
              for (final p in Preset.values)
                ChoiceChip(
                  label: Text(p.label),
                  selected: _preset == p,
                  onSelected: (_) => setState(() => _preset = p),
                ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: (_beforeBytes == null ||
                    _titleCtrl.text.trim().isEmpty ||
                    _preset == null ||
                    _saving)
                ? null
                : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.lock),
            label: const Text('Seal the capsule'),
          ),
        ],
      ),
    );
  }
}