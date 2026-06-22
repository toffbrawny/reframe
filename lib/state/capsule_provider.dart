/// App state: the list of capsules and the currently-opened one.
///
/// A thin [ChangeNotifier] over [CapsuleRepository]. The home screen rebuilds
/// on list changes; the detail screen refreshes after each mutating call.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/capsule_repository.dart';
import '../models/capsule.dart';

class CapsuleProvider extends ChangeNotifier {
  CapsuleProvider() {
    _bootstrap();
  }

  final List<Capsule> _capsules = [];
  List<Capsule> get capsules => List.unmodifiable(_capsules);

  bool _loading = true;
  bool get loading => _loading;

  /// Ticks once a second so countdowns on visible screens update live.
  ///
  /// Broadcast so multiple screens can listen (home + detail) — a plain
  /// `Stream.periodic` is single-subscription and throws "stream has already
  /// been listened to" the second time a screen subscribes.
  late final Stream<DateTime> clock = Stream.periodic(
          const Duration(seconds: 1), (_) => DateTime.now())
      .asBroadcastStream();

  Future<void> _bootstrap() async {
    _capsules
      ..clear()
      ..addAll(await CapsuleRepository.instance.all());
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _capsules
      ..clear()
      ..addAll(await CapsuleRepository.instance.all());
    notifyListeners();
  }

  Future<Capsule> create({
    required String title,
    required Uint8List beforeBytes,
    required Duration lockDuration,
  }) async {
    final c = await CapsuleRepository.instance.create(
      title: title,
      beforeBytes: beforeBytes,
      lockDuration: lockDuration,
    );
    _capsules.insert(0, c);
    notifyListeners();
    return c;
  }

  Future<Capsule> addAfter({
    required int capsuleId,
    required Uint8List afterBytes,
  }) async {
    final c = await CapsuleRepository.instance.addAfter(
      capsuleId: capsuleId,
      afterBytes: afterBytes,
    );
    _replace(c);
    return c;
  }

  Future<Capsule> relock(int capsuleId, Duration lockDuration) async {
    final c = await CapsuleRepository.instance.relock(capsuleId, lockDuration);
    _replace(c);
    return c;
  }

  Future<Capsule> finalizeCapsule(int capsuleId) async {
    final c = await CapsuleRepository.instance.finalizeCapsule(capsuleId);
    _replace(c);
    return c;
  }

  Future<void> delete(int capsuleId) async {
    await CapsuleRepository.instance.delete(capsuleId);
    _capsules.removeWhere((c) => c.id == capsuleId);
    notifyListeners();
  }

  void _replace(Capsule c) {
    final i = _capsules.indexWhere((e) => e.id == c.id);
    if (i >= 0) _capsules[i] = c;
    notifyListeners();
  }
}