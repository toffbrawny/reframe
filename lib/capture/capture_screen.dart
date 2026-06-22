/// Live camera capture for the before/after shots.
///
/// Uses CamerAwesome (native CameraX on Android, AVFoundation on iOS) for a
/// WhatsApp-style full-screen preview at sensor resolution — much sharper than
/// the stock `camera` plugin's clamped 720p preview. Tap-to-focus and
/// pinch-to-zoom are built in.
///
/// Pass [referenceBytes] to show alignment aids over the live feed (the
/// previous frame). For the "before" shot, pass null. Returns the captured
/// JPEG bytes via [Navigator.pop], or null if the user backs out.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

import 'alignment_overlay.dart';

class CaptureScreen extends StatelessWidget {
  const CaptureScreen({super.key, this.referenceBytes, this.title});

  final Uint8List? referenceBytes;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CameraAwesomeBuilder.custom(
        sensorConfig: SensorConfig.single(
          sensor: Sensor.position(SensorPosition.back),
          flashMode: FlashMode.none,
        ),
        saveConfig: SaveConfig.photo(),
        // cover = full-screen preview at the sensor's native aspect; no
        // FittedBox upscaling blur.
        previewFit: CameraPreviewFit.cover,
        progressIndicator:
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        builder: (state, preview) => _CaptureOverlay(
          state: state,
          referenceBytes: referenceBytes,
          title: title,
        ),
      ),
    );
  }
}

/// The UI layered over the camera preview. Built as a separate StatefulWidget
/// so its own `setState` (alignment mode, opacity, capturing) rebuilds only the
/// overlay — never the [CameraAwesomeBuilder] above it (which would re-init the
/// camera).
class _CaptureOverlay extends StatefulWidget {
  const _CaptureOverlay({
    required this.state,
    required this.referenceBytes,
    required this.title,
  });

  final CameraState state;
  final Uint8List? referenceBytes;
  final String? title;

  @override
  State<_CaptureOverlay> createState() => _CaptureOverlayState();
}

class _CaptureOverlayState extends State<_CaptureOverlay> {
  AlignmentMode _mode = AlignmentMode.ghost;
  double _ghostOpacity = 0.5;
  bool _capturing = false;
  bool _done = false;
  StreamSubscription<MediaCapture?>? _sub;

  @override
  void initState() {
    super.initState();
    // The capture result arrives on the shared capture stream (same CameraContext
    // regardless of which CameraState instance is current).
    _sub = widget.state.captureState$.listen(_onCapture);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _onCapture(MediaCapture? mc) async {
    if (mc == null || _done) return;
    if (mc.status == MediaCaptureStatus.success && mc.isPicture) {
      _done = true;
      final path = mc.captureRequest.path;
      Uint8List? bytes;
      if (path != null) {
        try {
          bytes = await File(path).readAsBytes();
          // the photo was saved to a temp file by the plugin; clean it up
          await File(path).delete();
        } catch (_) {}
      }
      if (!mounted) return;
      Navigator.pop(context, bytes != null ? Uint8List.fromList(bytes) : null);
    } else if (mc.status == MediaCaptureStatus.failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Capture failed: ${mc.exception ?? ''}')));
        setState(() => _capturing = false);
      }
    }
  }

  void _capture() {
    if (_capturing || _done) return;
    setState(() => _capturing = true);
    // Fire the capture; the result is handled in _onCapture above.
    widget.state.when(onPhotoMode: (photoState) => photoState.takePhoto());
  }

  @override
  Widget build(BuildContext context) {
    final hasRef = widget.referenceBytes != null;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Alignment aids (IgnorePointer, so taps fall through to the preview
        // for tap-to-focus). Drawn first so the controls sit above them.
        if (hasRef && _mode != AlignmentMode.off)
          AlignmentOverlay(
            referenceBytes: widget.referenceBytes,
            mode: _mode,
            ghostOpacity: _ghostOpacity,
          ),
        // Top controls bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context, null),
                  ),
                  if (widget.title != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          widget.title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  AwesomeFlashButton(state: widget.state),
                  AwesomeCameraSwitchButton(state: widget.state),
                  if (hasRef)
                    IconButton(
                      tooltip: 'Alignment: ${_mode.label}',
                      icon: Icon(_modeIcon(_mode), color: Colors.white),
                      onPressed: () =>
                          setState(() => _mode = _mode.next),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Ghost opacity slider
        if (hasRef && _mode == AlignmentMode.ghost)
          Positioned(
            bottom: 140,
            left: 24,
            right: 24,
            child: SliderTheme(
              data: const SliderThemeData(
                activeTrackColor: Colors.white,
                thumbColor: Colors.white,
                inactiveTrackColor: Colors.white24,
              ),
              child: Slider(
                value: _ghostOpacity,
                min: 0.1,
                max: 0.85,
                onChanged: (v) => setState(() => _ghostOpacity = v),
              ),
            ),
          ),
        // Shutter
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: GestureDetector(
                  onTap: _capturing ? null : _capture,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white70, width: 5),
                    ),
                    child: _capturing
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child:
                                CircularProgressIndicator(color: Colors.black),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _modeIcon(AlignmentMode m) => switch (m) {
        AlignmentMode.off => Icons.visibility_off,
        AlignmentMode.ghost => Icons.visibility,
        AlignmentMode.outlineGrid => Icons.grid_on,
      };
}