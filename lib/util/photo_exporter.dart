/// Exports captured frames (decrypted from the vault) to the system share
/// sheet as individual JPEG files — one or many at once.
///
/// Frames are encrypted at rest; to share them we decrypt each to a temporary
/// .jpg file in the system temp dir, hand the [XFile]s to share_plus, then
/// delete the temp files. We never write plaintext photos to a persistent
/// location.
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/capsule_repository.dart';
import '../models/capsule.dart';

class PhotoExporter {
  PhotoExporter._();

  /// Decrypts each frame and writes it to a temp .jpg file; returns the paths.
  static Future<List<String>> materialize(List<Frame> frames) async {
    final dir = await getTemporaryDirectory();
    final paths = <String>[];
    for (final f in frames) {
      final bytes = await CapsuleRepository.instance.readFrameBytes(f);
      final name =
          'reframe_${f.capsuleId}_${f.kind}_${f.id ?? f.capturedAt.millisecondsSinceEpoch}.jpg';
      final path = '${dir.path}/$name';
      await File(path).writeAsBytes(bytes, flush: true);
      paths.add(path);
    }
    return paths;
  }

  /// Decrypts + shares the given frames via the system share sheet (one or
  /// many), then cleans up the temp files. [text] is the optional share caption.
  static Future<void> share(List<Frame> frames, {String? text}) async {
    if (frames.isEmpty) return;
    final paths = await materialize(frames);
    try {
      await SharePlus.instance.share(ShareParams(
        files: paths.map((p) => XFile(p)).toList(),
        text: text,
      ));
    } finally {
      for (final p in paths) {
        try {
          await File(p).delete();
        } catch (_) {}
      }
    }
  }
}