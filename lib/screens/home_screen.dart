import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/capsule_repository.dart';
import '../models/capsule.dart';
import '../state/capsule_provider.dart';
import '../util/date_format.dart';
import 'capsule_detail_screen.dart';
import 'delete_capsule_dialog.dart';
import 'help_about_screen.dart';
import 'new_capsule_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late StreamSubscription<DateTime> _clockSub;

  @override
  void initState() {
    super.initState();
    _clockSub =
        context.read<CapsuleProvider>().clock.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CapsuleProvider>();
    final capsules = provider.capsules;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reframe'),
        actions: [
          IconButton(
            tooltip: 'Help & About',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpAboutScreen()),
            ),
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : capsules.isEmpty
              ? const _EmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: capsules.length,
                  itemBuilder: (context, i) {
                    final c = capsules[i];
                    return _CapsuleCard(capsule: c, now: now);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_a_photo),
        label: const Text('New capsule'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewCapsuleScreen()),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_clock,
                size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            const Text('Capture a moment. Seal it. Re-shoot it later.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
                'Start a capsule with a "before" photo, lock it behind a '
                'countdown, then re-shoot the same scene when it opens.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _CapsuleCard extends StatelessWidget {
  const _CapsuleCard({required this.capsule, required this.now});

  final Capsule capsule;
  final DateTime now;

  void _open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CapsuleDetailScreen(capsuleId: capsule.id!),
      ),
    );
  }

  Future<void> _showCardMenu(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open capsule'),
              onTap: () => Navigator.pop(ctx, 'open'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete capsule',
                  style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'open') {
      _open(context);
    } else if (action == 'delete') {
      final provider = context.read<CapsuleProvider>();
      if (await showDeleteCapsuleDialog(context, capsule)) {
        await provider.delete(capsule.id!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = capsule.statusAt(now);
    final ref = capsule.referenceFrame;
    return GestureDetector(
      onTap: () => _open(context),
      onLongPress: () => _showCardMenu(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (ref != null)
              _FrameThumb(frame: ref, blur: status == CapsuleStatus.locked)
            else
              ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(
                    child: Icon(Icons.photo_camera, color: Colors.white38)),
              ),
            // gradient + text
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                    stops: const [0.5, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(capsule.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  _StatusChip(status: status, capsule: capsule, now: now),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(
      {required this.status, required this.capsule, required this.now});

  final CapsuleStatus status;
  final Capsule capsule;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      CapsuleStatus.locked => (
          formatRemaining(capsule.remainingAt(now) ?? Duration.zero),
          Colors.amber,
          Icons.lock_clock
        ),
      CapsuleStatus.readyToCapture => (
          'ready to capture',
          Colors.greenAccent,
          Icons.camera
        ),
      CapsuleStatus.awaitingRelock => (
          'relock or finalize',
          Colors.lightBlueAccent,
          Icons.timer
        ),
      CapsuleStatus.finalized => (
          'finalized · ${capsule.afterFrames.length} after',
          Colors.white70,
          Icons.check_circle
        ),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 12)),
        ),
      ],
    );
  }
}

/// Loads + caches decrypted frame bytes, renders as a thumbnail.
class _FrameThumb extends StatefulWidget {
  const _FrameThumb({required this.frame, this.blur = false});

  final Frame frame;
  final bool blur;

  @override
  State<_FrameThumb> createState() => _FrameThumbState();
}

class _FrameThumbState extends State<_FrameThumb> {
  Uint8List? _bytes;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _bytes = await CapsuleRepository.instance.readFrameBytes(widget.frame);
    } catch (_) {}
    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _bytes == null) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final image = Image.memory(_bytes!, fit: BoxFit.cover);
    return widget.blur
        ? ImageFiltered(
            imageFilter: _blurFilter,
            child: image,
          )
        : image;
  }
}

final _blurFilter = ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14);