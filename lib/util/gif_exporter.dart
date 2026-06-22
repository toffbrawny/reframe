/// Stitches a capsule's timeline into an animated GIF.
///
/// Each photo is decoded, resized so its longest edge is at most [maxEdge]
/// (to keep file size sane), and emitted as two held frames (~1s each) so the
/// flip between then/now reads cleanly. Output is written to a temp file the
/// caller shares via share_plus.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class GifExporter {
  /// Builds a GIF from [frames] (ordered JPEG bytes: before, after1, ...).
  /// Returns the temp [File] path on success, or null if empty.
  static Future<String?> export(List<Uint8List> frames,
      {int maxEdge = 720, int frameMs = 1000}) async {
    if (frames.isEmpty) return null;

    final images = <img.Image>[];
    for (final bytes in frames) {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) continue;
      img.Image sized = decoded;
      final longest = decoded.width > decoded.height
          ? decoded.width
          : decoded.height;
      if (longest > maxEdge) {
        sized = img.copyResize(decoded,
            width: decoded.width > decoded.height
                ? maxEdge
                : (decoded.width * maxEdge ~/ longest),
            height: decoded.height >= decoded.width
                ? maxEdge
                : (decoded.height * maxEdge ~/ longest));
      }
      images.add(sized);
    }
    if (images.isEmpty) return null;

    final gif = img.GifEncoder();
    for (final im in images) {
      gif.addFrame(im, duration: frameMs);
      // duplicate so the hold reads as ~2s; keeps the animation from flashing
      gif.addFrame(im, duration: frameMs);
    }
    final bytes = gif.finish();
    if (bytes == null) return null;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/reframe_timeline.gif');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}