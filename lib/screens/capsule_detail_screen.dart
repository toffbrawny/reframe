import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../capture/capture_screen.dart';
import '../data/capsule_repository.dart';
import '../models/capsule.dart';
import '../state/capsule_provider.dart';
import '../util/date_format.dart';
import 'gallery_screen.dart';

class CapsuleDetailScreen extends StatefulWidget {
  const CapsuleDetailScreen({super.key, required this.capsuleId});

  final int capsuleId;

  @override
  State<CapsuleDetailScreen> createState() => _CapsuleDetailScreenState();
}

class _CapsuleDetailScreenState extends State<CapsuleDetailScreen> {
  late StreamSubscription<DateTime> _clockSub;

  @override
  void initState() {
    super.initState();
    _clockSub = context.read<CapsuleProvider>().clock.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockSub.cancel();
    super.dispose();
  }

  Capsule? _capsule(BuildContext context) =>
      context.read<CapsuleProvider>().capsules
          .firstWhereOrNull((c) => c.id == widget.capsuleId);

  Future<void> _confirmDelete(Capsule c) async {
    final provider = context.read<CapsuleProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete capsule?'),
        content: Text(
            'This permanently deletes "${c.title}" and all ${c.frames.length} photos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await provider.delete(c.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _capsule(context);
    if (c == null) {
      // Deleted or missing.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return const Scaffold(body: SizedBox.shrink());
    }
    final now = DateTime.now();
    final status = c.statusAt(now);
    final remaining = c.remainingAt(now);

    return Scaffold(
      appBar: AppBar(
        title: Text(c.title),
        actions: [
          IconButton(
            tooltip: 'Browse photos',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    GalleryScreen(capsuleId: widget.capsuleId),
              ),
            ),
            icon: const Icon(Icons.photo_library),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(c),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusHero(status: status, remaining: remaining, c: c),
          const SizedBox(height: 16),
          _StatsCard(c: c),
          const SizedBox(height: 24),
          Text('Timeline (${c.frames.length} photos)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text('Tap a photo to view it full-screen',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 12),
          for (var i = 0; i < [c.beforeFrame, ...c.afterFrames].length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _TimelineRow(
                frame: [c.beforeFrame, ...c.afterFrames][i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FrameViewerScreen(
                      capsuleId: widget.capsuleId,
                      startIndex: i,
                    ),
                  ),
                ),
              ),
            ),
          if (kDebugMode) ...[
            const Divider(),
            const Text('Debug', style: TextStyle(color: Colors.white38)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    final provider = context.read<CapsuleProvider>();
                    await CapsuleRepository.instance.debugUnlockNow(c.id!);
                    await provider.refresh();
                  },
                  child: const Text('Fast-forward unlock'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero(
      {required this.status, required this.remaining, required this.c});

  final CapsuleStatus status;
  final Duration? remaining;
  final Capsule c;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            switch (status) {
              CapsuleStatus.locked => _LockedView(remaining: remaining!, c: c),
              CapsuleStatus.readyToCapture =>
                _ReadyView(onCapture: () => _captureAfter(context, c)),
              CapsuleStatus.awaitingRelock => _AwaitingRelockView(c: c),
              CapsuleStatus.finalized =>
                const _FinalizedView(),
            },
          ],
        ),
      ),
    );
  }

  void _captureAfter(BuildContext context, Capsule c) async {
    final ref = c.referenceFrame;
    Uint8List? refBytes;
    if (ref != null) refBytes = await CapsuleRepository.instance.readFrameBytes(ref);
    if (!context.mounted) return;
    final bytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => CaptureScreen(
          title: 'After photo',
          referenceBytes: refBytes,
        ),
      ),
    );
    if (bytes != null) {
      if (!context.mounted) return;
      await context.read<CapsuleProvider>().addAfter(
            capsuleId: c.id!,
            afterBytes: bytes,
          );
    }
  }
}

class _LockedView extends StatelessWidget {
  const _LockedView({required this.remaining, required this.c});
  final Duration remaining;
  final Capsule c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lock_clock, color: Colors.amber),
            const SizedBox(width: 8),
            Text('Locked',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        Text(formatRemaining(remaining),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Unlocks ${formatDate(c.unlockAt!)}',
            style: const TextStyle(color: Colors.white54)),
      ],
    );
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({required this.onCapture});
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.camera, color: Colors.greenAccent),
            const SizedBox(width: 8),
            Text('It’s time!',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Re-shoot the same scene now. The last frame is shown '
            'as a guide so your shot lines up.'),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onCapture,
          icon: const Icon(Icons.camera),
          label: const Text('Capture after photo'),
        ),
      ],
    );
  }
}

class _AwaitingRelockView extends StatelessWidget {
  const _AwaitingRelockView({required this.c});
  final Capsule c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.timer, color: Colors.lightBlueAccent),
            const SizedBox(width: 8),
            Text('Captured! Keep going?',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Re-lock for another period to capture the next shot, '
            'or finalize the timeline.'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in Preset.values)
              FilledButton.tonalIcon(
                onPressed: () =>
                    context.read<CapsuleProvider>().relock(c.id!, p.duration),
                icon: const Icon(Icons.lock),
                label: Text(p.label),
              ),
            OutlinedButton(
              onPressed: () =>
                  context.read<CapsuleProvider>().finalizeCapsule(c.id!),
              child: const Text('Finalize'),
            ),
          ],
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 12),
          Text('Debug relock (rapid testing)',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in DebugPreset.values)
                FilledButton.tonalIcon(
                  onPressed: () => context
                      .read<CapsuleProvider>()
                      .relock(c.id!, d.duration),
                  icon: const Icon(Icons.lock_clock),
                  label: Text(d.label),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _FinalizedView extends StatelessWidget {
  const _FinalizedView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white70),
            const SizedBox(width: 8),
            Text('Timeline complete',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Browse the timeline and export your photos.'),
      ],
    );
  }
}

/// Smart stats summarizing the capsule's timeline: how many photos, when the
/// first and last were captured, the overall span, and the average gap between
/// re-shots.
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.c});

  final Capsule c;

  @override
  Widget build(BuildContext context) {
    final first = c.beforeFrame.capturedAt;
    final last = c.referenceFrame?.capturedAt ?? first;
    final span = last.difference(first);
    final afterCount = c.afterFrames.length;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Capsule stats', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            _row('Photos', '${c.frames.length}'),
            _row('Re-shots', '$afterCount'),
            _row('First capture', formatDate(first)),
            if (afterCount > 0) ...[
              _row('Last capture', formatDate(last)),
              _row('Time span', formatSpan(span)),
              _row(
                  'Avg gap',
                  formatSpan(Duration(
                      microseconds: span.inMicroseconds ~/ afterCount))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60)),
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _TimelineRow extends StatefulWidget {
  const _TimelineRow({required this.frame, this.onTap});
  final Frame frame;
  final VoidCallback? onTap;

  @override
  State<_TimelineRow> createState() => _TimelineRowState();
}

class _TimelineRowState extends State<_TimelineRow> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _bytes = await CapsuleRepository.instance.readFrameBytes(widget.frame);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 90,
              height: 120,
              child: _bytes == null
                  ? const ColoredBox(
                      color: Colors.white12,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                  : Image.memory(_bytes!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.frame.kind == 'before'
                        ? Colors.amber.withValues(alpha: 0.25)
                        : Colors.greenAccent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.frame.kind == 'before' ? 'BEFORE' : 'AFTER',
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.frame.kind == 'before'
                          ? Colors.amber
                          : Colors.greenAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(formatDate(widget.frame.capturedAt),
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                const Text('Tap to view',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// extension: firstWhereOrNull fallback for Dart lists (avoids extra package)
extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}