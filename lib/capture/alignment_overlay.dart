/// Alignment aids layered over the live camera preview.
///
/// - [AlignmentMode.off]: nothing.
/// - [AlignmentMode.ghost]: the reference frame shown translucent on top of
///   the live feed, so you line up the new shot by eye.
/// - [AlignmentMode.outlineGrid]: the reference frame desaturated and
///   contrast-boosted (a faint "trace") plus a rule-of-thirds grid and corner
///   guides drawn with [CustomPaint].
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';

enum AlignmentMode { off, ghost, outlineGrid }

extension AlignmentModeX on AlignmentMode {
  AlignmentMode get next => switch (this) {
        AlignmentMode.off => AlignmentMode.ghost,
        AlignmentMode.ghost => AlignmentMode.outlineGrid,
        AlignmentMode.outlineGrid => AlignmentMode.off,
      };

  String get label => switch (this) {
        AlignmentMode.off => 'Off',
        AlignmentMode.ghost => 'Ghost',
        AlignmentMode.outlineGrid => 'Outline',
      };
}

class AlignmentOverlay extends StatelessWidget {
  const AlignmentOverlay({
    super.key,
    required this.referenceBytes,
    required this.mode,
    this.ghostOpacity = 0.5,
  });

  final Uint8List? referenceBytes;
  final AlignmentMode mode;
  final double ghostOpacity;

  @override
  Widget build(BuildContext context) {
    if (mode == AlignmentMode.off || referenceBytes == null) {
      return const SizedBox.shrink();
    }
    final image = Image.memory(referenceBytes!, fit: BoxFit.contain);

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (mode == AlignmentMode.ghost)
            Opacity(opacity: ghostOpacity, child: image)
          else
            Opacity(
              opacity: 0.35,
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  // grayscale + contrast boost → faint high-key trace
                  0.299, 0.587, 0.114, 0, 0,
                  0.299, 0.587, 0.114, 0, 0,
                  0.299, 0.587, 0.114, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
                child: image,
              ),
            ),
          if (mode == AlignmentMode.outlineGrid)
            CustomPaint(
              painter: _GridPainter(),
              size: Size.infinite,
            ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Rule of thirds
    for (final i in [1.0 / 3, 2.0 / 3]) {
      canvas.drawLine(Offset(size.width * i, 0),
          Offset(size.width * i, size.height), paint);
      canvas.drawLine(Offset(0, size.height * i),
          Offset(size.width, size.height * i), paint);
    }

    // Corner guides
    const c = 36.0;
    final corners = <List<Offset>>[
      [Offset(0, c), Offset(0, 0), Offset(c, 0)],
      [Offset(size.width - c, 0), Offset(size.width, 0), Offset(size.width, c)],
      [Offset(0, size.height - c), Offset(0, size.height), Offset(c, size.height)],
      [Offset(size.width - c, size.height), Offset(size.width, size.height),
       Offset(size.width, size.height - c)],
    ];
    for (final c2 in corners) {
      canvas.drawLine(c2[0], c2[1], paint);
      canvas.drawLine(c2[1], c2[2], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}