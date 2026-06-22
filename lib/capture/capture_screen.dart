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
  AlignmentMode _mode = AlignmentMode.ghost;
  double _ghostOpacity = 0.5;
  bool _capturing = false;

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
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    // Prefer the rear camera for scene re-shots.
    final cam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    _controller = CameraController(
      cam,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await _controller!.initialize();
    if (mounted) setState(() {});
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
          if (_controller == null || !_controller!.value.isInitialized) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              // Center-cropped camera preview filling the screen.
              ClipRect(
                child: OverflowBox(
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    // Sensor is landscape; swap dims for a portrait device.
                    child: SizedBox(
                      width: _controller!.value.previewSize!.height,
                      height: _controller!.value.previewSize!.width,
                      child: CameraPreview(_controller!),
                    ),
                  ),
                ),
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
}