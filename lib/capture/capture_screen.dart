/// Live camera capture for the before/after shots.
///
/// Pass [referenceBytes] to show alignment aids over the live feed (the previous
/// frame). For the "before" shot, pass null. Returns the captured JPEG bytes via
/// [Navigator.pop], or null if the user backs out without capturing.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'alignment_overlay.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key, this.referenceBytes, this.title});

  final Uint8List? referenceBytes;
  final String? title;

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  AlignmentMode _mode = AlignmentMode.ghost;
  double _ghostOpacity = 0.5;
  bool _capturing = false;
  FlashMode _flash = FlashMode.off;
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    _initFuture = _init();
  }

  Future<void> _init() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required.')));
      }
      return;
    }
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;
    // Prefer the rear camera for scene re-shots.
    _cameraIndex = _cameras
        .indexWhere((c) => c.lensDirection == CameraLensDirection.back);
    if (_cameraIndex < 0) _cameraIndex = 0;
    await _startController(_cameras[_cameraIndex]);
  }

  Future<void> _startController(CameraDescription cam) async {
    final c = CameraController(
      cam,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await c.initialize();
    // Re-apply the current flash preference; ignore if unsupported by this sensor.
    try {
      await c.setFlashMode(_flash);
    } catch (_) {}
    if (!mounted) {
      await c.dispose();
      return;
    }
    _controller = c;
    if (mounted) setState(() {});
  }

  /// Switches to the next available camera (rear <-> selfie). `setDescription`
  /// re-initializes the existing controller in place, so we keep one controller
  /// and the preview texture updates seamlessly.
  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _switching) return;
    setState(() => _switching = true);
    final next = (_cameraIndex + 1) % _cameras.length;
    final ctrl = _controller;
    try {
      await ctrl?.setDescription(_cameras[next]);
      _cameraIndex = next;
      // Flash may not be supported on the new sensor (e.g. selfie) — re-apply
      // and fall back to off if it errors.
      try {
        await ctrl?.setFlashMode(_flash);
      } catch (_) {
        if (mounted) setState(() => _flash = FlashMode.off);
      }
    } catch (_) {}
    if (mounted) setState(() => _switching = false);
  }

  Future<void> _cycleFlash() async {
    const order = [
      FlashMode.off,
      FlashMode.auto,
      FlashMode.always,
      FlashMode.torch,
    ];
    final next = order[(order.indexOf(_flash) + 1) % order.length];
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    try {
      await ctrl.setFlashMode(next);
      setState(() => _flash = next);
    } catch (_) {
      // Not supported on this sensor (e.g. selfie). Stay silent.
    }
  }

  /// Tap-to-focus: normalize the tap to [0,1] over the preview and set the focus
  /// + exposure points, re-triggering autofocus. Mirrors the official camera
  /// plugin example's `onViewFinderTap`.
  Future<void> _onPreviewTap(TapDownDetails d, Size size) async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || size.isEmpty) return;
    final offset = Offset(
      (d.localPosition.dx / size.width).clamp(0.0, 1.0),
      (d.localPosition.dy / size.height).clamp(0.0, 1.0),
    );
    try {
      await ctrl.setFocusMode(FocusMode.auto);
      if (ctrl.value.focusPointSupported) await ctrl.setFocusPoint(offset);
      if (ctrl.value.exposurePointSupported) await ctrl.setExposurePoint(offset);
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _capturing) return;
    setState(() => _capturing = true);
    try {
      final xfile = await ctrl.takePicture();
      final bytes = await xfile.readAsBytes();
      if (mounted) Navigator.pop(context, Uint8List.fromList(bytes));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Capture failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRef = widget.referenceBytes != null;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title ?? 'Capture'),
        backgroundColor: Colors.black.withValues(alpha: 0.4),
        foregroundColor: Colors.white,
        actions: [
          if (_cameras.length > 1)
            IconButton(
              tooltip: 'Switch camera',
              onPressed: _switching ? null : _switchCamera,
              icon: _switching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cameraswitch, color: Colors.white),
            ),
          IconButton(
            tooltip: 'Flash: ${_flashLabel(_flash)}',
            onPressed: _cycleFlash,
            icon: Icon(_flashIcon(_flash), color: Colors.white),
          ),
          if (hasRef)
            TextButton.icon(
              onPressed: () => setState(() => _mode = _mode.next),
              icon: Icon(_modeIcon(_mode), color: Colors.white),
              label: Text(_mode.label,
                  style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snap) {
          final ctrl = _controller;
          if (ctrl == null || !ctrl.value.isInitialized || _switching) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              // Center-cropped camera preview filling the screen; tap to focus.
              LayoutBuilder(
                builder: (context, constraints) {
                  final size =
                      Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) => _onPreviewTap(d, size),
                    child: ClipRect(
                      child: OverflowBox(
                        maxWidth: double.infinity,
                        maxHeight: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          // Sensor is landscape; swap dims for a portrait device.
                          child: SizedBox(
                            width: ctrl.value.previewSize!.height,
                            height: ctrl.value.previewSize!.width,
                            child: CameraPreview(ctrl),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (hasRef)
                AlignmentOverlay(
                  referenceBytes: widget.referenceBytes,
                  mode: _mode,
                  ghostOpacity: _ghostOpacity,
                ),
              if (hasRef && _mode == AlignmentMode.ghost)
                Positioned(
                  bottom: 140,
                  left: 24,
                  right: 24,
                  child: SliderTheme(
                    data: SliderThemeData(
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
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 48),
              GestureDetector(
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
                          child: CircularProgressIndicator(color: Colors.black),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              SizedBox(
                width: 48,
                child: IconButton(
                  onPressed: () => Navigator.pop(context, null),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _modeIcon(AlignmentMode m) => switch (m) {
        AlignmentMode.off => Icons.visibility_off,
        AlignmentMode.ghost => Icons.visibility,
        AlignmentMode.outlineGrid => Icons.grid_on,
      };

  IconData _flashIcon(FlashMode f) => switch (f) {
        FlashMode.off => Icons.flash_off,
        FlashMode.auto => Icons.flash_auto,
        FlashMode.always => Icons.flash_on,
        FlashMode.torch => Icons.highlight,
      };

  String _flashLabel(FlashMode f) => switch (f) {
        FlashMode.off => 'off',
        FlashMode.auto => 'auto',
        FlashMode.always => 'on',
        FlashMode.torch => 'torch',
      };
}