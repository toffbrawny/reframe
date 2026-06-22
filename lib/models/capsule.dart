/// Data models for Reframe.
///
/// A [Capsule] is one subject/scene tracked over time: a single "before" photo
/// captured at creation, plus zero or more "after" photos captured at successive
/// unlock events. The [Preset] enum fixes the allowed lock durations.
library;

import 'package:flutter/foundation.dart';

/// Allowed lock durations. Fixed presets only — no custom values (by design).
enum Preset {
  week(Duration(days: 7), label: '1 week', short: '1w'),
  month(Duration(days: 30), label: '1 month', short: '1mo'),
  quarter(Duration(days: 90), label: '3 months', short: '3mo'),
  year(Duration(days: 365), label: '1 year', short: '1y');

  const Preset(this.duration, {required this.label, required this.short});

  final Duration duration;
  final String label;
  final String short;
}

/// A single photo in a capsule's timeline.
///
/// [kind] is `before` for the origin shot, `after` for each successive capture.
/// [path] is the encrypted file path relative to the app documents dir.
@immutable
class Frame {
  final int? id;
  final int capsuleId;
  final String kind; // "before" | "after"
  final String fileName; // relative file name inside the vault dir
  final DateTime capturedAt;

  const Frame({
    this.id,
    required this.capsuleId,
    required this.kind,
    required this.fileName,
    required this.capturedAt,
  });

  Frame copyWith({
    int? id,
    int? capsuleId,
    String? kind,
    String? fileName,
    DateTime? capturedAt,
  }) =>
      Frame(
        id: id ?? this.id,
        capsuleId: capsuleId ?? this.capsuleId,
        kind: kind ?? this.kind,
        fileName: fileName ?? this.fileName,
        capturedAt: capturedAt ?? this.capturedAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'capsule_id': capsuleId,
        'kind': kind,
        'file_name': fileName,
        'captured_at': capturedAt.toIso8601String(),
      };

  factory Frame.fromMap(Map<String, Object?> map) => Frame(
        id: map['id'] as int?,
        capsuleId: map['capsule_id'] as int,
        kind: map['kind'] as String,
        fileName: map['file_name'] as String,
        capturedAt: DateTime.parse(map['captured_at'] as String),
      );
}

/// Lifecycle status derived from [unlockAt] vs. now.
enum CapsuleStatus {
  locked, // countdown running
  readyToCapture, // unlockAt passed, awaiting the next after shot
  awaitingRelock, // after-shot just captured, user must pick next preset or finalize
  finalized, // no more captures; timeline complete
}

/// A time capsule: one before photo + N after photos.
@immutable
class Capsule {
  final int? id;
  final String title;
  final DateTime createdAt;

  /// Absolute moment the next after-shot becomes allowed. Null after finalize.
  final DateTime? unlockAt;

  /// True once the user chose to stop capturing (timeline sealed for good).
  final bool finalized;

  /// Ordered timeline: [before, after1, after2, ...]
  final List<Frame> frames;

  const Capsule({
    this.id,
    required this.title,
    required this.createdAt,
    this.unlockAt,
    this.finalized = false,
    this.frames = const [],
  });

  Frame get beforeFrame => frames.firstWhere((f) => f.kind == 'before');

  List<Frame> get afterFrames =>
      frames.where((f) => f.kind == 'after').toList()
        ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));

  /// The frame a new after-shot should align to: the most recent captured frame.
  Frame? get referenceFrame =>
      frames.isEmpty ? null : frames.reduce((a, b) =>
          a.capturedAt.isAfter(b.capturedAt) ? a : b);

  CapsuleStatus statusAt(DateTime now) {
    if (finalized) return CapsuleStatus.finalized;
    if (frames.isNotEmpty && unlockAt == null) return CapsuleStatus.awaitingRelock;
    if (unlockAt == null) return CapsuleStatus.awaitingRelock;
    if (now.isBefore(unlockAt!)) return CapsuleStatus.locked;
    return CapsuleStatus.readyToCapture;
  }

  Duration? remainingAt(DateTime now) {
    final u = unlockAt;
    if (u == null || !now.isBefore(u)) return null;
    return u.difference(now);
  }

  Capsule copyWith({
    int? id,
    String? title,
    DateTime? createdAt,
    DateTime? unlockAt,
    bool? finalized,
    List<Frame>? frames,
  }) =>
      Capsule(
        id: id ?? this.id,
        title: title ?? this.title,
        createdAt: createdAt ?? this.createdAt,
        unlockAt: unlockAt ?? this.unlockAt,
        finalized: finalized ?? this.finalized,
        frames: frames ?? this.frames,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'created_at': createdAt.toIso8601String(),
        'unlock_at': unlockAt?.toIso8601String(),
        'finalized': finalized ? 1 : 0,
      };

  factory Capsule.fromMap(Map<String, Object?> map, {List<Frame> frames = const []}) =>
      Capsule(
        id: map['id'] as int?,
        title: map['title'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        unlockAt: map['unlock_at'] == null
            ? null
            : DateTime.parse(map['unlock_at'] as String),
        finalized: (map['finalized'] as int) == 1,
        frames: frames,
      );
}