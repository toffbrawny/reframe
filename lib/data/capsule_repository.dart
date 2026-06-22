/// Repository coordinating SQLite metadata + encrypted photo files.
///
/// Callers hand in raw JPEG bytes; the repo persists them through [PhotoVault]
/// and records the metadata in SQLite. Reads rehydrate a [Capsule] with its
/// ordered [Frame] list (frames are not encrypted-in-place in the model — the
/// repo holds only file names; bytes are fetched on demand via [readFrameBytes]).
library;

import 'dart:typed_data';

import '../models/capsule.dart';
import 'db.dart';
import 'photo_vault.dart';
import 'package:sqflite/sqflite.dart';

class CapsuleRepository {
  CapsuleRepository._();
  static final CapsuleRepository instance = CapsuleRepository._();

  Future<List<Capsule>> all() async {
    final db = await AppDb.instance.db;
    final rows = await db.query('capsules', orderBy: 'created_at DESC');
    final out = <Capsule>[];
    for (final r in rows) {
      final id = r['id'] as int;
      final frames = await _framesFor(db, id);
      out.add(Capsule.fromMap(r, frames: frames));
    }
    return out;
  }

  Future<Capsule> _byId(int id) async {
    final db = await AppDb.instance.db;
    final rows = await db.query('capsules', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) throw StateError('capsule $id not found');
    final frames = await _framesFor(db, id);
    return Capsule.fromMap(rows.first, frames: frames);
  }

  Future<List<Frame>> _framesFor(DatabaseExecutor db, int capsuleId) async {
    final rows = await db.query(
      'frames',
      where: 'capsule_id = ?',
      whereArgs: [capsuleId],
      orderBy: 'captured_at ASC',
    );
    return rows.map((m) => Frame.fromMap(m)).toList();
  }

  /// Creates a new capsule from its before photo. Returns the reloaded capsule.
  ///
  /// [lockDuration] is the actual countdown length — callers pass a [Preset]
  /// duration in release, or a [DebugPreset] duration in debug builds.
  Future<Capsule> create({
    required String title,
    required Uint8List beforeBytes,
    required Duration lockDuration,
  }) async {
    final db = await AppDb.instance.db;
    final now = DateTime.now();
    final capsule = Capsule(
      title: title,
      createdAt: now,
      unlockAt: now.add(lockDuration),
    );
    final id = await db.insert('capsules', capsule.toMap());

    final fileName = await _storeFrame(id, 'before', beforeBytes, now);
    await db.insert('frames', Frame(
      capsuleId: id,
      kind: 'before',
      fileName: fileName,
      capturedAt: now,
    ).toMap());

    return _byId(id);
  }

  /// Adds an after-shot to an unlocked capsule and clears `unlockAt` so the
  /// status flips to `awaitingRelock` (user must pick the next preset or finalize).
  Future<Capsule> addAfter({
    required int capsuleId,
    required Uint8List afterBytes,
  }) async {
    final now = DateTime.now();
    final db = await AppDb.instance.db;
    final fileName = await _storeFrame(capsuleId, 'after', afterBytes, now);
    await db.insert('frames', Frame(
      capsuleId: capsuleId,
      kind: 'after',
      fileName: fileName,
      capturedAt: now,
    ).toMap());
    // Clear unlockAt; await relock decision.
    await db.update('capsules', {'unlock_at': null},
        where: 'id = ?', whereArgs: [capsuleId]);
    return _byId(capsuleId);
  }

  /// Re-locks a capsule for another [lockDuration] starting now.
  Future<Capsule> relock(int capsuleId, Duration lockDuration) async {
    final db = await AppDb.instance.db;
    final unlockAt = DateTime.now().add(lockDuration);
    await db.update('capsules', {'unlock_at': unlockAt.toIso8601String()},
        where: 'id = ?', whereArgs: [capsuleId]);
    return _byId(capsuleId);
  }

  /// Marks the timeline complete — no more captures.
  Future<Capsule> finalizeCapsule(int capsuleId) async {
    final db = await AppDb.instance.db;
    await db.update('capsules', {'finalized': 1, 'unlock_at': null},
        where: 'id = ?', whereArgs: [capsuleId]);
    return _byId(capsuleId);
  }

  /// DEBUG ONLY: forces the capsule to "ready to capture" by setting unlockAt
  /// to now. Lets us exercise the capture/relock loop in a single session.
  Future<void> debugUnlockNow(int capsuleId) async {
    final db = await AppDb.instance.db;
    await db.update('capsules',
        {'unlock_at': DateTime.now().toIso8601String(), 'finalized': 0},
        where: 'id = ?', whereArgs: [capsuleId]);
  }

  Future<void> delete(int capsuleId) async {
    final db = await AppDb.instance.db;
    final frames = await _framesFor(db, capsuleId);
    for (final f in frames) {
      await PhotoVault.instance.delete(f.fileName);
    }
    await db.delete('frames', where: 'capsule_id = ?', whereArgs: [capsuleId]);
    await db.delete('capsules', where: 'id = ?', whereArgs: [capsuleId]);
  }

  /// Decrypts and returns the JPEG bytes for a given frame.
  Future<Uint8List> readFrameBytes(Frame frame) =>
      PhotoVault.instance.read(frame.fileName);

  Future<String> _storeFrame(
    int capsuleId,
    String kind,
    Uint8List bytes,
    DateTime when,
  ) async {
    // Unique-ish file name: capsuleId_kind_epochMs.enc
    final fileName = '${capsuleId}_${kind}_${when.millisecondsSinceEpoch}.enc';
    await PhotoVault.instance.write(fileName, bytes);
    return fileName;
  }
}