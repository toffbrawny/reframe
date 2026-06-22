/// Browse a capsule's captured frames: a tappable grid that opens a
/// full-screen swipeable viewer, plus a multi-select mode for batch-exporting
/// individual photos via the system share sheet.
///
/// Frames are decrypted on demand from the vault. Only frames that exist (the
/// before shot + any after shots already captured) are shown — the lock on the
/// *next* capture is handled on the detail screen.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/capsule_repository.dart';
import '../models/capsule.dart';
import '../state/capsule_provider.dart';
import '../util/date_format.dart';
import '../util/photo_exporter.dart';

/// Grid gallery with multi-select + batch export.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, required this.capsuleId});

  final int capsuleId;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _selectMode = false;
  final Set<int> _selected = {}; // frame ids
  bool _exporting = false;

  Capsule? _capsule(BuildContext c) =>
      c.read<CapsuleProvider>().capsules.firstWhereOrNull((x) => x.id == widget.capsuleId);

  List<Frame> _orderedFrames(Capsule c) => [c.beforeFrame, ...c.afterFrames];

  Future<void> _exportSelected(Capsule c) async {
    final frames =
        _orderedFrames(c).where((f) => _selected.contains(f.id)).toList();
    if (frames.isEmpty) return;
    setState(() => _exporting = true);
    try {
      await PhotoExporter.share(frames, text: '${c.title} — Reframe');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _capsule(context);
    if (c == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return const Scaffold(body: SizedBox.shrink());
    }
    final frames = _orderedFrames(c);
    final allSelected = _selected.length == frames.length && frames.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectMode
            ? (_selected.isEmpty ? 'Select photos' : '${_selected.length} selected')
            : c.title),
        leading: IconButton(
          icon: Icon(_selectMode ? Icons.close : Icons.arrow_back),
          onPressed: () {
            if (_selectMode) {
              setState(() {
                _selectMode = false;
                _selected.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (!_selectMode)
            TextButton(
              onPressed: frames.isEmpty
                  ? null
                  : () => setState(() => _selectMode = true),
              child: const Text('Select'),
            )
          else ...[
            TextButton(
              onPressed: () => setState(() {
                if (allSelected) {
                  _selected.clear();
                } else {
                  _selected.clear();
                  _selected.addAll(frames.map((f) => f.id!));
                }
              }),
              child: Text(allSelected ? 'Clear' : 'Select all'),
            ),
          ],
        ],
      ),
      body: frames.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No photos yet.', style: TextStyle(color: Colors.white54)),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: frames.length,
              itemBuilder: (context, i) {
                final f = frames[i];
                final selected = _selected.contains(f.id);
                return _FrameCell(
                  frame: f,
                  selected: selected,
                  selectMode: _selectMode,
                  onTap: () {
                    if (_selectMode) {
                      setState(() {
                        if (selected) {
                          _selected.remove(f.id);
                        } else {
                          _selected.add(f.id!);
                        }
                      });
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FrameViewerScreen(
                            capsuleId: widget.capsuleId,
                            startIndex: i,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
      bottomNavigationBar: _selectMode
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Text('${_selected.length} selected',
                        style: const TextStyle(color: Colors.white70)),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: (_exporting || _selected.isEmpty)
                          ? null
                          : () => _exportSelected(c),
                      icon: _exporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.ios_share),
                      label: Text(_selected.isEmpty
                          ? 'Export'
                          : 'Export ${_selected.length}'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

/// A single grid cell: decrypted thumbnail + BEFORE/AFTER badge, with a
/// selection check overlay when in select mode.
class _FrameCell extends StatefulWidget {
  const _FrameCell({
    required this.frame,
    required this.selected,
    required this.selectMode,
    required this.onTap,
  });

  final Frame frame;
  final bool selected;
  final bool selectMode;
  final VoidCallback onTap;

  @override
  State<_FrameCell> createState() => _FrameCellState();
}

class _FrameCellState extends State<_FrameCell> {
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
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_bytes == null)
              const ColoredBox(
                color: Colors.white12,
                child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              Image.memory(_bytes!, fit: BoxFit.cover),
            // subtle gradient for legibility of the badge
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
                    stops: const [0, 0.25, 0.75, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 6,
              child: Text(
                widget.frame.kind == 'before' ? 'BEFORE' : 'AFTER',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: widget.frame.kind == 'before'
                      ? Colors.amber
                      : Colors.greenAccent,
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              left: 6,
              right: 6,
              child: Text(
                formatDateShort(widget.frame.capturedAt),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
            if (widget.selectMode)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.black54,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    widget.selected ? Icons.check : null,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen swipeable viewer for a capsule's frames. Tap toggles the chrome;
/// the AppBar's share action exports the current frame.
class FrameViewerScreen extends StatefulWidget {
  const FrameViewerScreen({
    super.key,
    required this.capsuleId,
    this.startIndex = 0,
  });

  final int capsuleId;
  final int startIndex;

  @override
  State<FrameViewerScreen> createState() => _FrameViewerScreenState();
}

class _FrameViewerScreenState extends State<FrameViewerScreen> {
  late PageController _pc;
  int _index = 0;
  bool _chrome = true;
  bool _sharing = false;
  final Map<int, Uint8List> _cache = {};

  Capsule? _capsule(BuildContext c) =>
      c.read<CapsuleProvider>().capsules.firstWhereOrNull((x) => x.id == widget.capsuleId);

  List<Frame> _orderedFrames(Capsule c) => [c.beforeFrame, ...c.afterFrames];

  @override
  void initState() {
    super.initState();
    _index = widget.startIndex;
    _pc = PageController(initialPage: widget.startIndex);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<Uint8List> _bytes(Frame f) async {
    final id = f.id;
    if (id != null && _cache.containsKey(id)) return _cache[id]!;
    final b = await CapsuleRepository.instance.readFrameBytes(f);
    if (id != null) _cache[id] = b;
    return b;
  }

  Future<void> _shareCurrent(Capsule c, List<Frame> frames) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await PhotoExporter.share([frames[_index]],
          text: '${c.title} — Reframe');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Share failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _capsule(context);
    if (c == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return const Scaffold(body: SizedBox.shrink());
    }
    final frames = _orderedFrames(c);
    final current = frames.isEmpty ? null : frames[_index.clamp(0, frames.length - 1)];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _chrome
          ? AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.4),
              title: Text(current == null
                  ? ''
                  : '${_index + 1} / ${frames.length} · ${current.kind == 'before' ? 'Before' : 'After'}'),
              actions: [
                if (current != null)
                  IconButton(
                    tooltip: 'Share this photo',
                    onPressed: _sharing ? null : () => _shareCurrent(c, frames),
                    icon: _sharing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.ios_share),
                  ),
              ],
            )
          : null,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pc,
            itemCount: frames.length,
            allowImplicitScrolling: true,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final f = frames[i];
              return GestureDetector(
                onTap: () => setState(() => _chrome = !_chrome),
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: FutureBuilder<Uint8List>(
                    future: _bytes(f),
                    builder: (context, snap) {
                      if (snap.data == null) {
                        return const CircularProgressIndicator(color: Colors.white);
                      }
                      return InteractiveViewer(
                        child: Image.memory(snap.data!, fit: BoxFit.contain),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          if (_chrome && frames.length > 1)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Text(
                    current == null ? '' : formatDate(current.capturedAt),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// extension: firstWhereOrNull fallback for Dart lists (avoids an extra package)
extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}